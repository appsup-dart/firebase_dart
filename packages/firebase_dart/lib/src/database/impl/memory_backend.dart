import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/database/impl/backend_connection/rules.dart';
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/event.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:stream_channel/stream_channel.dart';

import 'backend_connection.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

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
        try {
          var implementation = FirebaseImplementation.installation;
          if (implementation is IsolateFirebaseImplementation) {
            return IsolateMemoryBackend(implementation.commander, namespace);
          }
        } on FirebaseCoreException catch (e) {
          if (e.code != FirebaseCoreException.noSetup().code) {
            rethrow;
          }
        }
        return MemoryBackend();
      });

  static StreamChannel<Message> connect(Uri url) {
    var namespace = url.queryParameters['ns'] ?? url.host.split('.').first;

    var backend = getInstance(namespace);

    var connection = BackendConnection(backend, url.host)..open();

    return connection.transport!.foreignChannel;
  }
}

class IsolateMemoryBackend implements MemoryBackend {
  final Future<IsolateCommander> commander;
  final String namespace;

  IsolateMemoryBackend(this.commander, this.namespace);

  @override
  Future<void> auth(Auth? auth) {
    throw UnimplementedError();
  }

  @override
  Auth? get currentAuth => throw UnimplementedError();

  @override
  Future<List<String>> listen(String path, EventListener listener,
      {QueryFilter query = const QueryFilter(), String? hash}) {
    throw UnimplementedError();
  }

  @override
  Future<void> merge(String path, Map<String, dynamic> children) {
    throw UnimplementedError();
  }

  @override
  Future<void> put(String path, value, {String? hash}) {
    throw UnimplementedError();
  }

  @override
  set securityRules(Map<String, dynamic> rules) {
    commander.then((c) {
      c.execute(StaticFunctionCall(setSecurityRules, [namespace, rules]));
    });
  }

  @override
  SecurityTree get securityTree => throw UnimplementedError();

  @override
  Future<void> unlisten(String path, EventListener? listener,
      {QueryFilter query = const QueryFilter()}) {
    throw UnimplementedError();
  }

  @override
  Backend get unsecuredBackend => throw UnimplementedError();

  static void setSecurityRules(String namespace, Map<String, dynamic> rules) {
    var backend = MemoryBackend.getInstance(namespace);
    backend.securityRules = rules;
  }
}
