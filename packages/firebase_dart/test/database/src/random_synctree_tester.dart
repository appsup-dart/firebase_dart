import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/event.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/synctree_recorder.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

import '../persistence/mock.dart';

final _logger = Logger('firebase.test.random_synctree');

class MemoryQueryRegistrar extends QueryRegistrar {
  final List<MapEntry<QuerySpec, Completer<void>>> outstandingListens;

  final Map<QuerySpec, TreeStructuredData> registeredListens;

  MemoryQueryRegistrar(this.outstandingListens, this.registeredListens);

  @override
  Future<bool> register(QuerySpec query,
      {String? hash, required int priority}) async {
    var c = Completer<void>();
    outstandingListens.add(MapEntry(query, c));
    await c.future;
    return true;
  }

  @override
  Future<void> unregister(QuerySpec query) async {
    outstandingListens.removeWhere((e) => e.key == query);
    registeredListens.remove(query);
  }

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  void revoke(QuerySpec query) {
    outstandingListens.removeWhere((e) => e.key == query);
    registeredListens.remove(query);
  }
}

class SyncTreeTester {
  final bool usePersistence;

  late final SyncTree syncTree = SyncTree(
    'test:///',
    queryRegistrar: MemoryQueryRegistrar(outstandingListens, registeredListens),
    persistenceManager: usePersistence
        ? DefaultPersistenceManager(
            HivePersistenceStorageEngine(
                KeyValueDatabase(Hive.box('firebase-db-storage')))
              ..clear(),
            TestCachePolicy(0.1))
        : null,
  );

  /// A list of all listeners that are registered on the server, but not yet
  /// acknowledged.
  final List<MapEntry<QuerySpec, Completer<void>>> outstandingListens = [];

  /// All listeners that are registered in the sync tree.
  final Map<int, MapEntry<QuerySpec, EventListener>> userListens = {};

  /// The last reported value for each registered listener.
  final Map<QuerySpec, TreeStructuredData> registeredListens = {};

  /// The current state of the server.
  TreeStructuredData _currentServerState = TreeStructuredData();

  /// A list of all writes that are pending acknowledgement from the server.
  final Map<int, TreeOperation> outstandingWrites = {};

  TreeStructuredData get currentServerState => _currentServerState;

  SyncTreeTester({this.usePersistence = true});

  void applyEvent(SyncTreeOperation event) {
    _logger.fine(event);

    switch (event.type) {
      case SyncTreeOperationType.listen:
        applyUserListen(event.query!, event.listenType!, event.listenerId!);
        break;
      case SyncTreeOperationType.unlisten:
        applyUserUnlisten(event.query!, event.listenType!, event.listenerId!);
        break;
      case SyncTreeOperationType.operation:
        applyUserOperation(event.operation!, event.writeId!);
        break;
      case SyncTreeOperationType.ackListen:
        applyAckListen(event.query!);
        break;
      case SyncTreeOperationType.ackWrite:
        applyAckWrite(event.query!.path, event.writeId!);
        break;
      case SyncTreeOperationType.revertWrite:
        applyRevertWrite(event.query!.path, event.writeId!);
        break;
      case SyncTreeOperationType.serverOperation:
        applyServerOperation(event.operation!);
        break;
      case SyncTreeOperationType.ackUnlisten:
        // TODO: Handle this case.
        break;
      case SyncTreeOperationType.listenRevoked:
        // TODO: Handle this case.
        break;
      case SyncTreeOperationType.upgrade:
        // TODO: Handle this case.
        break;
    }
  }

  void applyUserUnlisten(QuerySpec query, String listenType, int listenerId) {
    syncTree.removeEventListener(listenType, query.path, query.params,
        userListens.remove(listenerId)!.value);
  }

  void applyUserListen(QuerySpec query, String listenType, int listenerId) {
    userListens[listenerId] ??= MapEntry(query, (event) {});
    syncTree.addEventListener(
        listenType, query.path, query.params, userListens[listenerId]!.value);
  }

  void applyUserOperation(TreeOperation operation, int writeId) {
    syncTree.applyUserOperation(operation, writeId);
    outstandingWrites[writeId] = operation;
  }

