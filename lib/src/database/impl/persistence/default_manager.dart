import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:logging/logging.dart';

import '../query_spec.dart';
import '../treestructureddata.dart';
import 'engine.dart';
import 'manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';

final _logger = Logger('firebase.persistence');

class DefaultPersistenceManager implements PersistenceManager {
  final PersistenceStorageEngine storageLayer;
  final TrackedQueryManager _trackedQueryManager;
  final CachePolicy cachePolicy;
  int _serverCacheUpdatesSinceLastPruneCheck = 0;

  DefaultPersistenceManager(this.storageLayer, this.cachePolicy)
      : _trackedQueryManager = TrackedQueryManager(storageLayer);

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
  void updateServerCache(TreeOperation operation, [QueryFilter filter]) {
    filter ??= QueryFilter();
    if (filter.limits) {
      var o = operation.nodeOperation;
      if (o is Overwrite) {
        operation = TreeOperation.merge(operation.path,
            o.value.children.map((k, v) => MapEntry(Path.from([k]), v)));
      }
    }
    storageLayer.overwriteServerCache(operation);
    setQueryComplete(operation.path, filter);
    _doPruneCheckAfterServerUpdate();
  }

  @override
  void setQueryActive(Path<Name> path, QueryFilter filter) {
    _trackedQueryManager.setQueryActive(QuerySpec(path, filter));
  }

  @override
  void setQueryInactive(Path<Name> path, QueryFilter filter) {
    _trackedQueryManager.setQueryInactive(QuerySpec(path, filter));
  }

  @override
  void setQueryComplete(Path<Name> path, QueryFilter filter) {
    if (!filter.limits) {
      _trackedQueryManager.setQueriesComplete(path);
    } else {
      _trackedQueryManager.setQueryCompleteIfExists(QuerySpec(path, filter));
    }
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

  void _doPruneCheckAfterServerUpdate() {
    _serverCacheUpdatesSinceLastPruneCheck++;
    if (cachePolicy
        .shouldCheckCacheSize(_serverCacheUpdatesSinceLastPruneCheck)) {
      _logger.fine('Reached prune check threshold.');
      _serverCacheUpdatesSinceLastPruneCheck = 0;
      var canPrune = true;
      var cacheSize = storageLayer.serverCacheEstimatedSizeInBytes();
      _logger.fine('Cache size: $cacheSize');
      while (canPrune &&
          cachePolicy.shouldPrune(
              cacheSize, _trackedQueryManager.countOfPrunableQueries())) {
        var pruneForest = _trackedQueryManager.pruneOldQueries(cachePolicy);
        if (pruneForest.prunesAnything()) {
          storageLayer.pruneCache(Path(), pruneForest);
        } else {
          canPrune = false;
        }
        cacheSize = storageLayer.serverCacheEstimatedSizeInBytes();
        _logger.fine('Cache size after prune: $cacheSize');
      }
    }
  }
}
