import 'dart:async';

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

String _formatElapsed(int microseconds) {
  if (microseconds < 1000) return '${microseconds}us';
  return '${(microseconds / 1000).toStringAsFixed(1)}ms';
}

class _TimedWork {
  final int elapsedUs;
  final int? endBytes;

  _TimedWork(this.elapsedUs, this.endBytes);
}

class DefaultPersistenceManager implements PersistenceManager {
  @override
  bool get isEnabled => true;

  final PersistenceStorageEngine storageLayer;
  final TrackedQueryManager _trackedQueryManager;
  final CachePolicy cachePolicy;
  int _serverCacheUpdatesSinceLastPruneCheck = 0;
  bool _pruneNeeded = false;
  bool _sizeCheckPending = false;
  bool _maintenanceScheduled = false;
  bool _closed = false;

  DefaultPersistenceManager(this.storageLayer, this.cachePolicy)
      : _trackedQueryManager = TrackedQueryManager(storageLayer) {
    // Measure the cache in the deferred maintenance, not during startup.
    _sizeCheckPending = true;
    _scheduleMaintenance();
  }

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
    var currentValue =
        storageLayer.serverCache(query.path).withFilter(query.params).value;
    var expected = query.path
        .fold(operation, (o, k) => o.operationForChild(k)!)
        .apply(currentValue);

    if (query.params.limits && query.path == operation.path) {
      var o = operation.nodeOperation;
      if (o is Overwrite) {
        // the new value in not necessarily complete for the path, it is only complete for the query
        operation = TreeOperation.merge(operation.path,
            o.value.children.map((k, v) => MapEntry(Path.from([k]), v)));
      }
    }
    storageLayer.overwriteServerCache(operation);
    setQueryComplete(query);

    // check if the value is as expected, if not, forget the extra keys
    var actual =
        storageLayer.serverCache(query.path).withFilter(query.params).value;
    while (actual != expected) {
      var wrongKeys = actual.children.keys
          .toSet()
          .difference(expected.children.keys.toSet());
      if (wrongKeys.isEmpty) {
        // this should probably not happen, but we will break out of the loop to avoid infinite loop
        _logger.warning(
            'Unexpected state: value in persistence storage does not match expected value.');
        break;
      }

      for (var k in wrongKeys) {
        storageLayer
            .overwriteServerCache(TreeOperation(query.path.child(k), Forget()));
      }

      actual =
          storageLayer.serverCache(query.path).withFilter(query.params).value;
    }