  void applyAckListen(QuerySpec query) {
    if (outstandingListens.isEmpty || outstandingListens.first.key != query) {
      return;
    }
    var e = outstandingListens.removeAt(0);
    _updateCurrentServerStateToQuery(query);
    e.value.complete();
  }

  void applyAckWrite(Path<Name> path, int writeId) {
    var operation = outstandingWrites.remove(writeId);
    if (operation == null) {
      _logger.warning('No outstanding write for $writeId at path $path');
      return;
    }
    _updateServerState(operation.apply(_currentServerState));
    syncTree.applyAck(path, writeId, true);
  }

  void applyRevertWrite(Path<Name> path, int writeId) {
    var operation = outstandingWrites.remove(writeId);
    if (operation == null) {
      _logger.warning('No outstanding write for $writeId at path $path');
      return;
    }
    syncTree.applyAck(path, writeId, false);
  }

  void applyServerOperation(TreeOperation operation) {
    var newState = operation.apply(_currentServerState);
    _updateServerState(newState);
  }

  void _updateCurrentServerStateToQuery(QuerySpec query) {
    var v = currentServerState.getChild(query.path).withFilter(query.params);
    if (registeredListens[query] == v) return;
    // TODO only send difference
    syncTree.applyServerOperation(
        TreeOperation(query.path, Overwrite(v)), query);
    registeredListens[query] = v;
  }

  void _updateServerState(TreeStructuredData newState) {
    if (newState == _currentServerState) return;
    _currentServerState = newState;
    for (var q in registeredListens.keys) {
      _updateCurrentServerStateToQuery(q);
    }
  }
}

extension SyncTreeTesterRecording on SyncTreeRecording {
  void replay(FakeAsync fakeAsync, {bool usePersistence = true}) {
    var tester = SyncTreeTester(usePersistence: usePersistence);
    for (var e in events) {
      tester.applyEvent(e);
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      tester.checkServerVersions();
      tester.checkPersistedServerCache();
      tester.checkLocalVersions();
    }
  }
}

class SyncTreeTesterRecorder extends SyncTreeTester {
  SyncTreeTesterRecorder({super.usePersistence = true});

  SyncTreeRecording? recording;
  void startRecording() {
    assert(recording == null);
    recording = SyncTreeRecording();
  }

  SyncTreeRecording stopRecording() {
    var r = recording!;
    recording = null;
    return r;
  }

  @override
  void applyEvent(SyncTreeOperation event) {
    recording?.events.add(event);
    super.applyEvent(event);
  }
}

class RandomSyncTreeRecordingGenerator {
  static Logger get logger => _logger;

  final RandomGenerator random;

  final double listenProbability;

  final double unlistenProbability;

  final double userOperationProbability;

  final double serverOperationProbability;

  final double serverListenResponseProbability;

  final double serverAckProbability;

  final double revertProbability;

  final SyncTreeTesterRecorder tester;

  int _currentWriteId = 0;

  RandomSyncTreeRecordingGenerator(
      {int? seed,
      this.listenProbability = 0.1,
      this.unlistenProbability = 0.0,
      this.userOperationProbability = 0.1,
      this.serverListenResponseProbability = 0.1,
      this.serverAckProbability = 0.9,
      this.revertProbability = 0.2,
      this.serverOperationProbability = 0.1,
      bool usePersistence = true})
      : random = RandomGenerator(seed ?? DateTime.now().millisecondsSinceEpoch),
        tester = SyncTreeTesterRecorder(usePersistence: usePersistence);

  SyncTreeOperation _generateUserListen() {
    var query = random.nextQuerySpec();
    return SyncTreeOperation.listen(query, 'cancel', Object().hashCode);
  }

  SyncTreeOperation _generateUserUnlisten() {
    var id = tester.userListens.keys
        .toList()[random.nextInt(tester.userListens.length)];
    return SyncTreeOperation.unlisten(
        tester.userListens[id]!.key, 'cancel', id);
  }

  SyncTreeOperation _generateUserOperation() {
    var operation = random.nextOperation();
    return SyncTreeOperation.operation(operation, _currentWriteId++);
  }

  SyncTreeOperation? _handleOutstandingListen() {
    if (tester.outstandingListens.isEmpty) return null;
    return SyncTreeOperation.ackListen(tester.outstandingListens.first.key);
  }

