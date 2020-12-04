// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/database.dart'
    show FirebaseDatabaseException, MutableData, TransactionHandler;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:sortedmap/sortedmap.dart';

import '../../database.dart' as firebase;
import 'connection.dart';
import 'event.dart';
import 'events/cancel.dart';
import 'events/child.dart';
import 'events/value.dart';
import 'firebase_impl.dart' as firebase;
import 'operations/tree.dart';
import 'synctree.dart';
import 'tree.dart';
import 'treestructureddata.dart';

final _logger = Logger('firebase-repo');

class Repo {
  static const dotInfo = '.info';
  static const dotInfoServerTimeOffset = 'serverTimeOffset';
  static const dotInfoAuthenticated = 'authenticated';
  static const dotInfoConnected = 'connected';

  static const _interruptReason = 'repo_interrupt';

  final PersistentConnection _connection;
  final Uri url;

  static final Map<firebase.FirebaseDatabase, Repo> _repos = {};

  @visibleForTesting
  static bool hasInstance(firebase.FirebaseDatabase db) => _repos[db] != null;

  final SyncTree _syncTree;

  final SyncTree _infoSyncTree;

  final PushIdGenerator pushIds = PushIdGenerator();

  int _nextWriteId = 0;
  TransactionsTree _transactions;
  final SparseSnapshotTree _onDisconnect = SparseSnapshotTree();

  StreamSubscription _authStateChangesSubscription;

  factory Repo(firebase.FirebaseDatabase db) {
    var url = Uri.parse(db.databaseURL ?? db.app.options.databaseURL);

    return _repos.putIfAbsent(db, () {
      var auth = FirebaseAuth.instanceFor(app: db.app);

      var connection =
          PersistentConnection(url, authTokenProvider: (refresh) async {
        var user = auth.currentUser;
        if (user == null) return null;
        var token = await user.getIdToken(refresh);
        return token;
      })
            ..initialize();

      return Repo._(url, connection, auth.authStateChanges());
    });
  }

  Repo._(this.url, this._connection, Stream<User> authStateChanges)
      : _syncTree = SyncTree(url.toString(), RemoteListeners(_connection)),
        _infoSyncTree =
            SyncTree(url.toString(), RemoteListenerRegistrar.fromCallbacks()) {
    _infoSyncTree.addEventListener(
        'value', Path.from([]), QueryFilter(), (event) {});
    _updateInfo(dotInfoAuthenticated, false);
    _updateInfo(dotInfoConnected, false);
    _authStateChangesSubscription = authStateChanges.listen((user) async {
      _updateInfo(dotInfoAuthenticated, user != null);
      return _connection
          .refreshAuthToken(user == null ? null : (await user.getIdToken()));
    });

    _transactions = TransactionsTree(this);
    _connection.onConnect.listen((v) {
      _updateInfo(dotInfoConnected, v);
      if (v) {
        _updateInfo(dotInfoServerTimeOffset,
            _connection.serverTime?.difference(DateTime.now())?.inMilliseconds);
      }
      if (!v) {
        _runOnDisconnectEvents();
      }
    });
    _connection.onDataOperation.listen((event) {
      if (event.type == OperationEventType.listenRevoked) {
        _syncTree.applyListenRevoked(event.path, event.query);
      } else {
        _syncTree.applyServerOperation(event.operation, event.query);
      }
    });
  }

  SyncTree get syncTree => _syncTree;

  RemoteListeners get registrar => _syncTree.registrar;

  Future triggerDisconnect() => _connection.disconnect();

  void purgeOutstandingWrites() {
    _logger.fine('Purging writes');
    // Abort any transactions
    _transactions.abort(
        Path.from([]), FirebaseDatabaseException.writeCanceled());
    // Remove outstanding writes from connection
    _connection.purgeOutstandingWrites();
  }

  /// Destroys this Repo permanently
  Future<void> close() async {
    await _authStateChangesSubscription.cancel();
    await _connection.close();
    await _syncTree.destroy();
    _unlistenTimers.forEach((v) => v.cancel());
    _repos.removeWhere((key, value) => value == this);
  }

