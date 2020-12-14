import 'dart:math';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';
import 'package:firebase_dart/src/database/impl/persistence/engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../tree.dart';
import '../treestructureddata.dart';
import 'package:quiver/core.dart';

final _logger = Logger('firebase.persistence');

@immutable
class TrackedQuery {
  final int id;
  final QuerySpec querySpec;
  final DateTime lastUse;
  final bool complete;
  final bool active;

  TrackedQuery(
      {@required this.id,
      @required this.querySpec,
      @required this.lastUse,
      @required this.complete,
      @required this.active})
      : assert(id != null),
        assert(querySpec != null),
        assert(lastUse != null),
        assert(complete != null),
        assert(active != null),
        assert(
            querySpec.params.limits || querySpec.params == const QueryFilter());

  TrackedQuery.fromJson(Map<String, dynamic> json)
      : this(
            id: json['k'],
            querySpec: QuerySpec.fromJson(json['q']),
            lastUse: DateTime.fromMillisecondsSinceEpoch(json['u']),
            complete: json['c'],
            active: json['a']);

  TrackedQuery replace({DateTime lastUse, bool complete, bool active}) =>
      TrackedQuery(
          id: id,
          querySpec: querySpec,
          lastUse: lastUse ?? this.lastUse,
          complete: complete ?? this.complete,
          active: active ?? this.active);

  TrackedQuery updateLastUse(DateTime lastUse) => replace(lastUse: lastUse);

  TrackedQuery setComplete() => replace(complete: true);

  TrackedQuery setActiveState(bool isActive) => replace(active: isActive);

  Map<String, dynamic> toJson() => {
        'k': id,
        'q': querySpec.toJson(),
        'u': lastUse.millisecondsSinceEpoch,
        'c': complete,
        'a': active
      };

  @override
  bool operator ==(o) =>
      o is TrackedQuery &&
      o.id == id &&
      o.querySpec == querySpec &&
      o.lastUse == lastUse &&
      o.complete == complete &&
      o.active == active;

  @override
  int get hashCode => hashObjects([id, querySpec, lastUse, complete, active]);

  @override
  String toString() {
    return 'TrackedQuery{id=$id, queryFilter=$querySpec, lastUse=$lastUse, '
        'complete=$complete, active=$active}';
  }
}

class TrackedQueryManager {
  static final Predicate<Map<QueryFilter, TrackedQuery>>
      _hasDefaultCompletePredicate = (trackedQueries) {
    var trackedQuery = trackedQueries[const QueryFilter()];
    return trackedQuery != null && trackedQuery.complete;
  };

  static final Predicate<Map<QueryFilter, TrackedQuery>>
      _hasActiveDefaultPredicate = (trackedQueries) {
    var trackedQuery = trackedQueries[const QueryFilter()];
    return trackedQuery != null && trackedQuery.active;
  };

  static final Predicate<TrackedQuery> _isQueryPrunablePredicate =
      (query) => !query.active;

  static final Predicate<TrackedQuery> _isQueryUnprunablePredicate =
      (query) => !_isQueryPrunablePredicate(query);

  /// In-memory cache of tracked queries.
  ///
  /// Should always be in-sync with the DB.
  TreeNode<Name, Map<QueryFilter, TrackedQuery>> trackedQueryTree;

  /// DB, where we permanently store tracked queries.
  final PersistenceStorageEngine storageLayer;

  // ID we'll assign to the next tracked query.
  int _currentQueryId = 0;

  static void assertValidTrackedQuery(QuerySpec query) {
    assert(query.params.limits || query.params == const QueryFilter(),
        "Can't have tracked non-default query that loads all data");
  }

  TrackedQueryManager(this.storageLayer)
      : trackedQueryTree =
            TreeNode<Name, Map<QueryFilter, TrackedQuery>>(null) {
    resetPreviouslyActiveTrackedQueries();

    // Populate our cache from the storage layer.
    var trackedQueries = storageLayer.loadTrackedQueries();
    for (var query in trackedQueries) {
      _currentQueryId = max(query.id + 1, _currentQueryId);
      cacheTrackedQuery(query);
    }
  }

