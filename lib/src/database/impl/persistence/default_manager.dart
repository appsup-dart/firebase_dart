import 'engine.dart';
import 'manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';

class DefaultPersistenceManager implements PersistenceManager {
  final PersistenceStorageEngine storageLayer;
  final CachePolicy cachePolicy;

  DefaultPersistenceManager(this.storageLayer, this.cachePolicy);

  /// Save a user overwrite
  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    storageLayer.saveUserOperation(operation, writeId);
  }

  /// Remove a write with the given write id.
  @override
  void removeUserOperation(int writeId) {
    storageLayer.removeUserOperation(writeId);
  }

  @override
  T runInTransaction<T>(T Function() callable) {
    storageLayer.beginTransaction();
    try {
      var result = callable();
      storageLayer.setTransactionSuccessful();
      return result;
    } finally {
      storageLayer.endTransaction();
    }
  }
}
