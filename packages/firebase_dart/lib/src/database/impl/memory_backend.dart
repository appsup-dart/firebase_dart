import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:stream_channel/stream_channel.dart';

import 'backend_connection.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

import 'memory_backend_non_isolate.dart'
    if (dart.library.isolate) 'package:firebase_dart/src/database/impl/memory_backend_isolate.dart';

class UnsecuredMemoryBackend extends SyncTreeBackend {
  UnsecuredMemoryBackend()
      : super(SyncTree('')
          ..root.value.parentState = QueryRegistrationState.registered
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
      _instances.putIfAbsent(namespace, () {
        return createMemoryBackend(namespace);
      });

  static StreamChannel<Message> connect(Uri url) {
    var namespace = url.queryParameters['ns'] ?? url.host.split('.').first;

    var backend = getInstance(namespace);

    var connection = BackendConnection(backend, url.host)..open();

    return connection.transport!.foreignChannel;
  }
}
