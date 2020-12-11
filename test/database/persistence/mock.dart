import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';

class MockPersistenceStorageEngine implements PersistenceStorageEngine {
  final Map<int, TreeOperation> writes = {};

  bool _insideTransaction = false;

  // Minor hack for testing purposes.
  bool disableTransactionCheck = false;

  @override
  void beginTransaction() {
    assert(!_insideTransaction,
        'runInTransaction called when an existing transaction is already in progress.');
    _insideTransaction = true;
  }

  void _verifyInsideTransaction() {
    assert(disableTransactionCheck || _insideTransaction,
        'Transaction expected to already be in progress.');
  }

  @override
  void endTransaction() {
    _insideTransaction = false;
  }

  @override
  void removeUserOperation(int writeId) {
    _verifyInsideTransaction();
    assert(writes.containsKey(writeId),
        "Tried to remove write that doesn't exist.");
    writes.remove(writeId);
  }

  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    _verifyInsideTransaction();
    writes[writeId] = operation;
  }

  @override
  void setTransactionSuccessful() {}
}

class TestCachePolicy implements CachePolicy {
  bool _timeToPrune = false;
  final double _percentToPruneAtOnce;
  final int _maxNumberToKeep;

  TestCachePolicy(this._percentToPruneAtOnce,
      [this._maxNumberToKeep = 1 << 31]);

  void pruneOnNextServerUpdate() {
    _timeToPrune = true;
  }

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) {
    if (_timeToPrune) {
      _timeToPrune = false;
      return true;
    } else {
      return false;
    }
  }

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) {
    return true;
  }

  @override
  double getPercentOfQueriesToPruneAtOnce() {
    return _percentToPruneAtOnce;
  }

  @override
  int getMaxNumberOfQueriesToKeep() {
    return _maxNumberToKeep;
  }
}
