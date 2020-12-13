import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

import '../treestructureddata.dart';

abstract class PersistenceManager {
  /// Save a user operation
  void saveUserOperation(TreeOperation operation, int writeId);

  /// Remove a user operation with the given write id.
  void removeUserOperation(int writeId);

  /// Overwrite the server cache with the given node for a given query. The query is considered to be
  /// complete after saving this node.
  void updateServerCache(TreeOperation operation, [QueryFilter filter]);

  void setQueryActive(Path<Name> path, QueryFilter filter);

  void setQueryInactive(Path<Name> path, QueryFilter filter);

  void setQueryComplete(Path<Name> path, QueryFilter filter);

  T runInTransaction<T>(T Function() callable);
}

class NoopPersistenceManager implements PersistenceManager {
  bool _insideTransaction = false;

  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    _verifyInsideTransaction();
  }

  @override
  void removeUserOperation(int writeId) {
    _verifyInsideTransaction();
  }

  @override
  void updateServerCache(TreeOperation operation, [QueryFilter filter]) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryActive(Path<Name> path, QueryFilter filter) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryInactive(Path<Name> path, QueryFilter filter) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryComplete(Path<Name> path, QueryFilter filter) {
    _verifyInsideTransaction();
  }

  @override
  T runInTransaction<T>(T Function() callable) {
    // We still track insideTransaction, so we can catch bugs.
    assert(!_insideTransaction,
        'runInTransaction called when an existing transaction is already in progress.');
    _insideTransaction = true;
    try {
      return callable();
    } finally {
      _insideTransaction = false;
    }
  }

  void _verifyInsideTransaction() {
    assert(
        _insideTransaction, 'Transaction expected to already be in progress.');
  }
}
