import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/database/impl/backend_connection/rules.dart';
import 'package:firebase_dart/src/database/impl/event.dart';
import 'package:firebase_dart/src/database/impl/memory_backend.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';

import 'backend_connection.dart';

MemoryBackend createMemoryBackend(String namespace) {
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
