// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/database.dart'
    show FirebaseDatabaseException, MutableData, TransactionHandler;
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sortedmap/sortedmap.dart';

import '../../database.dart' as firebase;
import 'connection.dart';
import 'event.dart';
import 'events/cancel.dart';
import 'events/child.dart';
import 'events/value.dart';
import 'firebase_impl.dart' as firebase;
import 'firebase_impl.dart';
import 'operations/tree.dart';
import 'synctree.dart';
import 'tree.dart';
import 'treestructureddata.dart';
import 'utils.dart';

part 'transaction.dart';

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

  static bool hasInstance(firebase.FirebaseDatabase db) => _repos[db] != null;

  final SyncTree _syncTree;

  final SyncTree _infoSyncTree;

  final PushIdGenerator pushIds = PushIdGenerator();

  int _nextWriteId = 0;
  late TransactionsTree _transactions;
  final SparseSnapshotTree _onDisconnect = SparseSnapshotTree();

  late StreamSubscription _authStateChangesSubscription;

  factory Repo(firebase.FirebaseDatabase db) {
    var url = Uri.parse(db.databaseURL);

    return _repos.putIfAbsent(db, () {
      var auth = FirebaseAuth.instanceFor(app: db.app);

      var connection =
          PersistentConnection(url, authTokenProvider: (refresh) async {
        var user = await auth.authStateChanges().first;
        if (user == null) return null;
        var token = await user.getIdToken(refresh);
        return token;
      })
            ..initialize();

      return Repo._(url, connection, auth.idTokenChanges(),
          (db as FirebaseDatabaseImpl).persistenceManager);
    });
  }

  Repo._(this.url, this._connection, Stream<User?> authStateChanges,
      PersistenceManager persistenceManager)
      : _syncTree = SyncTree(url.toString(),
            remoteRegister: (path, filter, hash) async {
          var warnings = await _connection.listen(path.join('/'),
              query: filter, hash: hash);
          for (var w in warnings) {
            _logger.warning(w);
          }
        }, remoteUnregister: (path, filter) async {
          await _connection.unlisten(path.join('/'), query: filter);
        }, persistenceManager: persistenceManager),
        _infoSyncTree = SyncTree(url.toString()) {
    _infoSyncTree.addEventListener(
        'value', Path.from([]), QueryFilter(), (event) {});
    _updateInfo(dotInfoAuthenticated, false);
    _updateInfo(dotInfoConnected, false);
    _authStateChangesSubscription = authStateChanges.listen((user) async {
      _updateInfo(dotInfoAuthenticated, user != null);
      try {
        return _connection
            .refreshAuthToken(user == null ? null : user.getIdToken());
      } catch (e, tr) {
        _logger.warning('Could not refresh auth token.', e, tr);
      }
    });

    _transactions = TransactionsTree(this);
    _connection.onConnect.listen((v) {
      _updateInfo(dotInfoConnected, v);
      if (v) {
        _updateInfo(dotInfoServerTimeOffset,
            _connection.serverTime.difference(DateTime.now()).inMilliseconds);
      }
      if (!v) {
        _runOnDisconnectEvents();
      }
    });
    _connection.onDataOperation.listen((event) {
      if (event.type == OperationEventType.listenRevoked) {
        _syncTree.applyListenRevoked(event.path!, event.query);
      } else {
        _syncTree.applyServerOperation(event.operation!, event.query);
      }
    });
  }

  SyncTree get syncTree => _syncTree;

  RemoteListenerRegistrar get registrar => _syncTree.registrar;

  Future<void> triggerDisconnect() => _connection.disconnect();

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
    _syncTree.destroy();
    _unlistenTimers.forEach((v) => v.cancel());
    _repos.removeWhere((key, value) => value == this);
  }

  void resume() => _connection.resume(_interruptReason);

  void interrupt() => _connection.interrupt(_interruptReason);

  /// The current authData
  Map<String, dynamic>? get authData => _connection.authData;

  /// Stream of auth data.
  ///
  /// When a user is logged in, its auth data is posted. When logged of, `null`
  /// is posted.
  Stream<Map<String, dynamic>?> get onAuth => _connection.onAuth;

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
        ServerValueX.resolve(newValue, _connection.serverValues), writeId);
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
          value.values.map<TreeStructuredData>((v) => ServerValueX.resolve(
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
      String path, QueryFilter? filter, String type, EventListener cb) async {
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
      String path, QueryFilter? filter, String type, EventListener cb) {
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
  TreeStructuredData? cachedValue(String path, QueryFilter filter) {
    path = _preparePath(path);
    var tree = _syncTree.root.subtreeNullable(Name.parsePath(path));
    if (tree == null) return null;
    return tree.value.valueForFilter(filter);
  }

  /// Helper function to create a stream for a particular event type.
  Stream<firebase.Event> createStream(
      firebase.DatabaseReference ref, QueryFilter filter, String type) {
    return DeferStream(() => StreamFactory(this, ref, filter, type)(),
        reusable: true);
  }

  Future<TreeStructuredData?> transaction(
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
          TreeOperation.overwrite(path, ServerValueX.resolve(snap, sv)), null);
      _transactions.abort(path, FirebaseDatabaseException.overriddenBySet());
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  void mockConnectionLost() => _connection.mockConnectionLost();

  void mockResetMessage() => _connection.mockResetMessage();

  void _updateInfo(String pathString, dynamic value) {
    _infoSyncTree.applyServerOperation(
        TreeOperation.overwrite(Name.parsePath('$dotInfo/$pathString'),
            TreeStructuredData.fromJson(value)),
        null);
  }
}

class StreamFactory {
  final Repo repo;
  final firebase.DatabaseReference ref;
  final QueryFilter filter;
  final String type;

  StreamFactory(this.repo, this.ref, this.filter, this.type);

  late StreamController<firebase.Event> controller;

  void addEvent(Event value) {
    var e = _mapEvent(value);
    if (e == null) return;
    Future.microtask(() => controller.add(e));
  }

  firebase.Event? _mapEvent(Event value) {
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
          firebase.DataSnapshotImpl(
              ref.child(value.childKey.toString()), TreeStructuredData()),
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
      controller.addError(event.error!, event.stackTrace);
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
  final lastRandChars = List.filled(64, 0);
  final random = Random();

  String next(DateTime timestamp) {
    var now = timestamp.millisecondsSinceEpoch;

    var duplicateTime = now == lastPushTime;
    lastPushTime = now;
    var timeStampChars = List.filled(8, '');
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
