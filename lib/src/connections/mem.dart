import '../connection.dart';
import 'dart:async';
import '../tree.dart';
import '../treestructureddata.dart';
import '../operations/tree.dart';
import '../synctree.dart';
import '../repo.dart';
import '../events/value.dart';
import '../firebase.dart' show FirebaseTokenCodec;

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
  static final SingleInstanceBackend _instance = new SingleInstanceBackend();

  TreeStructuredData data = new TreeStructuredData();
  final List<StreamController<TreeOperation>> controllers = [];

  Stream<TreeOperation> get _stream {
    var controller = new StreamController<TreeOperation>();
    controllers.add(controller);
    controller.add(new TreeOperation.overwrite(Name.parsePath(""), data));
    return controller.stream;
  }

  static Future<Null> _applyOnInstance(TreeOperation operation) =>
      _instance._apply(operation);

  static Stream<TreeOperation> get stream async* {
    yield* _instance._stream;
  }

  Future<Null> _apply(TreeOperation operation) async {
    data = operation.apply(data);
    for (var c in controllers) {
      c.add(operation);
    }
    await new Future.microtask(() => null);
  }

  static Future apply(TreeOperation operation) =>
      _applyOnInstance(operation);

}

class MemConnection extends Connection {
  MemConnection(String host)
      : syncTree = new SyncTree("", new _Registrar()),
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
    return new Future.value();
  }

  @override
  Future<Null> disconnect() async {
    _onConnectController.add(false);
    _runOnDisconnectEvents();
    _onConnectController.add(true);
  }

  SparseSnapshotTree _onDisconnect = new SparseSnapshotTree();

  void _runOnDisconnectEvents() {
    var sv = serverValues;
    _onDisconnect.forEachNode((path, snap) {
      if (snap == null) return;
      syncTree.applyServerOperation(
          new TreeOperation.overwrite(path, ServerValue.resolve(snap, sv)),
          null);
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  @override
  Future<Iterable<String>> listen(String path,
      {QueryFilter query, String hash}) async {
    var p = Name.parsePath(path);
    await syncTree.addEventListener("value", p, query, (event) {
      if (event is ValueEvent) {
        print(event.value);
        print(ServerValue.resolve(event.value, serverValues).toJson(true));
        print(ServerValue.resolve(event.value, serverValues).toJson(false));

        var operation = new OperationEvent(
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
    await syncTree.removeEventListener("value", p, query, null);
  }

  @override
  Future<Null> merge(String path, Map<String,dynamic> value,
      {String hash, int writeId}) async {
    var p = Name.parsePath(path);
    // TODO check hash
    syncTree.applyServerOperation(
        new TreeOperation.merge(
            p, new Map.fromIterables(
            value.keys.map((k)=>Name.parsePath(k)),
            value.values.map((v)=>new TreeStructuredData.fromJson(v))
        )),
        null);
  }

  @override
  Future<Null> put(String path, dynamic value,
      {String hash, int writeId}) async {
    var p = Name.parsePath(path);

    await SingleInstanceBackend.apply(
        new TreeOperation.overwrite(p, new TreeStructuredData.fromJson(value)));
    // TODO check hash
  }

  final StreamController<bool> _onConnectController = new StreamController();

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
      _onDisconnect.remember(Name.parsePath(path).child(new Name(childName)),
          new TreeStructuredData.fromJson(child));
    });
  }

  @override
  Future<Null> onDisconnectPut(String path, dynamic value) async {
    _onDisconnect.remember(
        Name.parsePath(path), new TreeStructuredData.fromJson(value));
  }

  @override
  DateTime get serverTime => new DateTime.now();

  @override
  Future<Map> auth(String token) async {
    var t = new FirebaseTokenCodec(null).decode(token);
    return t.data;
  }

  @override
  Future<Null> unauth() async {}

  final StreamController<Map> _onAuth = new StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation =
      new StreamController(sync: true);

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;
}