  void resume() => _connection.resume(_interruptReason);

  void interrupt() => _connection.interrupt(_interruptReason);

  /// The current authData
  dynamic get authData => _connection.authData;

  /// Stream of auth data.
  ///
  /// When a user is logged in, its auth data is posted. When logged of, `null`
  /// is posted.
  Stream<Map> get onAuth => _connection.onAuth;

  /// Tries to authenticate with [token].
  ///
  /// Returns a future that completes with the auth data on success, or fails
  /// otherwise.
  Future<void> auth(String token) async {
    await _connection.refreshAuthToken(token);
  }

  /// Unauthenticates.
  ///
  /// Returns a future that completes on success, or fails otherwise.
  Future<void> unauth() => _connection.refreshAuthToken(null);

  String _preparePath(String path) =>
      path.split('/').map(Uri.decodeComponent).join('/');

  /// Writes data [value] to the location [path] and sets the [priority].
  ///
  /// Returns a future that completes when the data has been written to the
  /// server and fails when data could not be written.
  Future<void> setWithPriority(
      String path, dynamic value, dynamic priority) async {
    // possibly the user starts this write in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    path = _preparePath(path);
    var newValue = TreeStructuredData.fromJson(value, priority);
    var writeId = _nextWriteId++;
    _syncTree.applyUserOverwrite(Name.parsePath(path),
        ServerValue.resolve(newValue, _connection.serverValues), writeId);
    _transactions.abort(
        Name.parsePath(path), FirebaseDatabaseException.overriddenBySet());
    try {
      await _connection.put(path, newValue.toJson(true));
      await Future.microtask(
          () => _syncTree.applyAck(Name.parsePath(path), writeId, true));
    } on FirebaseDatabaseException {
      _syncTree.applyAck(Name.parsePath(path), writeId, false);
      rethrow;
    }
  }

