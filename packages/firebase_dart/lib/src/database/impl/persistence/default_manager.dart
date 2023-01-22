import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:logging/logging.dart';

import '../data_observer.dart';
import '../query_spec.dart';
import '../synctree.dart';
import '../treestructureddata.dart';
import '../view.dart';
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
  void updateServerCache(QuerySpec query, TreeOperation operation) {
    if (query.params.limits && query.path == operation.path) {
      var o = operation.nodeOperation;
      if (o is Overwrite) {
        operation = TreeOperation.merge(operation.path,
            o.value.children.map((k, v) => MapEntry(Path.from([k]), v)));
      }
    }
    storageLayer.overwriteServerCache(operation);
    setQueryComplete(query);
    _doPruneCheckAfterServerUpdate();
  }

  bool _completeQueryContains(
      QueryFilter masterFilter, IncompleteData data, QueryFilter f) {
    var v = MasterView(masterFilter)
      ..applyOperation(TreeOperation.overwrite(Path.from([]), data.value),
          ViewOperationSource.server, null);
    return v.contains(f);
  }

  @override
  IncompleteData serverCache(QuerySpec query) {
    var v = storageLayer.serverCache(query.path);
    if (_trackedQueryManager.isQueryComplete(query)) {
      return IncompleteData.complete(v.value).withFilter(query.params);
    } else {
      var queries = _trackedQueryManager.trackedQueryTree
              .subtreeNullable(query.path)
              ?.value ??
          {};
      for (var p in queries.keys) {
        if (p.ordering == query.params.ordering &&
            queries[p]!.complete &&
            _completeQueryContains(p, v, query.params)) {
          return IncompleteData.complete(v.value).withFilter(query.params);
        }
      }

      return v.withFilter(query.params);
    }
  }

  @override
  void setQueryActive(QuerySpec query) {
    _trackedQueryManager.setQueryActive(query);
  }

  @override
  void setQueryInactive(QuerySpec query) {
    _trackedQueryManager.setQueryInactive(query);
  }

  @override
  void setQueryComplete(QuerySpec query) {
    if (!query.params.limits) {
      _trackedQueryManager.setQueriesComplete(query.path);
    } else {
      _trackedQueryManager.setQueryCompleteIfExists(query);
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
          storageLayer.pruneCache(pruneForest);
        } else {
          canPrune = false;
        }
        cacheSize = storageLayer.serverCacheEstimatedSizeInBytes();
        _logger.fine('Cache size after prune: $cacheSize');
      }
    }
  }

  @override
  Future<void> close() {
    return storageLayer.close();
  }
}
