import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/implementation/isolate/database.dart';
import 'package:meta/meta.dart';

import '../../database.dart';

@visibleForTesting
abstract class FirebaseDatabaseTestingController {
  factory FirebaseDatabaseTestingController(FirebaseDatabase db) {
    if (db is BaseFirebaseDatabase) {
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
  Future<void> triggerDisconnect() => db.triggerDisconnect();
}

@visibleForTesting
class FirebaseDatabaseImplTestingController
    implements FirebaseDatabaseTestingController {
  final Repo repo;

  FirebaseDatabaseImplTestingController(BaseFirebaseDatabase db)
      : repo = Repo(db);

  @override
  void mockConnectionLost() => repo.mockConnectionLost();
  @override
  void mockResetMessage() => repo.mockResetMessage();

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