  /// Writes the children in [value] to the location [path].
  ///
  /// Returns a future that completes when the data has been written to the
  /// server and fails when data could not be written.
  Future<void> update(String path, Map<String, dynamic> value) async {
    // possibly the user starts this write in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    if (value.isNotEmpty) {
      path = _preparePath(path);
      var serverValues = _connection.serverValues;
      var changedChildren = Map<Path<Name>, TreeStructuredData>.fromIterables(
          value.keys.map<Path<Name>>((c) => Name.parsePath(c)),
          value.values.map<TreeStructuredData>((v) => ServerValue.resolve(
              TreeStructuredData.fromJson(v, null), serverValues)));
      var writeId = _nextWriteId++;
      _syncTree.applyUserMerge(Name.parsePath(path), changedChildren, writeId);
      try {
        await _connection.merge(path, value);
        await Future.microtask(
            () => _syncTree.applyAck(Name.parsePath(path), writeId, true));
      } on firebase.FirebaseDatabaseException {
        _syncTree.applyAck(Name.parsePath(path), writeId, false);
      }
    }
  }

  /// Generates a unique id.
  String generateId() {
    return pushIds.next(_connection.serverTime);
  }

  /// Listens to changes of [type] at location [path] for data matching [filter].
  ///
  /// Returns a future that completes when the listener has been successfully
  /// registered at the server.
  Future<void> listen(
      String path, QueryFilter filter, String type, EventListener cb) async {
    // possibly the user started listening in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    path = _preparePath(path);

    var p = Name.parsePath(path);
    if (p.isNotEmpty && p.first.asString() == dotInfo) {
      await _infoSyncTree.addEventListener(
          type, Name.parsePath(path), filter ?? QueryFilter(), cb);
    } else {
      await _syncTree.addEventListener(
          type, Name.parsePath(path), filter ?? QueryFilter(), cb);
    }
  }

  final List<Timer> _unlistenTimers = [];

  /// Unlistens to changes of [type] at location [path] for data matching [filter].
  ///
  /// Returns a future that completes when the listener has been successfully
  /// unregistered at the server.
  void unlisten(
      String path, QueryFilter filter, String type, EventListener cb) {
    path = _preparePath(path);

    var p = Name.parsePath(path);
    if (p.isNotEmpty && p.first.asString() == dotInfo) {
      _infoSyncTree.removeEventListener(
          type, Name.parsePath(path), filter ?? QueryFilter(), cb);
    } else {
      var self;
      var timer = Timer(Duration(milliseconds: 2000), () {
        _unlistenTimers.remove(self);
        _syncTree.removeEventListener(
            type, Name.parsePath(path), filter ?? QueryFilter(), cb);
      });
      self = timer;
      _unlistenTimers.add(timer);
    }
  }

  /// Gets the current cached value at location [path] with [filter].
  TreeStructuredData cachedValue(String path, QueryFilter filter) {
    path = _preparePath(path);
    var tree = _syncTree.root.subtree(Name.parsePath(path));
    if (tree = null) return null;
    return tree.value.valueForFilter(filter);
  }

  /// Helper function to create a stream for a particular event type.
  Stream<firebase.Event> createStream(
      firebase.DatabaseReference ref, QueryFilter filter, String type) {
    return _Stream(() => StreamFactory(this, ref, filter, type)());
  }

  Future<TreeStructuredData> transaction(
          String path, TransactionHandler update, bool applyLocally) =>
      _transactions.startTransaction(
          Name.parsePath(_preparePath(path)), update, applyLocally);

  Future<void> onDisconnectSetWithPriority(
      String path, dynamic value, dynamic priority) async {
    // possibly the user starts this write in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    path = _preparePath(path);
    var newNode = TreeStructuredData.fromJson(value, priority);
    await _connection.onDisconnectPut(path, newNode.toJson(true)).then((_) {
      _onDisconnect.remember(Name.parsePath(path), newNode);
    });
  }

  Future<void> onDisconnectUpdate(
      String path, Map<String, dynamic> childrenToMerge) async {
    // possibly the user starts this write in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    path = _preparePath(path);
    if (childrenToMerge.isEmpty) return Future.value();

    await _connection.onDisconnectMerge(path, childrenToMerge).then((_) {
      childrenToMerge.forEach((childName, child) {
        _onDisconnect.remember(Name.parsePath(path).child(Name(childName)),
            TreeStructuredData.fromJson(child));
      });
    });
  }

  Future<void> onDisconnectCancel(String path) async {
    // possibly the user starts this write in response of an auth event
    // so, wait until all microtasks are processed to make sure that the
    // database also received the auth event
    await Future.microtask(() => null);

    path = _preparePath(path);
    await _connection.onDisconnectCancel(path).then((_) {
      _onDisconnect.forget(Name.parsePath(path));
    });
  }

  void _runOnDisconnectEvents() {
    var sv = _connection.serverValues;
    _onDisconnect.forEachNode((path, snap) {
      if (snap == null) return;
      _syncTree.applyServerOperation(
          TreeOperation.overwrite(path, ServerValue.resolve(snap, sv)), null);
      _transactions.abort(path, FirebaseDatabaseException.overriddenBySet());
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  @visibleForTesting
  void mockConnectionLost() => _connection.mockConnectionLost();

  @visibleForTesting
  void mockResetMessage() => _connection.mockResetMessage();

  void _updateInfo(String pathString, dynamic value) {
    _infoSyncTree.applyServerOperation(
        TreeOperation.overwrite(Name.parsePath('$dotInfo/$pathString'),
            TreeStructuredData.fromJson(value)),
        null);
  }
}

class RemoteListeners extends RemoteListenerRegistrar {
  final PersistentConnection connection;

  RemoteListeners(this.connection);

  @override
  Future<Null> remoteRegister(
      Path<Name> path, QueryFilter filter, String hash) async {
    var warnings =
        await connection.listen(path.join('/'), query: filter, hash: hash) ??
            [];
    for (var w in warnings) {
      _logger.warning(w);
    }
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) async {
    await connection.unlisten(path.join('/'), query: filter);
  }
}

class InfoRemoteListeners extends RemoteListenerRegistrar {
  @override
  Future<Null> remoteRegister(
      Path<Name> path, QueryFilter filter, String hash) {
    // TODO: implement remoteRegister
    throw UnimplementedError();
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) {
    // TODO: implement remoteUnregister
    throw UnimplementedError();
  }
}

typedef _StreamCreator<T> = Stream<T> Function();

class _Stream<T> extends Stream<T> {
  final _StreamCreator<T> factory;

  _Stream(this.factory);

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    var stream = factory();
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class StreamFactory {
  final Repo repo;
  final firebase.DatabaseReference ref;
  final QueryFilter filter;
  final String type;

  StreamFactory(this.repo, this.ref, this.filter, this.type);

  StreamController<firebase.Event> controller;

  void addEvent(Event value) {
    var e = _mapEvent(value);
    if (e == null) return;
    Future.microtask(() => controller.add(e));
  }

  firebase.Event _mapEvent(Event value) {
    if (value is ValueEvent) {
      if (type != 'value') return null;
      return firebase.Event(firebase.DataSnapshotImpl(ref, value.value), null);
    } else if (value is ChildAddedEvent) {
      if (type != 'child_added') return null;
      return firebase.Event(
          firebase.DataSnapshotImpl(
              ref.child(value.childKey.toString()), value.newValue),
          value.prevChildKey.toString());
    } else if (value is ChildChangedEvent) {
      if (type != 'child_changed') return null;
      return firebase.Event(
          firebase.DataSnapshotImpl(
              ref.child(value.childKey.toString()), value.newValue),
          value.prevChildKey.toString());
    } else if (value is ChildMovedEvent) {
      if (type != 'child_moved') return null;
      return firebase.Event(
          firebase.DataSnapshotImpl(ref.child(value.childKey.toString()), null),
          value.prevChildKey.toString());
    } else if (value is ChildRemovedEvent) {
      if (type != 'child_removed') return null;
      return firebase.Event(
          firebase.DataSnapshotImpl(
              ref.child(value.childKey.toString()), value.oldValue),
          value.prevChildKey.toString());
    }
    return null;
  }

  void addError(Event error) {
    assert(error is CancelEvent);
    stopListen();
    var event = error as CancelEvent;
    if (event.error != null) {
      controller.addError(event.error, event.stackTrace);
    }
    controller.close();
  }

  void startListen() {
    repo.listen(ref.url.path, filter, type, addEvent);
    repo.listen(ref.url.path, filter, 'cancel', addError);
  }

  void stopListen() {
    repo.unlisten(ref.url.path, filter, type, addEvent);
    repo.unlisten(ref.url.path, filter, 'cancel', addError);
  }

  Stream<firebase.Event> call() {
    controller = StreamController<firebase.Event>(
        onListen: startListen, onCancel: stopListen, sync: true);
    return controller.stream;
  }
}

class PushIdGenerator {
  static const String pushChars =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
  int lastPushTime = 0;
  final List lastRandChars = List(64);
  final Random random = Random();

  String next(DateTime timestamp) {
    var now = timestamp.millisecondsSinceEpoch;

    var duplicateTime = now == lastPushTime;
    lastPushTime = now;
    var timeStampChars = List(8);
    for (var i = 7; i >= 0; i--) {
      timeStampChars[i] = pushChars[now % 64];
      now = now ~/ 64;
    }
    var id = timeStampChars.join('');
    if (!duplicateTime) {
      for (var i = 0; i < 12; i++) {
        lastRandChars[i] = random.nextInt(64);
      }
    } else {
      var i;
      for (i = 11; i >= 0 && lastRandChars[i] == 63; i--) {
        lastRandChars[i] = 0;
      }
      lastRandChars[i]++;
    }
    for (var i = 0; i < 12; i++) {
      id += pushChars[lastRandChars[i]];
    }
    return id;
  }
}

enum TransactionStatus { run, sent, completed, sentNeedsAbort }

class Transaction implements Comparable<Transaction> {
  final Path<Name> path;
  final TransactionHandler update;
  final bool applyLocally;
  final Repo repo;
  final int order;
  final Completer<TreeStructuredData> completer = Completer();

  static int _order = 0;

  static const int maxRetries = 25;

  int retryCount = 0;
  FirebaseDatabaseException abortReason;
  int currentWriteId;
  TreeStructuredData currentInputSnapshot;
  TreeStructuredData currentOutputSnapshotRaw;
  TreeStructuredData currentOutputSnapshotResolved;

  TransactionStatus status;

  Transaction(this.repo, this.path, this.update, this.applyLocally)
      : order = _order++ {
    _watch();
  }

  bool get isSent =>
      status == TransactionStatus.sent ||
      status == TransactionStatus.sentNeedsAbort;

  bool get isComplete => status == TransactionStatus.completed;

  bool get isAborted => status == TransactionStatus.sentNeedsAbort;

  void _onValue(Event _) {}

  void _watch() {
    repo.listen(path.join('/'), null, 'value', _onValue);
  }

  void _unwatch() {
    repo.unlisten(path.join('/'), null, 'value', _onValue);
  }

  void run(TreeStructuredData currentState) {
    assert(status == null);
    if (retryCount >= maxRetries) {
      fail(FirebaseDatabaseException.maxRetries());
      return;
    }

    currentInputSnapshot = currentState;
    var data = MutableData(
        path.isEmpty ? null : path.last.toString(), currentState.toJson());

    try {
      data = update(data);
    } catch (e) {
      fail(FirebaseDatabaseException.userCodeException());
      return;
    }

    if (data == null) {
      fail(null);
      return;
    }
    status = TransactionStatus.run;

    var newNode =
        TreeStructuredData.fromJson(data.value, currentState.priority);
    currentOutputSnapshotRaw = newNode;
    currentOutputSnapshotResolved =
        ServerValue.resolve(newNode, repo._connection.serverValues);
    currentWriteId = repo._nextWriteId++;

    if (applyLocally) {
      repo._syncTree.applyUserOverwrite(
          path, currentOutputSnapshotResolved, currentWriteId);
    }
  }

  void fail(FirebaseDatabaseException e) {
    _unwatch();
    currentOutputSnapshotRaw = null;
    currentOutputSnapshotResolved = null;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
    status = TransactionStatus.completed;

    if (e == null) {
      // aborted by user
      completer.complete(null);
    } else {
      completer.completeError(e);
    }
  }

  void stale() {
    assert(status != TransactionStatus.completed);
    status = null;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
  }

  void send() {
    assert(status == TransactionStatus.run);
    status = TransactionStatus.sent;
    retryCount++;
  }

  void abort(FirebaseDatabaseException reason) {
    switch (status) {
      case TransactionStatus.sentNeedsAbort:
        break;
      case TransactionStatus.sent:
        status = TransactionStatus.sentNeedsAbort;
        abortReason = reason;
        break;
      case TransactionStatus.run:
        fail(reason);
        break;
      default:
        throw StateError('Unable to abort transaction in state $status');
    }
  }

  void complete() {
    assert(isSent);
    status = TransactionStatus.completed;

    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, true);

    completer.complete(currentOutputSnapshotResolved);

    _unwatch();
  }

  @override
  int compareTo(Transaction other) => Comparable.compare(order, other.order);
}

TreeStructuredData updateChild(
    TreeStructuredData value, Path<Name> path, TreeStructuredData child) {
  if (path.isEmpty) {
    return child;
  } else {
    var k = path.first;
    var c = value.children[k] ?? TreeStructuredData();
    var newChild = updateChild(c, path.skip(1), child);
    var newValue = value.clone();
    if (newValue.isLeaf && !newChild.isNil) newValue.value = null;
    if (newChild.isNil) {
      newValue.children.remove(k);
    } else {
      newValue.children[k] = newChild;
    }
    return newValue;
  }
}

class TransactionsTree {
  final Repo repo;
  final TransactionsNode root = TransactionsNode();

  TransactionsTree(this.repo);

  Future<TreeStructuredData> startTransaction(Path<Name> path,
      TransactionHandler transactionUpdate, bool applyLocally) {
    var transaction = Transaction(repo, path, transactionUpdate, applyLocally);
    var node = root.subtree(path, (a, b) => TransactionsNode());

    var current = getLatestValue(repo._syncTree, path);
    if (node.value.isEmpty) {
      node.input = current;
    }
    transaction.run(current);
    node.addTransaction(transaction);
    send();

    return transaction.completer.future;
  }

  void send() {
    root.send(repo, Path()).then((finished) {
      if (!finished) send();
    });
  }

  void abort(Path<Name> path, FirebaseDatabaseException exception) {
    for (var n in root.nodesOnPath(path)) {
      n.abort(exception);
    }
    var n = root.subtree(path);
    if (n == null) return;

    for (var n in n.childrenDeep) {
      n.abort(exception);
    }
  }
}

TreeStructuredData getLatestValue(SyncTree syncTree, Path<Name> path) {
  var nodes = syncTree.root.nodesOnPath(path);
  var subpath = path.skip(nodes.length - 1);
  var node = nodes.last;

  var point = node.value;
  for (var n in subpath) {
    point = point.child(n);
  }
  return point.valueForFilter(QueryFilter());
}

class TransactionsNode extends TreeNode<Name, List<Transaction>> {
  TransactionsNode() : super([], SortedMap<Name, TransactionsNode>());

  @override
  Map<Name, TransactionsNode> get children => super.children;

  @override
  TransactionsNode subtree(Path<Name> path,
          [TreeNode<Name, List<Transaction>> Function(
                  List<Transaction> parent, Name childName)
              newInstance]) =>
      super.subtree(path, newInstance);

  bool get isReadyToSend =>
      value.every((t) => t.status == TransactionStatus.run) &&
      children.values.every((n) => n.isReadyToSend);

  bool get needsRerun =>
      value.any((t) => t.status == null) ||
      children.values.any((n) => n.needsRerun);

  @override
  Iterable<TransactionsNode> nodesOnPath(Path<Name> path) =>
      super.nodesOnPath(path).map((v) => v as TransactionsNode);

  /// Completes all sent transactions
  void complete() {
    // complete all transactions that were sent and executed successfully,
    // also when they are marked for abort
    value.where((t) => t.isSent).forEach((m) => m.complete());
    // remove the transactions that are now complete
    value = value.where((t) => !t.isComplete).toList();
    // reset the status of all other transactions
    value.forEach((m) => m.status = null);

    // repeat for all children
    children.values.forEach((n) => n.complete());
  }

  /// Fails aborted transactions and resets other sent transactions
  ///
  /// A stale is executed when an attempt to write data failed, because the hash
  /// did not match, meaning that the data has been changed by another process.
  void stale() {
    // all transactions that were marked for abort, should fail
    value.where((t) => t.isAborted).forEach((m) => m.fail(m.abortReason));
    // and be removed from the list
    value = value.where((t) => !t.isComplete).toList();

    // all non aborted transactions should execute again
    value.where((t) => !t.isAborted).forEach((m) => m.stale());

    // repeat for all children
    children.values.forEach((n) => n.stale());
  }

  /// Fails all sent transactions
  ///
  /// Transactions were sent, but failed with reason other than concurrent write.
  /// The transactions will be stopped and return an error.
  void fail(FirebaseDatabaseException e) {
    // fail all sent transactions
    value.where((t) => t.isSent).forEach((m) => m.fail(e));
    // remove the failed transactions
    value = value.where((t) => !t.isComplete).toList();

    // repeat for children
    children.values.forEach((n) => n.fail(e));
  }

  void _send() {
    value.forEach((m) => m.send());
    children.values.forEach((n) => n._send());
  }

  Future<bool> send(Repo repo, Path<Name> path) async {
    if (value.isNotEmpty) {
      if (needsRerun) {
        stale();
        rerun(path, getLatestValue(repo._syncTree, path));
      }
      if (isReadyToSend) {
        var latestHash = input.hash;
        try {
          _send();
          await repo._connection
              .put(path.join('/'), output.toJson(true), hash: latestHash);
          complete();
          return false;
        } on firebase.FirebaseDatabaseException catch (e) {
          if (e.code == 'datastale') {
            stale();
          } else {
            fail(e);
          }
          return false;
        }
      }
      return true;
    } else {
      var allFinished = true;
      for (var k in children.keys.toList()) {
        allFinished =
            allFinished && await children[k].send(repo, path.child(k));
      }
      return allFinished;
    }
  }

  Iterable<Transaction> get transactionsInOrder =>
      List.from(_transactions)..sort();

  Iterable<Transaction> get _transactions sync* {
    yield* value;
    yield* children.values.expand<Transaction>((n) => n._transactions);
  }

  Iterable<TransactionsNode> get childrenDeep sync* {
    yield* children.values;
    yield* children.values.expand((n) => n.childrenDeep);
  }

  void rerun(Path<Name> path, TreeStructuredData input) {
    this.input = input;

    var v = input;
    for (var t in transactionsInOrder) {
      var p = t.path.skip(path.length);
      t.run(
          v.subtree(p, (a, b) => TreeStructuredData()) ?? TreeStructuredData());
      if (!t.isComplete) {
        v = updateChild(v, p, t.currentOutputSnapshotResolved);
      }
    }
  }

  TreeStructuredData input;

  int get lastId => max(
      value.isEmpty ? -1 : value.map((t) => t.order).reduce(max),
      children.isEmpty
          ? -1
          : children.values.map((n) => n.lastId).reduce(max) ?? -1);

  TreeStructuredData get output {
    var v = input;
    var lastId = -1;
    if (value.isNotEmpty) {
      v = value.last.currentOutputSnapshotRaw;
      lastId = value.last.order;
    }
    v = v.clone();
    children.forEach((key, node) {
      if (node.lastId > lastId) {
        v.children[key] = node.output;
      }
    });
    return v;
  }

  void addTransaction(Transaction transaction) {
    if (transaction.status == TransactionStatus.run) {
      value.add(transaction);
    }
  }

  void abort(FirebaseDatabaseException exception) {
    for (var txn in value) {
      txn.abort(exception);
    }
    value = value.where((t) => !t.isComplete).toList();
  }
}

class SparseSnapshotTree extends TreeNode<Name, TreeStructuredData> {
  SparseSnapshotTree() : super(null, SortedMap<Name, SparseSnapshotTree>());

  @override
  Map<Name, SparseSnapshotTree> get children => super.children;

  void remember(Path<Name> path, TreeStructuredData data) {
    if (path.isEmpty) {
      value = data;
      children.clear();
    } else {
      if (value != null) {
        value = updateChild(value, path, data);
      } else {
        var childKey = path.first;
        children.putIfAbsent(childKey, () => SparseSnapshotTree());
        var child = children[childKey];
        path = path.skip(1);
        child.remember(path, data);
      }
    }
  }

  bool forget(Path<Name> path) {
    if (path.isEmpty) {
      value = null;
      children.clear();
      return true;
    } else {
      if (value != null) {
        if (value.isLeaf) {
          return false;
        } else {
          var oldValue = value;
          value = null;
          oldValue.children.forEach((key, tree) {
            remember(Path.from([key]), tree);
          });
          return forget(path);
        }
      } else {
        var childKey = path.first;
        path = path.skip(1);
        if (children.containsKey(childKey)) {
          var safeToRemove = children[childKey].forget(path);
          if (safeToRemove) {
            children.remove(childKey);
          }
        }
        if (children.isEmpty) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
}