    _doPruneCheckAfterServerUpdate();
  }

  bool _completeQueryContains(
      QueryFilter masterFilter, IncompleteData data, QueryFilter f) {
    var v = MasterView(masterFilter, persistenceEnabled: isEnabled)
      ..applyOperation(TreeOperation.overwrite(Path.from([]), data.value),
          ViewOperationSource.server, null);
    return v.contains(f);
  }

  @override
  IncompleteData serverCache(QuerySpec query) {
    var v = storageLayer.serverCache(query.path);
    final ordering = query.params.ordering;
    if (ordering is TreeStructuredDataOrdering &&
        ordering != const TreeStructuredDataOrdering.byPriority()) {
      v.writeTree.addIndex(ordering);
    }
    if (_trackedQueryManager.isQueryComplete(query)) {
      return IncompleteData.complete(v.withFilter(query.params).value)
          .withFilter(query.params);
    } else {
      var queries = _trackedQueryManager.trackedQueryTree
              .subtreeNullable(query.path)
              ?.value ??
          {};
      for (var p in queries.keys) {
        if (p.ordering == query.params.ordering &&
            queries[p]!.complete &&
            _completeQueryContains(p, v, query.params)) {
          return IncompleteData.complete(v.withFilter(query.params).value)
              .withFilter(query.params);
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
      _sizeCheckPending = true;
      _scheduleMaintenance();
    }
  }

  /// Measures the cache and, when it should be pruned, only records that.
  void _notePruneIfNeeded() {
    var cacheSize = storageLayer.serverCacheEstimatedSizeInBytes();
    var prunable = _trackedQueryManager.countOfPrunableQueries();
    if (cachePolicy.shouldPrune(cacheSize, prunable)) {
      _pruneNeeded = true;
    }
    _logger.fine('Cache size check: $cacheSize bytes, $prunable prunable '
        'queries${_pruneNeeded ? ', prune marked' : ''}.');
  }

  void _scheduleMaintenance() {
    if (_closed || _maintenanceScheduled) return;
    if (!_pruneNeeded &&
        !_sizeCheckPending &&
        storageLayer.orphanedServerCacheRemoved) {
      return;
    }
    _maintenanceScheduled = true;
    // A timer lets the current frame and pending events run first; a
    // microtask would run before the next frame.
    Timer(Duration.zero, _runMaintenance);
  }

  void _runMaintenance() {
    _maintenanceScheduled = false;
    if (_closed) return;
    if (_sizeCheckPending) {
      _sizeCheckPending = false;
      _notePruneIfNeeded();
    }
    if (!_pruneNeeded && storageLayer.orphanedServerCacheRemoved) return;

    var prune = _pruneNeeded;
    _pruneNeeded = false;
    var orphanCleanup = !storageLayer.orphanedServerCacheRemoved;
    _logger.fine('Persistence maintenance started '
        '(orphan cleanup: $orphanCleanup, size prune: $prune).');
    var elapsedUs = 0;
    runInTransaction(() {
      // Logged sizes cost a full cache walk, so only measure them at FINEST.
      var size = _logger.isLoggable(Level.FINEST)
          ? storageLayer.serverCacheEstimatedSizeInBytes()
          : null;
      if (orphanCleanup) {
        var result = _runTimed('Orphan cache cleanup', size, () {
          _trackedQueryManager.removeOrphanedServerCacheOnce();
        });
        size = result.endBytes;
        elapsedUs += result.elapsedUs;
      }
      if (prune) {
        var result = _runTimed(
            'Cache prune (target ${cachePolicy.maximumCacheSizeAfterPrune} '
            'bytes, keep ${cachePolicy.maxNumberOfQueriesToKeep} queries)',
            size, () {
          var pruneForest = _trackedQueryManager.pruneToMaximumSize(
              cachePolicy.maximumCacheSizeAfterPrune,
              cachePolicy.maxNumberOfQueriesToKeep);
          if (pruneForest.prunesAnything()) {
            storageLayer.pruneCache(pruneForest);
          }
        });
        elapsedUs += result.elapsedUs;
      }
    });
    _logger.fine(
        'Persistence maintenance finished in ${_formatElapsed(elapsedUs)}.');
  }

  /// Runs [body] and logs its cache size, prunable-query count, and duration.
  ///
  /// The end size is measured only at [Level.FINEST]. That size is returned so
  /// a following prune can use it as its start size.
  _TimedWork _runTimed(String action, int? startBytes, void Function() body) {
    var queriesBefore = _trackedQueryManager.countOfPrunableQueries();
    var watch = Stopwatch()..start();
    body();
    watch.stop();
    int? endBytes;
    if (_logger.isLoggable(Level.FINE)) {
      endBytes = _logger.isLoggable(Level.FINEST)
          ? storageLayer.serverCacheEstimatedSizeInBytes()
          : null;
      var queriesAfter = _trackedQueryManager.countOfPrunableQueries();
      _logger.fine('$action: ${startBytes ?? '?'} -> $endBytes bytes, '
          '$queriesBefore -> $queriesAfter prunable queries, '
          '${_formatElapsed(watch.elapsedMicroseconds)}.');
    }
    return _TimedWork(watch.elapsedMicroseconds, endBytes);
  }

  @override
  Future<void> close() {
    _closed = true;
    return storageLayer.close();
  }
}
