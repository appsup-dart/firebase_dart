
import '../connection.dart';
import 'dart:async';
import '../tree.dart';
import '../treestructureddata.dart';
import '../operations/tree.dart';
import '../synctree.dart';
import '../repo.dart';
import '../events/value.dart';
import '../firebase.dart' show FirebaseTokenCodec;
import 'package:logging/logging.dart';
import 'package:isolate/isolate.dart';
import 'dart:isolate';
import '../isolate_runner.dart';

final _logger = new Logger("firebase-mem");



class _Registrar extends RemoteListenerRegistrar {

  @override
  Future<Null> remoteRegister(Path<Name> path, QueryFilter filter, String hash) async {
    // TODO: implement remoteRegister
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) async {
    // TODO: implement remoteUnregister
  }
}


class BackendOperation {
  final String path;
  final bool isMerge;
  final dynamic data;

  BackendOperation.overwrite(this.path, this.data) : isMerge = false;
  BackendOperation.merge(this.path, this.data) : isMerge = true;

  factory BackendOperation.fromTreeOperation(TreeOperation op) {
    var path = op.path.join("/");
    var nop = op.nodeOperation;
    if (nop is Overwrite) {
      return new BackendOperation.overwrite(path, nop.value.toJson(true));
    } else if (nop is Merge) {
      return new BackendOperation.merge(path, new TreeStructuredData.nonLeaf(nop.children).toJson(true));
    } else if (nop is SetPriority) {
      return new BackendOperation.overwrite("$path/.priority", nop.value);
    }
    throw new ArgumentError.value(op);
  }

  TreeOperation toTreeOperation() => isMerge ?
  new TreeOperation.merge(Name.parsePath(path),new TreeStructuredData.fromJson(data).children) :
  new TreeOperation.overwrite(Name.parsePath(path), new TreeStructuredData.fromJson(data));
}

class SingleInstanceBackend {

  static final SingleInstanceBackend _instance = new SingleInstanceBackend();

  TreeStructuredData data = new TreeStructuredData();
  final List<StreamController<BackendOperation>> controllers = [];



  Stream<BackendOperation> get _stream {
    var controller = new StreamController<BackendOperation>();
    controllers.add(controller);
    controller.add(new BackendOperation.overwrite("",null));
    return controller.stream;
  }

  static void _createStream(SendPort sendPort) {
    _instance._stream.forEach((v)=>sendPort.send(v));
  }

  static Future<Null> _applyOnInstance(BackendOperation operation) => _instance._apply(operation);

  static Stream<TreeOperation> get stream async* {
    var r = new ReceivePort();
    await _runner.run(SingleInstanceBackend._createStream,r.sendPort);
    yield* r.map((o)=>o.toTreeOperation());
  }


  Future<Null> _apply(BackendOperation operation) async {
    data = operation.toTreeOperation().apply(data);
    for (var c in controllers) {
      c.add(operation);
    }
    await new Future.delayed(new Duration(milliseconds: 1000));
  }

  static Future<Null> apply(TreeOperation operation) =>
      _runner.run(_applyOnInstance,new BackendOperation.fromTreeOperation(operation));


  static Runner get _runner {
    return Runners.mainRunner;
  }


}



class MemConnection extends Connection {


  MemConnection(String host) : syncTree = new SyncTree("", new _Registrar()), super.base(host) {
    SingleInstanceBackend.stream.listen((op) {
      _logger.fine("operation from backend $op");
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
      syncTree.applyServerOperation(new TreeOperation.overwrite(path, ServerValue.resolve(snap,sv)), null);
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  @override
  Future<Iterable<String>> listen(String path, {QueryFilter query, String hash}) async {
    _logger.fine("listen $path $query");
    var p = Name.parsePath(path);
    await syncTree.addEventListener("value",p, query, (event) {
      if (event is ValueEvent) {
        var operation = new OperationEvent(OperationEventType.overwrite, p,
            ServerValue.resolve(event.value, serverValues), query.limits ? query : null);
        _logger.fine("operation $path ${operation.query} $query ${operation.type} ${operation.data}");
        _onDataOperation.add(operation);
      }
    });

    return [];
  }

  @override
  Future<Null> unlisten(String path, {QueryFilter query}) async {
    var p = Name.parsePath(path);
    await syncTree.removeEventListener("value",p,query,null);
  }


  @override
  Future<Null> merge(String path, value, {String hash, int writeId}) async {
    _logger.fine("merge $path $value");
    var p = Name.parsePath(path);
    // TODO check hash
    syncTree.applyServerOperation(new TreeOperation.merge(p, new TreeStructuredData.fromJson(value).children), null);
  }

  @override
  Future<Null> put(String path, value, {String hash, int writeId}) async {
    _logger.fine("put $path $value");
    var p = Name.parsePath(path);

    await SingleInstanceBackend.apply(new TreeOperation.overwrite(p, new TreeStructuredData.fromJson(value)));
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
  Future<Null> onDisconnectMerge(String path, Map<String, dynamic> childrenToMerge) async {
    childrenToMerge.forEach((childName, child) {
      _onDisconnect.remember(Name.parsePath(path).child(new Name(childName)),
          new TreeStructuredData.fromJson(child));
    });
  }

  @override
  Future<Null> onDisconnectPut(String path, value) async {
    _onDisconnect.remember(Name.parsePath(path), new TreeStructuredData.fromJson(value));
  }


  @override
  DateTime get serverTime => new DateTime.now();

  bool _isAuthenticated = false;

  @override
  Future<Map> auth(String token) async {
    _isAuthenticated = true;
    var t = new FirebaseTokenCodec(null).decode(token);
    return t.data;
  }


  @override
  Future<Null> unauth() async {
    _isAuthenticated = false;
  }

  final StreamController<Map> _onAuth = new StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation = new StreamController(sync: true);

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;
}

