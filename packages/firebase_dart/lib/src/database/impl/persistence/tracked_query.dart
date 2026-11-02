import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/database/impl/persistence/engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../tree.dart';
import '../treestructureddata.dart';

final _logger = Logger('firebase.persistence');

@immutable
class TrackedQuery {
  final int id;
  final QuerySpec querySpec;
  final DateTime lastUse;
  final bool complete;
  final bool active;

  TrackedQuery(
      {required this.id,
      required this.querySpec,
      required this.lastUse,
      required this.complete,
      required this.active})
      : assert(
            querySpec.params.limits || querySpec.params == const QueryFilter());

  TrackedQuery.fromJson(Map<dynamic, dynamic> json)
      : this(
            id: json['k'],
            querySpec: QuerySpec.fromJson(json['q']),
            lastUse: DateTime.fromMicrosecondsSinceEpoch(json['u']),
            complete: json['c'],
            active: json['a']);

  TrackedQuery replace({DateTime? lastUse, bool? complete, bool? active}) =>
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
        'u': lastUse.microsecondsSinceEpoch,
        'c': complete,
        'a': active
      };

  @override
  bool operator ==(other) =>
      other is TrackedQuery &&
      other.id == id &&
      other.querySpec == querySpec &&
      other.lastUse == lastUse &&
      other.complete == complete &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, querySpec, lastUse, complete, active);

  @override
  String toString() {
    return 'TrackedQuery{id=$id, queryFilter=$querySpec, lastUse=$lastUse, '
        'complete=$complete, active=$active}';
  }
}

class TrackedQueryManager {
  static bool _hasDefaultCompletePredicate(
      Map<QueryFilter, TrackedQuery> trackedQueries) {
    var trackedQuery = trackedQueries[const QueryFilter()];
    return trackedQuery != null && trackedQuery.complete;
  }

  static bool _hasActiveDefaultPredicate(
      Map<QueryFilter, TrackedQuery> trackedQueries) {
    var trackedQuery = trackedQueries[const QueryFilter()];
    return trackedQuery != null && trackedQuery.active;
  }

  static bool _isQueryPrunablePredicate(TrackedQuery query) => !query.active;

  static bool _isQueryUnprunablePredicate(TrackedQuery query) =>
      !_isQueryPrunablePredicate(query);

  /// In-memory cache of tracked queries.
  ///
  /// Should always be in-sync with the DB.
  ModifiableTreeNode<Name, Map<QueryFilter, TrackedQuery>> trackedQueryTree;

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
            ModifiableTreeNode<Name, Map<QueryFilter, TrackedQuery>>({}) {
    resetPreviouslyActiveTrackedQueries();

    // Populate our cache from the storage layer.
    var trackedQueries = storageLayer.loadTrackedQueries();
    for (var query in trackedQueries) {
      _currentQueryId = max(query.id + 1, _currentQueryId);
      cacheTrackedQuery(query);
    }
    _removeServerCacheNotCoveredByTrackedQueries(trackedQueries);
  }