  SyncTreeOperation? _handleOutstandingWrite() {
    if (tester.outstandingWrites.isEmpty) return null;

    var writeId = tester.outstandingWrites.keys.first;
    var op = tester.outstandingWrites[writeId]!;
    var path = op.path;
    var isEmptyPriorityError = path.isNotEmpty &&
        path.last.isPriorityChildName &&
        tester._currentServerState.getChild(path.parent!).isEmpty;

    if (random.nextDouble() < revertProbability || isEmptyPriorityError) {
      return SyncTreeOperation.revertWrite(path, writeId);
    } else {
      return SyncTreeOperation.ackWrite(path, writeId);
    }
  }

  SyncTreeOperation _generateServerOperation() {
    var op = random.nextOperation();
    return SyncTreeOperation.serverOperation(op, QuerySpec(Path.from([])));
  }

  void next() {
    SyncTreeOperation? event;
    if (random.nextDouble() < listenProbability) {
      event = _generateUserListen();
    } else if (unlistenProbability != 0 &&
        tester.userListens.isNotEmpty &&
        random.nextDouble() < unlistenProbability) {
      event = _generateUserUnlisten();
    } else if (random.nextDouble() < userOperationProbability) {
      event = _generateUserOperation();
    } else if (random.nextDouble() < serverListenResponseProbability) {
      event = _handleOutstandingListen();
    } else if (random.nextDouble() < serverAckProbability) {
      event = _handleOutstandingWrite();
    } else if (random.nextDouble() < serverOperationProbability) {
      event = _generateServerOperation();
    }

    if (event != null) {
      tester.applyEvent(event);
    }
  }

  void flush() {
    while (tester.outstandingListens.isNotEmpty) {
      var event = _handleOutstandingListen();
      if (event == null) break;
      tester.applyEvent(event);
      return;
    }
    while (tester.outstandingWrites.isNotEmpty) {
      var event = _handleOutstandingWrite();
      if (event == null) break;
      tester.applyEvent(event);
      return;
    }
  }
}

extension SyncTreeTesterCheckX on SyncTreeTester {
  void checkAllViewsComplete() {
    if (outstandingListens.isNotEmpty || outstandingWrites.isNotEmpty) {
      throw StateError(
          'Should call flush prior to checking views for completeness');
    }
    syncTree.root.forEachNode((path, node) {
      node.views.forEach((params, view) {
        if (!view.data.localVersion.isComplete) {
          throw StateError(
              'Local version should be complete at path ${path.join('/')}');
        }
        if (!view.data.serverVersion.isComplete) {
          throw StateError(
              'Server version should be complete at path ${path.join('/')}');
        }
      });
    });
  }

  void checkPersistedActiveQueries() {
    if (!usePersistence) return;
    var trackedQueries = storageEngine!
        .loadTrackedQueries()
        .where((v) => v.active)
        .map((v) => v.querySpec);
    expect(trackedQueries.toSet(), <QuerySpec>{
      ...outstandingListens.map((v) => v.key),
      ...registeredListens.keys
    });
  }

  void checkServerVersions() {
    syncTree.root.forEachNode((path, node) {
      node.views.forEach((params, view) {
        if (!view.isInSync) return;

        if (view.data.serverVersion.isComplete) {
          // complete data should match with value on server
          var serverValue =
              currentServerState.getChild(path).withFilter(params);
          var serverView = view.data.serverVersion.value.withFilter(params);
          if (serverValue != serverView) {
            throw StateError(
                'SyncTree has an incorrect view of the server for $path $params: serverValue = $serverValue, serverView = $serverView');
          }
        }
      });
    });
  }

  HivePersistenceStorageEngine? get storageEngine => usePersistence
      ? (syncTree.persistenceManager as DefaultPersistenceManager).storageLayer
          as HivePersistenceStorageEngine
      : null;

  void checkPersistedWrites() {
    if (!usePersistence) return;
    expect(storageEngine!.loadUserOperations(), outstandingWrites);
  }

  void checkPersistedServerCache() {
    if (!usePersistence) return;
    var v = storageEngine!.database.loadServerCache().value;
    syncTree.root.forEachNode((path, node) {
      if (outstandingListens
          .map((v) => v.key)
          .any((q) => path.isDescendantOf(q.path) || path == q.path)) {
        return;
      }
      node.views.forEach((params, view) {
        if (!view.isInSync) return;
        if (view.data.serverVersion.isComplete) {
          // complete data should match with value on server
          var persistedValue = v.getChild(path).withFilter(params);
          var serverView = view.data.serverVersion.value;
          expect(persistedValue, serverView,
              reason: 'No match at path $path with params $params');
        }
      });
    });
  }

