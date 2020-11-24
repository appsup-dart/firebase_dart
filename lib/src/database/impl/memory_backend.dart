import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:stream_channel/stream_channel.dart';

import 'backend_connection.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

class UnsecuredMemoryBackend extends SyncTreeBackend {
  UnsecuredMemoryBackend()
      : super(SyncTree('', _MemRegistrar())
          ..root.value.isCompleteFromParent = true
          ..addEventListener('value', Path.from([]), QueryFilter(), (event) {})
          ..applyServerOperation(
              TreeOperation.overwrite(
                  Path.from([]), TreeStructuredData.fromJson(null)),
              null));
}

class MemoryBackend extends SecuredBackend {
  static final Map<String, MemoryBackend> _instances = {};

  MemoryBackend() : super.from(UnsecuredMemoryBackend());

  static MemoryBackend getInstance(String namespace) =>
      _instances.putIfAbsent(namespace, () => MemoryBackend());

  static StreamChannel<Message> connect(Uri url) {
    var namespace = url.queryParameters['ns'] ?? url.host.split('.').first;

    var backend = getInstance(namespace);

    var connection = BackendConnection(backend, url.host)..open();

    return connection.transport.foreignChannel;
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
