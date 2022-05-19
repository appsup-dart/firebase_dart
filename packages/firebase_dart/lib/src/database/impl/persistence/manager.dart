import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
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
  IncompleteData serverCache(QuerySpec query);

  /// Overwrite the server cache with the given node for a given query.
  ///
  /// The query is considered to be complete after saving this node.
  void updateServerCache(QuerySpec query, TreeOperation operation);

  void setQueryActive(QuerySpec query);

  void setQueryInactive(QuerySpec query);

  void setQueryComplete(QuerySpec query);

  T runInTransaction<T>(T Function() callable);

  Future<void> close();
}

class FakePersistenceManager extends NoopPersistenceManager {
  final IncompleteData Function(Path<Name> path, QueryFilter filter)
      serverCacheFunction;

  FakePersistenceManager(this.serverCacheFunction);

  @override
  IncompleteData serverCache(QuerySpec query) {
    return serverCacheFunction(query.path, query.params);
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
  IncompleteData serverCache(QuerySpec query) {
    return IncompleteData.empty(query.params);
  }

  @override
  void updateServerCache(QuerySpec query, TreeOperation operation) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryActive(QuerySpec query) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryInactive(QuerySpec query) {
    _verifyInsideTransaction();
  }

  @override
  void setQueryComplete(QuerySpec query) {
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

  @override
  Future<void> close() async {}
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
  IncompleteData serverCache(QuerySpec query) {
    return delegateTo.serverCache(query);
  }

  @override
  void setQueryActive(QuerySpec query) {
    return delegateTo.setQueryActive(query);
  }

  @override
  void setQueryComplete(QuerySpec query) {
    return delegateTo.setQueryComplete(query);
  }

  @override
  void setQueryInactive(QuerySpec query) {
    return delegateTo.setQueryInactive(query);
  }

  @override
  void updateServerCache(QuerySpec query, TreeOperation operation) {
    return delegateTo.updateServerCache(query, operation);
  }

  @override
  Future<void> close() {
    return delegateTo.close();
  }
}
