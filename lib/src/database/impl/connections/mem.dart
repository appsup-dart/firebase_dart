import 'package:firebase_dart/src/database/impl/data_observer.dart';

import '../connection.dart';
import 'dart:async';
import '../tree.dart';
import '../treestructureddata.dart';
import '../operations/tree.dart';
import '../synctree.dart';
import '../repo.dart';
import '../events/value.dart';
import '../../../database.dart' show FirebaseTokenCodec;

class _Registrar extends RemoteListenerRegistrar {
  @override
  Future<Null> remoteRegister(
      Path<Name> path, QueryFilter filter, String hash) async {
    // TODO: implement remoteRegister
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) async {
    // TODO: implement remoteUnregister
  }
}

class SingleInstanceBackend {
  static final SingleInstanceBackend _instance = SingleInstanceBackend();

  TreeStructuredData data = TreeStructuredData();
  final List<StreamController<TreeOperation>> controllers = [];

  Stream<TreeOperation> get _stream {
    var controller = StreamController<TreeOperation>();
    controllers.add(controller);
    controller.add(TreeOperation.overwrite(Name.parsePath(''), data));
    return controller.stream;
  }

  static Future<Null> _applyOnInstance(TreeOperation operation) =>
      _instance._apply(operation);

  static Stream<TreeOperation> get stream async* {
    yield* _instance._stream;
  }

  /// Generates the special server values
  Map<ServerValue, Value> get _serverValues =>
      {ServerValue.timestamp: Value(DateTime.now().millisecondsSinceEpoch)};

  Future<Null> _apply(TreeOperation operation) async {
    operation = _resolveTreeOperation(operation, _serverValues);
    data = operation.apply(data);
    for (var c in controllers) {
      c.add(operation);
    }
    await Future.microtask(() => null);
  }

  Operation _resolveNodeOperation(
      Operation operation, Map<ServerValue, Value> serverValues) {
    if (operation is Overwrite) {
      return Overwrite(ServerValue.resolve(operation.value, serverValues));
    }
    if (operation is Merge) {
      return Merge(Map.fromIterables(
          operation.overwrites.map((o) => o.path),
          operation.overwrites.map((o) => ServerValue.resolve(
              (o.nodeOperation as Overwrite).value, serverValues))));
    }
    return operation;
  }

  TreeOperation _resolveTreeOperation(
      TreeOperation operation, Map<ServerValue, Value> serverValues) {
    var nodeOperation =
        _resolveNodeOperation(operation.nodeOperation, serverValues);
    if (nodeOperation == operation.nodeOperation) return operation;
    return TreeOperation(operation.path, nodeOperation);
  }

  static Future apply(TreeOperation operation) => _applyOnInstance(operation);
}

class MemConnection extends Connection {
  MemConnection(String host)
      : syncTree = SyncTree('', _Registrar()),
        super.base(host) {
    SingleInstanceBackend.stream.listen((op) {
      syncTree.applyServerOperation(op, null);
    });
    _onConnectController.add(true);
    syncTree.root.value.isCompleteFromParent = true;
  }

  final SyncTree syncTree;

  @override
  Future<Null> close() {
    _onAuth.close();
    _onDataOperation.close();
    _onConnectController.close();
    return Future.value();
  }

  @override
  Future<Null> disconnect() async {
    _onConnectController.add(false);
    _runOnDisconnectEvents();
    _onConnectController.add(true);
  }

  final SparseSnapshotTree _onDisconnect = SparseSnapshotTree();

  void _runOnDisconnectEvents() {
    var sv = serverValues;
    _onDisconnect.forEachNode((path, snap) {
      if (snap == null) return;
      syncTree.applyServerOperation(
          TreeOperation.overwrite(path, ServerValue.resolve(snap, sv)), null);
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  @override
  Future<Iterable<String>> listen(String path,
      {QueryFilter query, String hash}) async {
    var p = Name.parsePath(path);
    await syncTree.addEventListener('value', p, query, (event) {
      if (event is ValueEvent) {
        var operation = OperationEvent(
            OperationEventType.overwrite,
            p,
            ServerValue.resolve(event.value, serverValues).toJson(true),
            query.limits ? query : null);
        _onDataOperation.add(operation);
      }
    });

    return [];
  }

  @override
  Future<Null> unlisten(String path, {QueryFilter query}) async {
    var p = Name.parsePath(path);
    await syncTree.removeEventListener('value', p, query, null);
  }

  @override
  Future<Null> merge(String path, Map<String, dynamic> value,
      {String hash, int writeId}) async {
    var p = Name.parsePath(path);
    // TODO check hash
    syncTree.applyServerOperation(
        TreeOperation.merge(
            p,
            Map.fromIterables(value.keys.map((k) => Name.parsePath(k)),
                value.values.map((v) => TreeStructuredData.fromJson(v)))),
        null);
  }

  @override
  Future<Null> put(String path, dynamic value,
      {String hash, int writeId}) async {
    var p = Name.parsePath(path);

    await SingleInstanceBackend.apply(
        TreeOperation.overwrite(p, TreeStructuredData.fromJson(value)));
    // TODO check hash
  }

  final StreamController<bool> _onConnectController = StreamController();

  @override
  Stream<bool> get onConnect => _onConnectController.stream;

  @override
  Future<Null> onDisconnectCancel(String path) async {
    _onDisconnect.forget(Name.parsePath(path));
  }

  @override
  Future<Null> onDisconnectMerge(
      String path, Map<String, dynamic> childrenToMerge) async {
    childrenToMerge.forEach((childName, child) {
      _onDisconnect.remember(Name.parsePath(path).child(Name(childName)),
          TreeStructuredData.fromJson(child));
    });
  }

  @override
  Future<Null> onDisconnectPut(String path, dynamic value) async {
    _onDisconnect.remember(
        Name.parsePath(path), TreeStructuredData.fromJson(value));
  }

  @override
  DateTime get serverTime => DateTime.now();

  @override
  Future<Map> auth(FutureOr<String> token) async {
    var t = FirebaseTokenCodec(null).decode(token);
    return t.data;
  }

  @override
  Future<Null> unauth() async {}

  final StreamController<Map> _onAuth = StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation =
      StreamController(sync: true);

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;
}
