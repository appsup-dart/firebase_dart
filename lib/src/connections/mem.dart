
import '../connection.dart';
import 'dart:async';
import '../tree.dart';
import '../treestructureddata.dart';
import '../event.dart';
import '../operations/tree.dart';
import '../synctree.dart';
import '../repo.dart';
import '../events/value.dart';
import '../view.dart';
import '../data_observer.dart';
import '../firebase.dart' show FirebaseTokenCodec;
import 'package:logging/logging.dart';

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

class MemConnection extends Connection {

  MemConnection(String host) : super.base(host) {
    _onConnectController.add(true);
    syncTree.root.value.isCompleteFromParent = true;
    syncTree.applyServerOperation(new TreeOperation.overwrite(new Path(), new TreeStructuredData()), null);
    _logger.finer("${syncTree.root.value.views.values.first.data.localVersion}");
  }

  bool _isClosed = false;

  final SyncTree syncTree = new SyncTree(new _Registrar());

  @override
  Future<Null> close() {
    _isClosed = true;
    return new Future.value();
  }

  @override
  Future<Null> disconnect() {
    // TODO: implement disconnect
  }

  @override
  Future<Iterable<String>> listen(String path, {QueryFilter query, int tag, String hash}) async {
    var p = Name.parsePath(path);
    _logger.finer("listen $p");
    await syncTree.addEventListener("value",p, query, (event) {
      _logger.finer("listener $event ${event}");
      if (event is ValueEvent) {
        _logger.finer("listener $event ${event.value}");
        _onDataOperation.add(new OperationEvent(OperationEventType.overwrite, p,
        new TreeStructuredData.fromJson(event.value), query));
      }
    });

    return [];
  }

  @override
  Future<Null> unlisten(String path, {QueryFilter query, int tag}) {
    var p = Name.parsePath(path);
//    syncTree.removeEventListener("value",p,new QueryFilter.fromQuery(query));
  }


  @override
  Future<Null> merge(String path, value, {String hash, int writeId}) async {
    var p = Name.parsePath(path);
    // TODO check hash
    syncTree.applyUserMerge(p, new TreeStructuredData.fromJson(value).children /*TODO resolve sv*/, writeId);
  }

  @override
  Future<Null> put(String path, value, {String hash, int writeId}) async {

    var p = Name.parsePath(path);
    _logger.finer("put $p $value");
    // TODO check hash
    syncTree.applyServerOperation(new TreeOperation.overwrite(p, new TreeStructuredData.fromJson(value)), null);

    _logger.finer(syncTree.root.value.valueForFilter(new QueryFilter()));
  }

  final StreamController<bool> _onConnectController = new StreamController();

  @override
  Stream<bool> get onConnect => _onConnectController.stream;


  @override
  Future<Null> onDisconnectCancel(String path) {
    // TODO: implement onDisconnectCancel
  }

  @override
  Future<Null> onDisconnectMerge(String path, Map<String, dynamic> childrenToMerge) {
    // TODO: implement onDisconnectMerge
  }

  @override
  Future<Null> onDisconnectPut(String path, value) {
    // TODO: implement onDisconnectPut
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

  final StreamController<Map> _onAuth = new StreamController();
  final StreamController<OperationEvent> _onDataOperation = new StreamController();

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;
}

