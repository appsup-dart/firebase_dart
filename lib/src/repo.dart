// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'connection.dart';
import 'dart:async';
import 'treestructureddata.dart';
import 'synctree.dart';
import 'firebase.dart' as firebase;
import 'firebase_impl.dart' as firebase;
import 'events/value.dart';
import 'events/child.dart';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:sortedmap/sortedmap.dart';
import 'tree.dart';
import 'event.dart';
import 'operations/tree.dart';

final _logger = new Logger("firebase-repo");



class Repo {
  final Connection _connection;
  final Uri url;

  static final Map<Uri, Repo> _repos = {};

  final SyncTree _syncTree;

  SyncTree get syncTree => _syncTree;

  final PushIdGenerator pushIds = new PushIdGenerator();

  int _nextWriteId = 0;
  TransactionsTree _transactions;
  SparseSnapshotTree _onDisconnect = new SparseSnapshotTree();

  factory Repo(Uri url) {
    return _repos.putIfAbsent(url, () => new Repo._(url, new Connection(url)));
  }

  Repo._(this.url, this._connection) : _syncTree = new SyncTree(url.toString(), new RemoteListeners(_connection)) {
    _transactions = new TransactionsTree(this);
    _connection.onConnect.listen((v) {
      if (!v) {
        _runOnDisconnectEvents();
      }
    });
    _connection.onDataOperation.listen((event) {
      if (event.type==OperationEventType.listenRevoked) {
        _syncTree.applyListenRevoked(event.path, event.query);
      } else {
        _syncTree.applyServerOperation(event.operation, event.query);
      }
    });
    _connection.onAuth.forEach((e)=>_onAuth.add(e));
    onAuth.listen((v) => _authData = v);
  }

  RemoteListeners get registrar => _syncTree.registrar;

  firebase.Firebase get rootRef => new firebase.Firebase(url.toString());

  var _authData;
  final StreamController<Map> _onAuth = new StreamController.broadcast();

  Future triggerDisconnect() => _connection.disconnect();

  Future close() async {
    await _onAuth.close();
    await _connection.close();
  }

  /// The current authData
  dynamic get authData => _authData;

  /// Stream of auth data.
  ///
  /// When a user is logged in, its auth data is posted. When logged of, [null]
  /// is posted.
  Stream<Map> get onAuth => _onAuth.stream;

  /// Tries to authenticate with [token].
  ///
  /// Returns a future that completes with the auth data on success, or fails
  /// otherwise.
  Future<Map> auth(String token) async {
    var auth = await _connection.auth(token);
    _onAuth.add(auth);
    _authData = auth;
    return auth;
  }

  /// Unauthenticates.
  ///
  /// Returns a future that completes on success, or fails otherwise.
  Future unauth() => _connection.unauth().then((_) {
        _onAuth.add(null);
        _authData = null;
      });

  String _preparePath(String path) => path.split("/").map(Uri.decodeComponent).join("/");

  /// Writes data [value] to the location [path] and sets the [priority].
  ///
  /// Returns a future that completes when the data has been written to the
  /// server and fails when data could not be written.
  Future<Null> setWithPriority(String path, dynamic value, dynamic priority) async {
    path = _preparePath(path);
    var newValue = new TreeStructuredData.fromJson(value, priority);
    var writeId = _nextWriteId++;
    _syncTree.applyUserOverwrite(Name.parsePath(path),
        ServerValue.resolve(newValue, _connection.serverValues), writeId);
    _transactions.abort(Name.parsePath(path));
    try {
      await _connection.put(path, newValue.toJson(true), writeId: writeId);
      await new Future.microtask(()=>_syncTree.applyAck(Name.parsePath(path), writeId, true));
    } on ServerError {
      _syncTree.applyAck(Name.parsePath(path), writeId, false);
    }
  }

  /// Writes the children in [value] to the location [path].
  ///
  /// Returns a future that completes when the data has been written to the
  /// server and fails when data could not be written.
  Future update(String path, Map<String, dynamic> value) async {
    path = _preparePath(path);
    var changedChildren = new Map<Name, TreeStructuredData>.fromIterables(
        value.keys.map/*<Name>*/((c) => new Name(c)),
        value.values.map/*<TreeStructuredData>*/(
            (v) => new TreeStructuredData.fromJson(v, null)));
    if (value.isNotEmpty) {
      int writeId = _nextWriteId++;
      _syncTree.applyUserMerge(Name.parsePath(path),
          ServerValue.resolve(new TreeStructuredData.nonLeaf(changedChildren), _connection.serverValues).children, writeId);
      try {
        await _connection.merge(path, value, writeId: writeId);
        await new Future.microtask(()=>_syncTree.applyAck(Name.parsePath(path), writeId, true));
      } on ServerError {
        _syncTree.applyAck(Name.parsePath(path), writeId, false);
      }
    }
  }