  void resetPreviouslyActiveTrackedQueries() {
    // Minor hack: We do most of our transactions at the SyncTree level, but it
    // is very inconvenient to do so here, so the transaction goes here. :-/
    try {
      storageLayer.beginTransaction();
      storageLayer.resetPreviouslyActiveTrackedQueries(clock.now());
      storageLayer.setTransactionSuccessful();
    } finally {
      storageLayer.endTransaction();
    }
  }

  TrackedQuery findTrackedQuery(QuerySpec query) {
    var child =
        trackedQueryTree.subtree(query.path, (_, __) => TreeNode()).value;
    if (child == null) return null;
    return child[query.normalize().params];
  }

  void removeTrackedQuery(QuerySpec query) {
    query = query.normalize();
    var trackedQuery = findTrackedQuery(query);
    assert(trackedQuery != null, 'Query must exist to be removed.');

    storageLayer.deleteTrackedQuery(trackedQuery.id);
    var trackedQueries = trackedQueryTree.subtree(query.path).value;
    trackedQueries.remove(query.params);
    if (trackedQueries.isEmpty &&
        trackedQueryTree.subtree(query.path).isEmpty) {
      trackedQueryTree = trackedQueryTree.removePath(query.path) ?? TreeNode();
    }
  }

  void setQueryActive(QuerySpec query) {
    _setQueryActiveFlag(query, true);
  }

  void setQueryInactive(QuerySpec query) {
    _setQueryActiveFlag(query, false);
  }

  void _setQueryActiveFlag(QuerySpec query, bool isActive) {
    query = query.normalize();
    var trackedQuery = findTrackedQuery(query);

    // Regardless of whether it's now active or no longer active, we update the lastUse time.
    var lastUse = clock.now();
    if (trackedQuery != null) {
      trackedQuery =
          trackedQuery.updateLastUse(lastUse).setActiveState(isActive);
    } else {
      assert(isActive,
          "If we're setting the query to inactive, we should already be tracking it!");
      trackedQuery = TrackedQuery(
          id: _currentQueryId++,
          querySpec: query,
          lastUse: lastUse,
          complete: false,
          active: isActive);
    }

    saveTrackedQuery(trackedQuery);
  }

  void setQueryCompleteIfExists(QuerySpec query) {
    query = query.normalize();
    var trackedQuery = findTrackedQuery(query);
    if (trackedQuery != null && !trackedQuery.complete) {
      saveTrackedQuery(trackedQuery.setComplete());
    }
  }

  void setQueriesComplete(Path<Name> path) {
    var node = trackedQueryTree.subtree(path);
    if (node == null) return;
    for (var value in node.allNonNullValues) {
      for (var e in value.entries) {
        var trackedQuery = e.value;
        if (!trackedQuery.complete) {
          saveTrackedQuery(trackedQuery.setComplete());
        }
      }
    }
  }

  bool isQueryComplete(QuerySpec query) {
    if (includedInDefaultCompleteQuery(query.path)) {
      return true;
    } else if (!query.params.limits) {
      // We didn't find a default complete query, so must not be complete.
      return false;
    } else {
      var trackedQueries = trackedQueryTree.subtree(query.path)?.value;
      if (trackedQueries == null) return false;
      return trackedQueries != null &&
          trackedQueries.containsKey(query.params) &&
          trackedQueries[query.params].complete;
    }
  }

  PruneForest pruneOldQueries(CachePolicy cachePolicy) {
    var prunable = getQueriesMatching(_isQueryPrunablePredicate);
    var countToPrune = calculateCountToPrune(cachePolicy, prunable.length);
    var forest = PruneForest();

    _logger.fine(
        'Pruning old queries. Prunable: ${prunable.length}. Count to prune: $countToPrune');

    prunable.sort((q1, q2) => Comparable.compare(q1.lastUse, q2.lastUse));

    for (var i = 0; i < countToPrune; i++) {
      var toPrune = prunable[i];
      forest = forest.prune(toPrune.querySpec.path);
      removeTrackedQuery(toPrune.querySpec);
    }

    // Keep the rest of the prunable queries.
    for (var i = countToPrune; i < prunable.length; i++) {
      var toKeep = prunable[i];
      forest = forest.keep(toKeep.querySpec.path);
    }

    // Also keep the unprunable queries.
    var unprunable = getQueriesMatching(_isQueryUnprunablePredicate);
    _logger.fine('Unprunable queries: ${unprunable.length}');
    for (var toKeep in unprunable) {
      forest = forest.keep(toKeep.querySpec.path);
    }

    return forest;
  }