  void checkLocalVersions() {
    var v = currentServerState;
    for (var w in outstandingWrites.entries) {
      v = w.value.apply(v);
    }

    syncTree.root.forEachNode((path, node) {
      node.views.forEach((params, view) {
        if (outstandingListens
            .map((v) => v.key)
            .any((q) => path.isDescendantOf(q.path) || path == q.path)) {
          return;
        }

        // TODO: once completeness on user operation is correctly implemented, local versions should also match when there are still outstanding writes
        if (outstandingWrites.entries
            .map((v) => v.value)
            .any((o) => o.path.isDescendantOf(path) || path == o.path)) {
          return;
        }

        if (!view.isInSync) return;

        if (view.data.localVersion.isComplete) {
          // complete data should match with value on server
          var serverValue = v.getChild(path).withFilter(params);
          var serverView = view.data.localVersion.value;
          if (serverValue != serverView) {
            throw StateError(
                'SyncTree has an incorrect local version for $path $params: serverValue = $serverValue, serverView = $serverView');
          }
        }
      });
    });
  }
}

extension SyncTreeX on SyncTree {
  void applyUserOperation(TreeOperation operation, int writeId) {
    var op = operation.nodeOperation;
    if (op is Merge) {
      applyUserMerge(
          operation.path,
          {
            for (var o in op.overwrites)
              o.path: (o.nodeOperation as Overwrite).value
          },
          writeId);
    } else if (op is SetPriority) {
      applyUserOverwrite(
          operation.path.child(Name('.priority')), op.value, writeId);
    } else {
      applyUserOverwrite(operation.path, (op as Overwrite).value, writeId);
    }
  }
}

class RandomGenerator {
  final Random _random;

  final RandomGeneratorParameters parameters;

  RandomGenerator([int? seed])
      : _random = Random(seed),
        parameters = RandomGeneratorParameters() {
    print('Random seed $seed');
  }

  Name nextKey() {
    if (_random.nextDouble() < parameters.indexKeyProbability) {
      return Name('index-key');
    } else {
      return Name('key-${_random.nextInt(parameters.maxKeyValues)}');
    }
  }

  Path<Name> nextPath(int maxDepth) {
    var depth = _random.nextInt(maxDepth);

    return Path.from([...Iterable.generate(depth, (_) => nextKey())]);
  }

  TreeStructuredDataOrdering nextOrdering() {
    if (_random.nextDouble() < parameters.orderByKeyProbability) {
      return TreeStructuredDataOrdering.byKey();
    } else if (_random.nextDouble() < parameters.orderByPriorityProbability) {
      return TreeStructuredDataOrdering.byPriority();
    } else if (_random.nextDouble() < parameters.orderByValueProbability) {
      return TreeStructuredDataOrdering.byValue();
    } else {
      return TreeStructuredDataOrdering.byChild('index-key');
    }
  }

  QuerySpec nextQuerySpec() {
    return QuerySpec(
      nextPath(parameters.maxListenDepth),
      nextQueryParams(),
    );
  }

  QueryFilter nextQueryParams() {
    if (nextDouble() < parameters.defaultParamsProbability) {
      return QueryFilter();
    } else {
      var ordering = nextOrdering();
      var limit = nextBool();
      return QueryFilter(
          ordering: ordering,
          limit: !limit ? null : nextInt(30) + 1,
          reversed: limit && nextBool(),
          validInterval:
              nextKeyValueInterval(keyOnly: ordering is KeyOrdering));
    }
  }

  Value? nextValue({bool allowNull = false}) {
    var randValue = nextDouble();
    if (allowNull && randValue < 0.2) {
      return null;
    } else if (randValue < 0.4) {
      return Value.bool(nextBool());
    } else if (randValue < 0.6) {
      return Value.string('string-${nextInt(1 << 31)}');
    } else if (randValue < 0.8) {
      return Value.num(nextDouble());
    } else {
      return Value.num(nextInt(1 << 31));
    }
  }

