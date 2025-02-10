import 'dart:async';
import 'dart:convert';
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
import 'package:logging/logging.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

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
    outstandingListens.remove(query);
    registeredListens.remove(query);
  }

  @override
  Future<void> close() {
    return Future.value();
  }
}

enum SyncTreeTesterEventType {
  listen,
  unlisten,
  operation,
  ackListen,
  ackWrite,
  revertWrite,
  serverOperation
}

class SyncTreeTesterEvent {
  final SyncTreeTesterEventType type;

  final QuerySpec? query;

  TreeOperation? operation;

  SyncTreeTesterEvent.listen(this.query)
      : operation = null,
        type = SyncTreeTesterEventType.listen;
  SyncTreeTesterEvent.unlisten(this.query)
      : operation = null,
        type = SyncTreeTesterEventType.unlisten;
  SyncTreeTesterEvent.operation(this.operation)
      : query = null,
        type = SyncTreeTesterEventType.operation;
  SyncTreeTesterEvent.ackListen(this.query)
      : operation = null,
        type = SyncTreeTesterEventType.ackListen;
  SyncTreeTesterEvent.ackWrite(this.operation)
      : query = null,
        type = SyncTreeTesterEventType.ackWrite;
  SyncTreeTesterEvent.revertWrite(this.operation)
      : query = null,
        type = SyncTreeTesterEventType.revertWrite;
  SyncTreeTesterEvent.serverOperation(this.operation)
      : query = null,
        type = SyncTreeTesterEventType.serverOperation;

  @override
  String toString() {
    return 'SyncTreeTesterEvent{type: $type, query: $query, operation: $operation}';
  }

  String toCode() {
    switch (type) {
      case SyncTreeTesterEventType.listen:
        return 'SyncTreeTesterEvent.listen(${query!.toCode()})';
      case SyncTreeTesterEventType.unlisten:
        return 'SyncTreeTesterEvent.unlisten(${query!.toCode()})';
      case SyncTreeTesterEventType.operation:
        return 'SyncTreeTesterEvent.operation(${operation!.toCode()})';
      case SyncTreeTesterEventType.ackListen:
        return 'SyncTreeTesterEvent.ackListen(${query!.toCode()})';
      case SyncTreeTesterEventType.ackWrite:
        return 'SyncTreeTesterEvent.ackWrite(${operation!.toCode()})';
      case SyncTreeTesterEventType.revertWrite:
        return 'SyncTreeTesterEvent.revertWrite(${operation!.toCode()})';
      case SyncTreeTesterEventType.serverOperation:
        return 'SyncTreeTesterEvent.serverOperation(${operation!.toCode()})';
    }
  }
}

extension QuerySpecCodeX on QuerySpec {
  String toCode() {
    return 'QuerySpec(${path.toCode()}, ${params.toCode()})';
  }
}

extension PathCodeX on Path<Name> {
  String toCode() {
    return 'Path.from([${map((v) => v.toCode()).join(', ')}])';
  }
}

extension NameCodeX on Name {
  String toCode() {
    return 'Name(\'$this\')';
  }
}

extension QueryFilterCodeX on QueryFilter {
  String toCode() {
    return 'QueryFilter(ordering: ${ordering.toCode()}, limit: $limit, reversed: $reversed, validInterval: ${validInterval.toCode()})';
  }
}

extension OrderingCodeX on Ordering {
  String toCode() {
    if (this is KeyOrdering) {
      return 'KeyOrdering()';
    } else if (this is PriorityOrdering) {
      return 'PriorityOrdering()';
    } else if (this is ValueOrdering) {
      return 'ValueOrdering()';
    } else {
      return 'ChildOrdering(\'${(this as ChildOrdering).child}\')';
    }
  }
}

extension KeyValueIntervalCodeX on KeyValueInterval {
  String toCode() {
    return 'KeyValueInterval(${(start.key as Name?)?.toCode()}, ${(start.value as TreeStructuredData?)?.toCode()}, ${(end.key as Name?)?.toCode()}, ${(end.value as TreeStructuredData?)?.toCode()})';
  }
}

extension TreeOperationCodeX on TreeOperation {
  String toCode() {
    return 'TreeOperation(${path.toCode()}, ${nodeOperation?.toCode()})';
  }
}

extension OperationCodeX on Operation {
  String toCode() {
    if (this is Overwrite) {
      return 'Overwrite(${(this as Overwrite).value.toCode()})';
    } else if (this is Merge) {
      return 'Merge([${(this as Merge).overwrites.map((o) => o.toCode()).join(', ')}])';
    } else {
      return 'SetPriority(${(this as SetPriority).value.toCode()})';
    }
  }
}

