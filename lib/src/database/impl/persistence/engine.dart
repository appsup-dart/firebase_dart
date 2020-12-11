import 'package:firebase_dart/src/database/impl/operations/tree.dart';

/// This class provides an interface to a persistent cache.
///
/// The persistence cache persists user writes, cached server data and the
/// corresponding completeness tree.
///
/// There exists one PersistentCache per repo.
abstract class PersistenceStorageEngine {
  /// Save a user operation
  void saveUserOperation(TreeOperation operation, int writeId);

  /// Remove a write with the given write id.
  void removeUserOperation(int writeId);

  void beginTransaction();

  void endTransaction();

  void setTransactionSuccessful();
}