  /// Adds [value] to the location [path] for which a unique id is generated.
  ///
  /// Returns a future that completes with the generated key when the data has
  /// been written to the server and fails when data could not be written.
  Future push(String path, dynamic value) async {
    path = _preparePath(path);
    var name = pushIds.next(_connection.serverTime);
    var pushedPath = "$path/$name";
    if (value != null) {
      await setWithPriority(pushedPath, value, null);
    }
    return name;
  }

  /// Listens to changes of [type] at location [path] for data matching [filter].
  ///
  /// Returns a future that completes when the listener has been successfully
  /// registered at the server.
  Future listen(
      String path, QueryFilter filter, String type, EventListener cb) {
    path = _preparePath(path);
    return _syncTree.addEventListener(type, Name.parsePath(path), filter ?? new QueryFilter(), cb);
  }

  /// Unlistens to changes of [type] at location [path] for data matching [filter].
  ///
  /// Returns a future that completes when the listener has been successfully
  /// unregistered at the server.
  Future unlisten(
      String path, QueryFilter filter, String type, EventListener cb) {
    path = _preparePath(path);
    return new Future.delayed(new Duration(milliseconds: 2000),
    ()=>_syncTree.removeEventListener(type, Name.parsePath(path), filter ?? new QueryFilter(), cb));
  }

  /// Gets the current cached value at location [path] with [filter].
  TreeStructuredData cachedValue(String path, QueryFilter filter) {
    path = _preparePath(path);
    var tree = _syncTree.root.subtree(Name.parsePath(path));
    if (tree = null) return null;
    return tree.value.valueForFilter(filter);
  }

  /// Helper function to create a new stream for a particular event type.
  Stream<firebase.Event> createStream(
      firebase.Firebase ref, QueryFilter filter, String type) {
    return new _Stream(() => new StreamFactory(this, ref, filter, type)());
  }

  Future<TreeStructuredData> transaction(
          String path, Function update, bool applyLocally) =>
      _transactions.startTransaction(
          Name.parsePath(_preparePath(path)), update, applyLocally);

  Future onDisconnectSetWithPriority(
      String path, dynamic value, dynamic priority) {
    path = _preparePath(path);
    var newNode = new TreeStructuredData.fromJson(value, priority);
    return _connection.onDisconnectPut(path, newNode.toJson(true)).then((_) {
      _onDisconnect.remember(Name.parsePath(path), newNode);
    });
  }

  Future onDisconnectUpdate(String path, Map<String, dynamic> childrenToMerge) {
    path = _preparePath(path);
    if (childrenToMerge.isEmpty) return new Future.value();

    return _connection.onDisconnectMerge(path, childrenToMerge).then((_) {
      childrenToMerge.forEach((childName, child) {
        _onDisconnect.remember(Name.parsePath(path).child(new Name(childName)),
            new TreeStructuredData.fromJson(child));
      });
    });
  }

  Future onDisconnectCancel(String path) {
    path = _preparePath(path);
    return _connection.onDisconnectCancel(path).then((_) {
      _onDisconnect.forget(Name.parsePath(path));
    });
  }