extension TreeStructuredDataCodeX on TreeStructuredData {
  String toCode() {
    return 'TreeStructuredData.fromJson(${json.encode(toJson())})';
  }
}

class SyncTreeTester {
  late final SyncTree syncTree = SyncTree(
    'test:///',
    queryRegistrar: MemoryQueryRegistrar(outstandingListens, registeredListens),
    // persistenceManager: DefaultPersistenceManager(
    //     HivePersistenceStorageEngine(
    //         KeyValueDatabase(Hive.box('firebase-db-storage'))),
    //     TestCachePolicy(0.1)),
  );

  final List<MapEntry<QuerySpec, Completer<void>>> outstandingListens = [];

  final Map<QuerySpec, EventListener> userListens = {};

  final Map<QuerySpec, TreeStructuredData> registeredListens = {};

  TreeStructuredData _currentServerState = TreeStructuredData();

  final List<MapEntry<int, TreeOperation>> outstandingWrites = [];

  TreeStructuredData get currentServerState => _currentServerState;

  int _currentWriteId = 0;

  void applyEvent(SyncTreeTesterEvent event) {
    _logger.fine(event);

    switch (event.type) {
      case SyncTreeTesterEventType.listen:
        applyUserListen(event.query!);
        break;
      case SyncTreeTesterEventType.unlisten:
        applyUserUnlisten(event.query!);
        break;
      case SyncTreeTesterEventType.operation:
        applyUserOperation(event.operation!);
        break;
      case SyncTreeTesterEventType.ackListen:
        applyAckListen(event.query!);
        break;
      case SyncTreeTesterEventType.ackWrite:
        applyAckWrite(event.operation!);
        break;
      case SyncTreeTesterEventType.revertWrite:
        applyRevertWrite(event.operation!);
        break;
      case SyncTreeTesterEventType.serverOperation:
        applyServerOperation(event.operation!);
        break;
    }
  }

  void applyUserUnlisten(QuerySpec query) {
    syncTree.removeEventListener(
        'cancel', query.path, query.params, userListens.remove(query)!);
  }

  void applyUserListen(QuerySpec query) {
    userListens[query] ??= (event) {
      userListens.remove(query);
    };
    syncTree.addEventListener(
        'cancel', query.path, query.params, userListens[query]!);
  }

  void applyUserOperation(TreeOperation operation) {
    var taggedOperation = MapEntry(_currentWriteId++, operation);
    syncTree.applyUserOperation(taggedOperation.value, taggedOperation.key);
    outstandingWrites.add(taggedOperation);
  }

  void applyAckListen(QuerySpec query) {
    if (outstandingListens.isEmpty || outstandingListens.first.key != query) {
      return;
    }
    var e = outstandingListens.removeAt(0);
    _updateCurrentServerStateToQuery(query);
    e.value.complete();
  }

  void applyAckWrite(TreeOperation operation) {
    if (outstandingWrites.isEmpty ||
        outstandingWrites.first.value != operation) {
      return;
    }
    var e = outstandingWrites.removeAt(0);
    _updateServerState(operation.apply(_currentServerState));
    syncTree.applyAck(operation.path, e.key, true);
  }

