import 'dart:convert';

import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

class MockPersistenceStorageEngine implements PersistenceStorageEngine {
  final Map<int, Set<Name>> trackedQueryKeys = {};
  final Map<int, TrackedQuery> trackedQueries = {};
  final Map<int, TreeOperation> writes = {};
  IncompleteData _serverCache = IncompleteData.empty();

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
  void deleteTrackedQuery(int trackedQueryId) {
    _verifyInsideTransaction();
    trackedQueries.remove(trackedQueryId);
    trackedQueryKeys.remove(trackedQueryId);
  }

  @override
  void endTransaction() {
    _insideTransaction = false;
  }

  @override
  List<TrackedQuery> loadTrackedQueries() {
    return [...trackedQueries.values]
      ..sort((a, b) => Comparable.compare(a.id, b.id));
  }

  Set<Name> _loadTrackedQueryKeys(int trackedQueryId) {
    assert(trackedQueries.containsKey(trackedQueryId),
        "Can't track keys for an untracked query.");
    var trackedKeys = trackedQueryKeys[trackedQueryId];
    return {...?trackedKeys};
  }

  @override
  Set<Name> loadTrackedQueryKeys(Iterable<int> trackedQueryIds) {
    var keys = <Name>{};
    for (var id in trackedQueryIds) {
      assert(trackedQueries.containsKey(id),
          "Can't track keys for an untracked query.");
      keys.addAll(_loadTrackedQueryKeys(id));
    }
    return keys;
  }

  @override
  void overwriteServerCache(TreeOperation operation) {
    _verifyInsideTransaction();
    _serverCache = _serverCache.applyOperation(operation);
  }

  IncompleteData get serverCache => _serverCache;

  @override
  void pruneCache(Path<Name> prunePath, PruneForest pruneForest) {
    _verifyInsideTransaction();

    _serverCache.forEachCompleteNode((absoluteDataPath, value) {
      assert(
          prunePath == absoluteDataPath ||
              !absoluteDataPath.contains(prunePath),
          'Pruning at $prunePath but we found data higher up.');
      if (prunePath.contains(absoluteDataPath)) {
        final dataPath = absoluteDataPath.skip(prunePath.length);
        final dataNode = value;
        if (pruneForest.shouldPruneUnkeptDescendants(dataPath)) {
          var newCache = pruneForest
              .child(dataPath)
              .foldKeptNodes<IncompleteData>(IncompleteData.empty(),
                  (keepPath, value, accum) {
            var op = TreeOperation.overwrite(
                Path.from([...absoluteDataPath, ...keepPath]),
                dataNode.getChild(keepPath));
            return accum.applyOperation(op);
          });
          _serverCache = _serverCache
              .removeWrite(absoluteDataPath)
              .applyOperation(newCache.toOperation());
        } else {
          // NOTE: This is technically a valid scenario (e.g. you ask to prune at / but only want to
          // prune 'foo' and 'bar' and ignore everything else).  But currently our pruning will
          // explicitly prune or keep everything we know about, so if we hit this it means our
          // tracked queries and the server cache are out of sync.
          assert(pruneForest.shouldKeep(dataPath),
              'We have data at $dataPath that is neither pruned nor kept.');
        }
      }
    });
  }

  @override
  void removeUserOperation(int writeId) {
    _verifyInsideTransaction();
    assert(writes.containsKey(writeId),
        "Tried to remove write that doesn't exist.");
    writes.remove(writeId);
  }

  @override
  void resetPreviouslyActiveTrackedQueries(DateTime lastUse) {
    for (var entry in trackedQueries.entries) {
      var id = entry.key;
      var query = entry.value;
      if (query.active) {
        query = query.setActiveState(false).updateLastUse(lastUse);
        trackedQueries[id] = query;
      }
    }
  }

  @override
  void saveTrackedQuery(TrackedQuery trackedQuery) {
    _verifyInsideTransaction();
    // Sanity check: If we're using the same id, it should be the same query.
    var existing = trackedQueries[trackedQuery.id];
    assert(existing == null || existing.querySpec == trackedQuery.querySpec);

    // Sanity check: If this queryspec already exists, it should be the same id.
    for (var query in trackedQueries.values) {
      if (query.querySpec == trackedQuery.querySpec) {
        assert(query.id == trackedQuery.id);
      }
    }

    trackedQueries[trackedQuery.id] = trackedQuery;
  }

  @override
  void saveTrackedQueryKeys(int trackedQueryId, Set<Name> keys) {
    _verifyInsideTransaction();
    assert(trackedQueries.containsKey(trackedQueryId),
        "Can't track keys for an untracked query.");
    trackedQueryKeys[trackedQueryId] = {...keys};
  }

  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    _verifyInsideTransaction();
    writes[writeId] = operation;
  }

  @override
  int serverCacheEstimatedSizeInBytes() {
    return json.encode(_serverCache.value).length;
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