  static int calculateCountToPrune(CachePolicy cachePolicy, int prunableCount) {
    var countToKeep = prunableCount;

    // prune by percentage.
    var percentToKeep = 1 - cachePolicy.getPercentOfQueriesToPruneAtOnce();
    countToKeep = (countToKeep * percentToKeep).floor();

    // Make sure we're not keeping more than the max.
    countToKeep = min(countToKeep, cachePolicy.getMaxNumberOfQueriesToKeep());

    // Now we know how many to prune.
    return prunableCount - countToKeep;
  }

  void ensureCompleteTrackedQuery(Path path) {
    if (!includedInDefaultCompleteQuery(path)) {
      // TODO[persistence]: What if it's included in the tracked keys of a query?  Do we still want
      // to add a new tracked query for it?

      var querySpec = QuerySpec(path);
      var trackedQuery = findTrackedQuery(querySpec);
      if (trackedQuery == null) {
        trackedQuery = TrackedQuery(
            id: _currentQueryId++,
            querySpec: querySpec,
            lastUse: clock.now(),
            complete: true,
            active: false);
      } else {
        assert(!trackedQuery.complete, 'This should have been handled above!');
        trackedQuery = trackedQuery.setComplete();
      }
      saveTrackedQuery(trackedQuery);
    }
  }

  bool hasActiveDefaultQuery(Path path) {
    return trackedQueryTree.rootMostValueMatching(
            path, _hasActiveDefaultPredicate) !=
        null;
  }

  int countOfPrunableQueries() {
    return getQueriesMatching(_isQueryPrunablePredicate).length;
  }

  /// Used for tests to assert we're still in-sync with the DB.
  ///
  /// Don't call it in production, since it's slow.
  @visibleForTesting
  void verifyCache() {
    var storedTrackedQueries = storageLayer.loadTrackedQueries();

    final trackedQueries = <TrackedQuery>[
      ...trackedQueryTree.allNonNullValues.expand((v) => v.values)
    ];
    trackedQueries.sort((o1, o2) => Comparable.compare(o1.id, o2.id));

    assert(const ListEquality().equals(storedTrackedQueries, trackedQueries),
        'Tracked queries out of sync.  Tracked queries: $trackedQueries. Stored queries: $storedTrackedQueries');
  }

  bool includedInDefaultCompleteQuery(Path path) {
    return trackedQueryTree.findRootMostMatchingPath(
            path, _hasDefaultCompletePredicate) !=
        null;
  }

  Set<int> filteredQueryIdsAtPath(Path path) {
    final ids = <int>{};

    var queries = trackedQueryTree.subtree(path)?.value;
    if (queries != null) {
      for (var query in queries.values) {
        if (query.querySpec.params.limits) {
          ids.add(query.id);
        }
      }
    }
    return ids;
  }

  void cacheTrackedQuery(TrackedQuery query) {
    assertValidTrackedQuery(query.querySpec);

    var trackedSet = trackedQueryTree.subtree(query.querySpec.path).value;
    if (trackedSet == null) {
      trackedSet = <QueryFilter, TrackedQuery>{};
      trackedQueryTree =
          trackedQueryTree.setValue(query.querySpec.path, trackedSet);
    }

    // Sanity check.
    var existing = trackedSet[query.querySpec.params];
    assert(existing == null || existing.id == query.id);

    trackedSet[query.querySpec.params] = query;
  }

  void saveTrackedQuery(TrackedQuery query) {
    cacheTrackedQuery(query);
    storageLayer.saveTrackedQuery(query);
  }

  List<TrackedQuery> getQueriesMatching(Predicate<TrackedQuery> predicate) {
    return [
      ...trackedQueryTree.allNonNullValues.expand((v) {
        return v.values.where(predicate);
      })
    ];
  }
}