  void _runOnDisconnectEvents() {
    var sv = _connection.serverValues;
    _onDisconnect.forEachNode((path, snap) {
      if (snap == null) return;
      _syncTree.applyServerOperation(new TreeOperation.overwrite(path, ServerValue.resolve(snap,sv)), null);
      _transactions.abort(path);
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }
}

class RemoteListeners extends RemoteListenerRegistrar {


  final Connection connection;

  RemoteListeners(this.connection);

  @override
  Future<Null> remoteRegister(Path<Name> path, QueryFilter filter, String hash) async {
    var warnings = await connection.listen(path.join('/'), query: filter, hash: hash) ?? [];
    for (var w in warnings) {
      _logger.warning(w);
    }
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) async {
    await connection.unlisten(path.join('/'), query: filter);
  }

}


typedef Stream<T> _StreamCreator<T>();

class _Stream<T> extends Stream<T> {
  final _StreamCreator<T> factory;

  _Stream(this.factory);

  @override
  StreamSubscription<T> listen(void onData(T event),
      {Function onError, void onDone(), bool cancelOnError}) {
    Stream<T> stream = factory();
    return stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class StreamFactory {
  final Repo repo;
  final firebase.Firebase ref;
  final QueryFilter filter;
  final String type;

  StreamFactory(this.repo, this.ref, this.filter, this.type);

  StreamController<firebase.Event> controller;

  void addEvent(Event value) {
    var e = _mapEvent(value);
    if (e==null) return;
    new Future.microtask(() => controller.add(e));
  }

  firebase.Event _mapEvent(Event value) {
    if (value is ValueEvent) {
      if (type!="value") return null;
      return new firebase.Event(new firebase.DataSnapshotImpl(ref, value.value), null);
    } else if (value is ChildAddedEvent) {
      if (type!="child_added") return null;
      return new firebase.Event(new firebase.DataSnapshotImpl(ref.child(value.childKey.toString()), value.newValue), value.prevChildKey.toString());
    } else if (value is ChildChangedEvent) {
      if (type!="child_changed") return null;
      return new firebase.Event(new firebase.DataSnapshotImpl(ref.child(value.childKey.toString()), value.newValue), value.prevChildKey.toString());
    } else if (value is ChildMovedEvent) {
      if (type!="child_moved") return null;
      return new firebase.Event(new firebase.DataSnapshotImpl(ref.child(value.childKey.toString()), null), value.prevChildKey.toString());
    } else if (value is ChildRemovedEvent) {
      if (type!="child_removed") return null;
      return new firebase.Event(new firebase.DataSnapshotImpl(ref.child(value.childKey.toString()), value.oldValue), value.prevChildKey.toString());
    }
    return null;
  }

  void addError(Event error) {
    stopListen();
    controller.addError(error);
    controller.close();
  }

  void startListen() {
    repo.listen(ref.url.path, filter, type, addEvent);
    repo.listen(ref.url.path, filter, "cancel", addError);
  }

  void stopListen() {
    repo.unlisten(ref.url.path, filter, type, addEvent);
    repo.unlisten(ref.url.path, filter, "cancel", addError);
  }

  Stream<firebase.Event> call() {
    controller = new StreamController<firebase.Event>(
        onListen: startListen, onCancel: stopListen, sync: true);
    return controller.stream;
  }
}

class PushIdGenerator {
  static const String pushChars =
      "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
  int lastPushTime = 0;
  final List lastRandChars = new List(64);
  final Random random = new Random();

  String next(DateTime timestamp) {
    var now = timestamp.millisecondsSinceEpoch;

    var duplicateTime = now == lastPushTime;
    lastPushTime = now;
    var timeStampChars = new List(8);
    for (var i = 7; i >= 0; i--) {
      timeStampChars[i] = pushChars[now % 64];
      now = now ~/ 64;
    }
    var id = timeStampChars.join("");
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
  final Function update;
  final bool applyLocally;
  final Repo repo;
  final int order;
  final Completer<TreeStructuredData> completer = new Completer();

  static int _order = 0;

  static const int maxRetries = 25;

  int retryCount = 0;
  String abortReason;
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
    repo.listen(path.join("/"), null, "value", _onValue);
  }

  void _unwatch() {
    repo.unlisten(path.join("/"), null, "value", _onValue);
  }

  void run(TreeStructuredData currentState) {
    assert(status == null);
    if (retryCount >= maxRetries) {
      fail(new Exception("maxretries"));
      return;
    }

    currentInputSnapshot = currentState;
    try {
      var newVal = update(currentState.toJson());

      status = TransactionStatus.run;

      var newNode = new TreeStructuredData.fromJson(newVal, currentState.priority);
      currentOutputSnapshotRaw = newNode;
      currentOutputSnapshotResolved = ServerValue.resolve(newNode, repo._connection.serverValues);
      currentWriteId = repo._nextWriteId++;

      if (applyLocally)
        repo._syncTree.applyUserOverwrite(path,currentOutputSnapshotResolved
            , currentWriteId);
    } catch (e) {
      fail(e);
    }
  }

  void fail(dynamic e) {
    _unwatch();
    currentOutputSnapshotRaw = null;
    currentOutputSnapshotResolved = null;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
    status = TransactionStatus.completed;

    completer.completeError(e);
  }

  void stale() {
    status = null;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
  }

  void send() {
    assert(status == TransactionStatus.run);
    status = TransactionStatus.sent;
    retryCount++;
  }

  void abort(String reason) {
    switch (status) {
      case TransactionStatus.sentNeedsAbort:
        break;
      case TransactionStatus.sent:
        status = TransactionStatus.sentNeedsAbort;
        abortReason = reason;
        break;
      case TransactionStatus.run:
        fail(new Exception(reason));
        break;
      default:
        throw new StateError("Unable to abort transaction in state $status");
    }
  }

  void complete() {
    assert(status == TransactionStatus.sent);
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
    var c = value.children[k] ?? new TreeStructuredData();
    var newChild = updateChild(c, path.skip(1), child);
    var newValue = value.clone();
    if (newValue.isLeaf && !newChild.isNil) newValue.value = null;
    if (newChild.isNil)
      newValue.children.remove(k);
    else
      newValue.children[k] = newChild;
    return newValue;
  }
}

class TransactionsTree {
  final Repo repo;
  final TransactionsNode root = new TransactionsNode();

  TransactionsTree(this.repo);

  Future<TreeStructuredData> startTransaction(
      Path<Name> path, Function transactionUpdate, bool applyLocally) {
    var transaction =
        new Transaction(repo, path, transactionUpdate, applyLocally);
    var node = root.subtree(path, (a,b) => new TransactionsNode());

    var current = getLatestValue(repo, path);
    if (node.value.isEmpty) {
      node.input = current;
    }
    transaction.run(current);
    node.addTransaction(transaction);
    send();

    return transaction.completer.future;
  }

  void send() {
    root.send(repo, new Path()).then((finished) {
      if (!finished) send();
    });
  }

  void abort(Path<Name> path) {
    root.nodesOnPath(path).forEach((n) => n.abort());
  }
}

TreeStructuredData getLatestValue(Repo repo, Path<Name> path) {
  var node = repo._syncTree.root.subtree(path);
  if (node == null) return new TreeStructuredData();
  return node.value.valueForFilter(new QueryFilter());
}

class TransactionsNode extends TreeNode<Name, List<Transaction>> {
  TransactionsNode() : super([]);

  @override
  Map<Name, TransactionsNode> get children => super.children;

  @override
  TransactionsNode subtree(Path<Name> path,
          [TreeNode<Name, List<Transaction>> newInstance(List<Transaction> parent, Name childName)]) =>
      super.subtree(path, newInstance);

  bool get isReadyToSend =>
      value.every((t) => t.status == TransactionStatus.run) &&
      children.values.every((n) => n.isReadyToSend);

  bool get needsRerun =>
      value.any((t) => t.status == null) ||
      children.values.any((n) => n.needsRerun);

  @override
  Iterable<TransactionsNode> nodesOnPath(Path<Name> path) =>
      super.nodesOnPath(path);

  /// Completes all sent transactions
  void complete() {
    value.where((t) => t.isSent).forEach((m) => m.complete());
    value.where((t) => !t.isComplete).forEach((m) => m.status = null);
    value =
        value.where((t) => t.status != TransactionStatus.completed).toList();
    children.values.forEach((n) => n.complete());
  }

  /// Fails aborted transactions and resets other sent transactions
  void stale() {
    value
        .where((t) => t.isAborted)
        .forEach((m) => m.fail(new Exception(m.abortReason)));
    value.where((t) => !t.isAborted).forEach((m) => m.stale());
    value =
        value.where((t) => t.status != TransactionStatus.completed).toList();
    children.values.forEach((n) => n.stale());
  }

  /// Fails all sent transactions
  void fail(dynamic e) {
    value.where((t) => t.isSent).forEach((m) => m.fail(e));
    value =
        value.where((t) => t.status != TransactionStatus.completed).toList();
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
        rerun(path, getLatestValue(repo, path));
      }
      if (isReadyToSend) {
        var latestHash = input.hash;
        try {
          _send();
          await repo._connection
              .put(path.join("/"), output.toJson(true), hash: latestHash);
          complete();
          return false;
        } on ServerError catch (e) {
          if (e.code == "datastale")
            stale();
          else
            fail(e);
          return false;
        }
      }
      return true;
    } else {
      var allFinished = true;
      for (var k in children.keys) {
        allFinished =
            allFinished && await children[k].send(repo, path.child(k));
      }
      return allFinished;
    }
  }

  Iterable<Transaction> get transactionsInOrder =>
      new List.from(_transactions)..sort();

  Iterable<Transaction> get _transactions sync* {
    yield* value;
    yield* children.values.expand/*<Transaction>*/((n) => n._transactions);
  }

  void rerun(Path<Name> path, TreeStructuredData input) {
    this.input = input;

    var v = input;
    for (var t in transactionsInOrder) {
      var p = t.path.skip(path.length);
      t.run(v.subtree(p, (a,b) => new TreeStructuredData()) ??
          new TreeStructuredData());
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

  void abort() {
    for (var txn in value) {
      txn.abort("set");
    }
    value = value.where((t) => !t.isComplete).toList();
  }
}

class SparseSnapshotTree extends TreeNode<Name, TreeStructuredData> {
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
        children.putIfAbsent(childKey, () => new SparseSnapshotTree());
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
            remember(new Path.from([key]), tree);
          });
          return this.forget(path);
        }
      } else {
        var childKey = path.first;
        path = path.skip(1);
        if (this.children.containsKey(childKey)) {
          var safeToRemove = children[childKey].forget(path);
          if (safeToRemove) {
            children.remove(childKey);
          }
        }
        if (this.children.isEmpty) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
}
