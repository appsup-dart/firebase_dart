import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/implementation/isolate/database.dart';
import 'package:meta/meta.dart';

import '../../database.dart';

@visibleForTesting
abstract class FirebaseDatabaseTestingController {
  factory FirebaseDatabaseTestingController(FirebaseDatabase db) {
    if (db is FirebaseDatabaseImpl) {
      return FirebaseDatabaseImplTestingController(db);
    } else if (db is IsolateFirebaseDatabase) {
      return FirebaseDatabaseIsolateTestingController(db);
    }
    throw UnsupportedError(
        'Cannot create FirebaseDatabaseTestingController from $db');
  }

  void mockConnectionLost();

  void mockResetMessage();

  Future<void> triggerDisconnect();

  Future<void> authenticate(String token);
  Future<void> unauth();

  Stream<Map<String, dynamic>?> get onAuth;

  Map<String, dynamic>? get auth;
}

@visibleForTesting
class FirebaseDatabaseIsolateTestingController
    implements FirebaseDatabaseTestingController {
  final IsolateFirebaseDatabase db;

  FirebaseDatabaseIsolateTestingController(this.db);

  @override
  void mockConnectionLost() => db.mockConnectionLost();

  @override
  void mockResetMessage() => db.mockResetMessage();

  @override
  Future<void> authenticate(String token) => db.auth(token);

  @override
  Future<void> unauth() => db.unauth();

  @override
  Stream<Map<String, dynamic>?> get onAuth => db.onAuth;

  @override
  Map<String, dynamic>? get auth => db.currentAuthData;

  @override
  Future<void> triggerDisconnect() => db.triggerDisconnect();
}

@visibleForTesting
class FirebaseDatabaseImplTestingController
    implements FirebaseDatabaseTestingController {
  final Repo repo;

  FirebaseDatabaseImplTestingController(FirebaseDatabaseImpl db)
      : repo = Repo(db);

  @override
  void mockConnectionLost() => repo.mockConnectionLost();
  @override
  void mockResetMessage() => repo.mockResetMessage();

  @override
  Future<void> authenticate(String token) => repo.auth(token);
  @override
  Future<void> unauth() => repo.unauth();

  @override
  Stream<Map<String, dynamic>?> get onAuth => repo.onAuth;

  @override
  Map<String, dynamic>? get auth => repo.authData;

  @override
  Future<void> triggerDisconnect() => repo.triggerDisconnect();
}

@visibleForTesting
extension FirebaseDatabaseTestingX on FirebaseDatabase {
  FirebaseDatabaseTestingController get _controller =>
      FirebaseDatabaseTestingController(this);

  void mockConnectionLost() => _controller.mockConnectionLost();

  void mockResetMessage() => _controller.mockResetMessage();

  Future<void> triggerDisconnect() => _controller.triggerDisconnect();
}

@visibleForTesting
extension QueryTestingX on Query {
  FirebaseDatabase get database => this is QueryImpl
      ? (this as QueryImpl).db
      : (this as IsolateQuery).database;
}

@visibleForTesting
extension LegacyAuthExtension on DatabaseReference {
  FirebaseDatabaseTestingController get _controller =>
      FirebaseDatabaseTestingController(database);

  Future<void> authWithCustomToken(String token) =>
      _controller.authenticate(token);

  Stream<Map<String, dynamic>?> get onAuth => _controller.onAuth;

  Future<void> unauth() => _controller.unauth();

  Map<String, dynamic>? get auth => _controller.auth;
}