  void applyRevertWrite(TreeOperation operation) {
    if (outstandingWrites.isEmpty ||
        outstandingWrites.first.value != operation) {
      return;
    }
    var e = outstandingWrites.removeAt(0);
    syncTree.applyAck(operation.path, e.key, false);
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

class SyncTreeTesterRecording {
  List<SyncTreeTesterEvent> events = [];

  SyncTreeTesterRecording({List<SyncTreeTesterEvent>? events})
      : events = events ?? [];

  void replay(FakeAsync fakeAsync) {
    var tester = SyncTreeTester();
    for (var e in events) {
      tester.applyEvent(e);
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      tester.checkServerVersions();
      tester.checkLocalVersions();
    }
  }

  @override
  String toString() {
    return 'SyncTreeTesterRecording{events: $events}';
  }

  String toCode() {
    var buffer = StringBuffer();
    buffer.writeln('SyncTreeTesterRecording(');
    buffer.writeln('  events: [');
    for (var e in events) {
      buffer.writeln('    ${e.toCode()},');
    }
    buffer.writeln('  ]');
    buffer.writeln(')');
    return buffer.toString();
  }
}

mixin SyncTreeTesterRecorder on SyncTreeTester {
  SyncTreeTesterRecording? recording;
  void startRecording() {
    assert(recording == null);
    recording = SyncTreeTesterRecording();
  }

  SyncTreeTesterRecording stopRecording() {
    var r = recording!;
    recording = null;
    return r;
  }

  @override
  void applyEvent(SyncTreeTesterEvent event) {
    recording?.events.add(event);
    super.applyEvent(event);
  }
}

class RandomSyncTreeTester with SyncTreeTester, SyncTreeTesterRecorder {
  static Logger get logger => _logger;

  final RandomGenerator random;

  final double listenProbability;

  final double unlistenProbability;

  final double userOperationProbability;

  final double serverOperationProbability;

  final double serverListenResponseProbability;

  final double serverAckProbability;

  final double revertProbability;

  RandomSyncTreeTester(
      {int? seed,
      this.listenProbability = 0.1,
      this.unlistenProbability = 0.0,
      this.userOperationProbability = 0.1,
      this.serverListenResponseProbability = 0.1,
      this.serverAckProbability = 0.9,
      this.revertProbability = 0.2,
      this.serverOperationProbability = 0.1})
      : random = RandomGenerator(seed ?? DateTime.now().millisecondsSinceEpoch);

  SyncTreeTesterEvent _generateUserListen() {
    var query = random.nextQuerySpec();
    return SyncTreeTesterEvent.listen(query);
  }

  SyncTreeTesterEvent _generateUserUnlisten() {
    var query = userListens.keys.toList()[random.nextInt(userListens.length)];
    return SyncTreeTesterEvent.unlisten(query);
  }

  SyncTreeTesterEvent _generateUserOperation() {
    var operation = random.nextOperation();
    return SyncTreeTesterEvent.operation(operation);
  }

  SyncTreeTesterEvent? _handleOutstandingListen() {
    if (outstandingListens.isEmpty) return null;
    return SyncTreeTesterEvent.ackListen(outstandingListens.first.key);
  }

  SyncTreeTesterEvent? _handleOutstandingWrite() {
    if (outstandingWrites.isEmpty) return null;

    var op = outstandingWrites.first;
    var path = op.value.path;
    var isEmptyPriorityError = path.isNotEmpty &&
        path.last.isPriorityChildName &&
        _currentServerState.getChild(path.parent!).isEmpty;

    if (random.nextDouble() < revertProbability || isEmptyPriorityError) {
      return SyncTreeTesterEvent.revertWrite(op.value);
    } else {
      return SyncTreeTesterEvent.ackWrite(op.value);
    }
  }

  SyncTreeTesterEvent _generateServerOperation() {
    var op = random.nextOperation();
    return SyncTreeTesterEvent.serverOperation(op);
  }

  void next() {
    SyncTreeTesterEvent? event;
    if (random.nextDouble() < listenProbability) {
      event = _generateUserListen();
    } else if (unlistenProbability != 0 &&
        userListens.isNotEmpty &&
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
      applyEvent(event);
    }
  }

  void flush() {
    while (outstandingListens.isNotEmpty) {
      var event = _handleOutstandingListen();
      if (event == null) break;
      applyEvent(event);
      return;
    }
    while (outstandingWrites.isNotEmpty) {
      var event = _handleOutstandingWrite();
      if (event == null) break;
      applyEvent(event);
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
    var trackedQueries = storageEngine
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
      if (outstandingListens
          .map((v) => v.key)
          .any((q) => path.isDescendantOf(q.path) || path == q.path)) {
        return;
      }
      node.views.forEach((params, view) {
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

  HivePersistenceStorageEngine get storageEngine =>
      (syncTree.persistenceManager as DefaultPersistenceManager).storageLayer
          as HivePersistenceStorageEngine;

  void checkPersistedWrites() {
    expect(
        storageEngine.loadUserOperations(), Map.fromEntries(outstandingWrites));
  }

  void checkPersistedServerCache() {
    var v = storageEngine.database.loadServerCache().value;
    syncTree.root.forEachNode((path, node) {
      node.views.forEach((params, view) {
        if (view.data.localVersion.isComplete) {
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
    for (var w in outstandingWrites) {
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
        if (outstandingWrites
            .map((v) => v.value)
            .any((o) => o.path.isDescendantOf(path) || path == o.path)) return;

        if (view.data.localVersion.isComplete) {
          // complete data should match with value on server
          var serverValue = v.getChild(path).withFilter(params);
          var serverView = view.data.localVersion.value;
          if (serverValue != serverView) {
            throw StateError('SyncTree has an incorrect local version');
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
