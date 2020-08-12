import 'package:firebase_dart/database.dart' show FirebaseDatabaseException;
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:stream_channel/stream_channel.dart';

import 'backend_connection.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'event.dart';

class MemoryBackend extends Backend {
  static final Map<String, MemoryBackend> _instances = {};

  final SyncTree syncTree = SyncTree('', _MemRegistrar())
    ..root.value.isCompleteFromParent = true
    ..addEventListener('value', Path.from([]), QueryFilter(), (event) {})
    ..applyServerOperation(
        TreeOperation.overwrite(
            Path.from([]), TreeStructuredData.fromJson(null)),
        null);

  static StreamChannel<Message> connect(Uri url) {
    var namespace = url.queryParameters['ns'] ?? url.host.split('.').first;

    var backend = _instances.putIfAbsent(namespace, () => MemoryBackend());

    var connection = BackendConnection(backend, url.host)..open();

    return connection.transport.foreignChannel;
  }

  @override
  Future<void> listen(String path, EventListener listener,
      {Query query, String hash}) async {
    await syncTree.addEventListener(
        'value', Name.parsePath(path), query.toFilter(), listener);
  }

  @override
  Future<void> unlisten(String path, EventListener listener,
      {Query query}) async {
    await syncTree.removeEventListener(
        'value', Name.parsePath(path), query.toFilter(), listener);
  }

  @override
  Future<void> put(String path, value, {String hash}) async {
    var serverValues = {
      ServerValue.timestamp: Value(DateTime.now().millisecondsSinceEpoch)
    };
    var p = Name.parsePath(path);
    if (hash != null) {
      var current = getLatestValue(syncTree, p);
      if (hash != current.hash) {
        throw FirebaseDatabaseException.dataStale();
      }
    }
    syncTree.applyServerOperation(
        TreeOperation.overwrite(
            p,
            ServerValue.resolve(
                TreeStructuredData.fromJson(value), serverValues)),
        null);
  }

  @override
  Future<void> merge(String path, Map<String, dynamic> children) async {
    var serverValues = {
      ServerValue.timestamp: Value(DateTime.now().millisecondsSinceEpoch)
    };
    syncTree.applyServerOperation(
        TreeOperation.merge(
            Name.parsePath(path),
            children.map((k, v) => MapEntry(
                Name.parsePath(k),
                ServerValue.resolve(
                    TreeStructuredData.fromJson(v), serverValues)))),
        null);
  }
}

class _MemRegistrar extends RemoteListenerRegistrar {
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
