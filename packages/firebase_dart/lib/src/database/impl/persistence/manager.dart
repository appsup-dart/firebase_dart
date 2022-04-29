import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';

import '../data_observer.dart';
import '../treestructureddata.dart';

abstract class PersistenceManager {
  /// Save a user operation
  void saveUserOperation(TreeOperation operation, int writeId);

  /// Remove a user operation with the given write id.
  void removeUserOperation(int writeId);

  /// Returns any cached node or children as a [IncompleteData].
  ///
  /// The query is *not* used to filter the node but rather to determine if it
  /// can be considered complete.
  IncompleteData serverCache(Path<Name> path,
      [QueryFilter filter = const QueryFilter()]);

  /// Overwrite the server cache with the given node for a given query.
  ///
  /// The query is considered to be complete after saving this node.
  void updateServerCache(TreeOperation operation, [QueryFilter? filter]);

  void setQueryActive(Path<Name> path, QueryFilter filter);

  void setQueryInactive(Path<Name> path, QueryFilter filter);

  void setQueryComplete(Path<Name> path, QueryFilter filter);

  T runInTransaction<T>(T Function() callable);
}

class FakePersistenceManager extends NoopPersistenceManager {
  final IncompleteData Function(Path<Name> path, QueryFilter filter)
      serverCacheFunction;

  FakePersistenceManager(this.serverCacheFunction);

  @override
  IncompleteData serverCache(Path<Name> path,
      [QueryFilter filter = const QueryFilter()]) {
    return serverCacheFunction(path, filter);
  }
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
  IncompleteData serverCache(Path<Name> path,
      [QueryFilter filter = const QueryFilter()]) {
    return IncompleteData.empty(filter);
  }

  @override
  void updateServerCache(TreeOperation operation, [QueryFilter? filter]) {
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

class DelegatingPersistenceManager implements PersistenceManager {
  final PersistenceManager Function() factory;

  DelegatingPersistenceManager(this.factory);

  late PersistenceManager delegateTo = factory();

  @override
  void removeUserOperation(int writeId) {
    delegateTo.removeUserOperation(writeId);
  }

  @override
  T runInTransaction<T>(T Function() callable) {
    return delegateTo.runInTransaction(callable);
  }

  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    return delegateTo.saveUserOperation(operation, writeId);
  }

  @override
  IncompleteData serverCache(Path<Name> path,
      [QueryFilter filter = const QueryFilter()]) {
    return delegateTo.serverCache(path, filter);
  }

  @override
  void setQueryActive(Path<Name> path, QueryFilter filter) {
    return delegateTo.setQueryActive(path, filter);
  }

  @override
  void setQueryComplete(Path<Name> path, QueryFilter filter) {
    return delegateTo.setQueryComplete(path, filter);
  }

  @override
  void setQueryInactive(Path<Name> path, QueryFilter filter) {
    return delegateTo.setQueryInactive(path, filter);
  }

  @override
  void updateServerCache(TreeOperation operation, [QueryFilter? filter]) {
    return delegateTo.updateServerCache(operation, filter);
  }
}