  /// Drops server cache that no tracked query covers. Existing installs can
  /// already contain that data; this runs once per database.
  void _removeServerCacheNotCoveredByTrackedQueries(
      List<TrackedQuery> trackedQueries) {
    if (storageLayer.orphanedServerCacheRemoved) return;

    try {
      storageLayer.beginTransaction();
      var forest = PruneForest().prune(Path());
      for (var query in trackedQueries) {
        forest = _keepQuery(forest, query);
      }
      storageLayer.pruneCache(forest);
      storageLayer.markOrphanedServerCacheRemoved();
      storageLayer.setTransactionSuccessful();
    } finally {
      storageLayer.endTransaction();
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

  TrackedQuery? findTrackedQuery(QuerySpec query) {
    var child = trackedQueryTree
        .subtree(query.path, (_, __) => ModifiableTreeNode({}))
        .value;
    return child[query.normalize().params];
  }

  void removeTrackedQuery(QuerySpec query) {
    query = query.normalize();
    var trackedQuery = findTrackedQuery(query)!;

    storageLayer.deleteTrackedQuery(trackedQuery.id);
    var trackedQueries = trackedQueryTree.subtreeNullable(query.path)!.value;
    trackedQueries.remove(query.params);
    if (trackedQueries.isEmpty &&
        trackedQueryTree.subtreeNullable(query.path)!.isEmpty) {
      trackedQueryTree =
          trackedQueryTree.removePath(query.path) ?? ModifiableTreeNode({});
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
    var node = trackedQueryTree.subtreeNullable(path);
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
      var trackedQueries = trackedQueryTree.subtreeNullable(query.path)?.value;
      if (trackedQueries == null) return false;
      return trackedQueries.containsKey(query.params) &&
          trackedQueries[query.params]!.complete;
    }
  }

  /// Drops the oldest prunable queries until the cache is at or below
  /// [targetBytes] and at most [maxQueriesToKeep] prunable queries remain.
  PruneForest pruneToMaximumSize(int targetBytes, int maxQueriesToKeep) {
    var prunable = getQueriesMatching(_isQueryPrunablePredicate);
    prunable.sort((q1, q2) => Comparable.compare(q1.lastUse, q2.lastUse));
    var unprunable = getQueriesMatching(_isQueryUnprunablePredicate);

    var nodes = <_CacheNode>[];
    storageLayer.serverCache(Path()).forEachCompleteNode((path, value) {
      nodes.add(_CacheNode(path, _estimatedNodeStorageSize(path, value)));
    });
    var current = 0;
    for (var node in nodes) {
      current += node.bytes;
    }

    var dropped = <TrackedQuery>[];
    var droppedSet = <TrackedQuery>{};
    var minDrop = max(0, prunable.length - maxQueriesToKeep);
    for (var query in prunable) {
      if (dropped.length >= minDrop && current <= targetBytes) break;
      dropped.add(query);
      droppedSet.add(query);
      for (var node in nodes) {
        if (node.freed || !_queryCovers(query, node.path)) continue;
        if (_keptByRemainingQuery(
            node.path, prunable, unprunable, droppedSet)) {
          continue;
        }
        current -= node.bytes;
        node.freed = true;
      }
    }

    var forest = PruneForest();
    for (var query in dropped) {
      forest = forest.prune(query.querySpec.path);
      removeTrackedQuery(query.querySpec);
    }
    for (var query in prunable) {
      if (droppedSet.contains(query)) continue;
      forest = _keepQuery(forest, query);
    }
    for (var query in unprunable) {
      forest = _keepQuery(forest, query);
    }
    return forest;
  }

  bool _queryCovers(TrackedQuery query, Path<Name> node) {
    var path = query.querySpec.path;
    if (node != path && !node.isDescendantOf(path)) return false;
    if (!query.querySpec.params.limits) return true;
    if (node.length == path.length) return false;
    var keys = storageLayer
        .serverCache(path)
        .withFilter(query.querySpec.params)
        .value
        .children
        .keys;
    return keys.contains(node[path.length]);
  }

  bool _keptByRemainingQuery(Path<Name> node, List<TrackedQuery> prunable,
      List<TrackedQuery> unprunable, Set<TrackedQuery> dropped) {
    for (var query in unprunable) {
      if (_queryCovers(query, node)) return true;
    }
    for (var query in prunable) {
      if (dropped.contains(query)) continue;
      if (_queryCovers(query, node)) return true;
    }
    return false;
  }

  /// A default query covers its whole path. A limited query only covers the
  /// children currently in the cache that match its filter, so other queries
  /// on the same path can still drop their own children.
  PruneForest _keepQuery(PruneForest forest, TrackedQuery query) {
    var spec = query.querySpec;
    if (!spec.params.limits) {
      return forest.keep(spec.path);
    }
    var keys = storageLayer
        .serverCache(spec.path)
        .withFilter(spec.params)
        .value
        .children
        .keys
        .toSet();
    return forest.keepAll(spec.path, keys);
  }

  void ensureCompleteTrackedQuery(Path<Name> path) {
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

  bool hasActiveDefaultQuery(Path<Name> path) {
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
  bool includedInDefaultCompleteQuery(Path<Name> path) {
    return trackedQueryTree.findRootMostMatchingPath(
            path, _hasDefaultCompletePredicate) !=
        null;
  }

  Set<int> filteredQueryIdsAtPath(Path<Name> path) {
    final ids = <int>{};

    var queries = trackedQueryTree.subtreeNullable(path)?.value;
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

    var trackedSet =
        trackedQueryTree.subtreeNullable(query.querySpec.path)?.value;
    if (trackedSet == null) {
      trackedSet = <QueryFilter, TrackedQuery>{};
      trackedQueryTree =
          trackedQueryTree.setValue(query.querySpec.path, trackedSet, () => {});
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

int _estimatedNodeStorageSize(Path<Name> path, TreeStructuredData value) {
  return path.join('/').length +
      json.encode(value.toJson(true)).toString().length;
}

class _CacheNode {
  final Path<Name> path;
  final int bytes;
  bool freed = false;

  _CacheNode(this.path, this.bytes);
}