  KeyValueInterval nextKeyValueInterval({bool keyOnly = false}) {
    var startValue = keyOnly
        ? TreeStructuredData()
        : nextBool()
            ? null
            : TreeStructuredData.leaf(nextValue()!);
    var endValue = keyOnly
        ? TreeStructuredData()
        : nextBool()
            ? null
            : TreeStructuredData.leaf(nextValue()!);
    if (startValue != null &&
        endValue != null &&
        Comparable.compare(startValue, endValue) > 0) {
      var v = startValue;
      startValue = endValue;
      endValue = v;
    }

    var startKey = startValue == null
        ? null
        : nextBool()
            ? Name.min
            : nextKey();
    var endKey = endValue == null
        ? null
        : nextBool()
            ? Name.max
            : nextKey();
    if (startKey != null &&
        endKey != null &&
        startValue == endValue &&
        Comparable.compare(startKey, endKey) > 0) {
      var v = startKey;
      startKey = endKey;
      endKey = v;
    }
    return KeyValueInterval(startKey, startValue, endKey, endValue);
  }

  double nextDouble() => _random.nextDouble();

  bool nextBool() => _random.nextBool();

  int nextInt(int max) => _random.nextInt(max);

  Merge nextMerge(int currentDepth) {
    var numMergeNodes = nextInt(parameters.maxMergeSize) + 1;
    return Merge({
      for (var i = 0; i < numMergeNodes; i++)
        Path.from([nextKey()]): nextTreeValue(currentDepth + 1)
    });
  }

  TreeStructuredData nextTreeValue(int currentDepth, {bool allowNull = true}) {
    if (currentDepth >= parameters.maxDepth) {
      var v = nextValue(allowNull: allowNull);
      return v == null ? TreeStructuredData() : TreeStructuredData.leaf(v);
    } else {
      var randValue = _random.nextDouble();
      if (allowNull && randValue < 0.2) {
        return TreeStructuredData();
      } else if (randValue < 0.4) {
        var v = nextValue(allowNull: allowNull);
        return v == null ? TreeStructuredData() : TreeStructuredData.leaf(v);
      } else {
        var numChildren = 1 +
            _random.nextInt(currentDepth == 0
                ? parameters.maxTopChildren
                : parameters.maxOtherChildren);
        return TreeStructuredData.nonLeaf({
          for (var i = 0; i < numChildren; i++)
            nextKey(): nextTreeValue(currentDepth + 1, allowNull: false)
        }, nextValue());
      }
    }
  }

  Overwrite nextOverwrite(int currentDepth) {
    return Overwrite(nextTreeValue(currentDepth));
  }

  SetPriority nextSetPriority() {
    return SetPriority(nextValue(allowNull: true));
  }

  Operation nextNodeOperation(int currentDepth) {
    if (nextDouble() < parameters.setPriorityProbability) {
      return nextSetPriority();
    } else if (nextDouble() < parameters.mergeProbability) {
      return nextMerge(currentDepth);
    } else {
      return nextOverwrite(currentDepth);
    }
  }

  TreeOperation nextOperation() {
    var path = nextPath(parameters.maxDepth);
    var op = nextNodeOperation(path.length);

    return TreeOperation(path, op);
  }
}

class RandomGeneratorParameters {
  final int maxKeyValues;

  final double setPriorityProbability;

  final double indexKeyProbability;

  final double orderByKeyProbability;

  final double orderByPriorityProbability;
  final double orderByValueProbability;

  final double defaultParamsProbability;

  final double mergeProbability;

  final int maxListenDepth;

  final int maxMergeSize;

  final int maxDepth;

  final int maxTopChildren;

  final int maxOtherChildren;

  RandomGeneratorParameters(
      {this.defaultParamsProbability = 0.5,
      this.orderByKeyProbability = 0.1,
      this.orderByPriorityProbability = 0.1,
      this.orderByValueProbability = 0.1,
      this.maxKeyValues = 100,
      this.setPriorityProbability = 0.1,
      this.indexKeyProbability = 0.1,
      this.maxListenDepth = 3,
      this.mergeProbability = 0.3,
      this.maxMergeSize = 5,
      this.maxDepth = 5,
      this.maxOtherChildren = 3,
      this.maxTopChildren = 10});
}
