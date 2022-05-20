// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:firebase_dart/database.dart' show FirebaseDatabaseException;
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:sortedmap/sortedmap.dart';

import 'data_observer.dart';
import 'event.dart';
import 'events/cancel.dart';
import 'operations/tree.dart';
import 'tree.dart';
import 'treestructureddata.dart';
import 'view.dart';

import 'package:synchronized/extension.dart';

final _logger = Logger('firebase-synctree');

class MasterView {
  QueryFilter masterFilter;

  final String? debugName;

  ViewCache _data;

  final Map<QueryFilter, EventTarget> observers = {};

  MasterView(this.masterFilter, {this.debugName})
      : _data = ViewCache(IncompleteData.empty(masterFilter),
            IncompleteData.empty(masterFilter));

  MasterView withFilter(QueryFilter filter) =>
      MasterView(filter, debugName: debugName)
        .._data = _data.withFilter(filter);

  ViewCache get data => _data;

  void upgrade() {
    masterFilter = QueryFilter(
        ordering: masterFilter.ordering as TreeStructuredDataOrdering);
    _data = _data.withFilter(masterFilter);
  }

  /// Checks if the filter [f] is contained by the data in this master view
  ///
  /// When the filter might be contained, but it cannot be determined yet,
  /// because the data in this view is not yet complete, it will return true.
  bool contains(QueryFilter f) {
    if (f == masterFilter) return true;
    if (f.orderBy != masterFilter.orderBy) return false;
    if (!masterFilter.limits) return true;
    if (!_data.localVersion.isComplete) {
      if (masterFilter.limit == null) {
        if (masterFilter.validInterval.contains(f.validInterval)) return true;
      }
      if (f.limit == null) {
        if (!masterFilter.validInterval.contains(f.validInterval)) return false;
      }

      if (masterFilter.validInterval.containsPoint(
          f.reversed ? f.validInterval.end : f.validInterval.start)) {
        return true;
      }
      return false;
    }

    var i = _data.localVersion.value.childrenAsFilteredMap.completeInterval;
    if (i.start == Pair.min()) {
      if (i.end == Pair.max() || i.containsPoint(f.validInterval.end)) {
        return true;
      }
    } else if (i.end == Pair.max() && i.containsPoint(f.validInterval.start)) {
      return true;
    } else if (i.contains(f.validInterval)) {
      return true;
    }
    return _data.localVersion.value.childrenAsFilteredMap
        .filteredMapView(
            start: f.validInterval.start,
            end: f.validInterval.end,
            limit: f.limit,
            reversed: f.reversed)
        .isComplete;
  }

  bool isCompleteForChild(Name child) {
    var l = _data.localVersion;
    if (!l.isComplete) {
      // we don't have all the data yet, so could be complete
      return true;
    }
    if (!masterFilter.limits) {
      // query is not limiting, so all children will be complete
      return true;
    }
    if (l.value.children.containsKey(child)) {
      // the child exists and is present in this complete value
      return true;
    }
    if (masterFilter.ordering is KeyOrdering) {
      if (l.value.childrenAsFilteredMap.completeInterval.containsPoint(
          masterFilter.ordering.mapKeyValue(child, TreeStructuredData()))) {
        // the child does not exist as it should be present in the data if it did
        return true;
      }
    }
    return false;
  }

  /// Adds the event listener only when the filter is contained by the master
  /// filter.
  ///
  /// Returns true when the listener was added.
  bool addEventListener(
      String type, QueryFilter filter, EventListener listener) {
    if (!contains(filter)) return false;
    observers
        .putIfAbsent(
            filter,
            () =>
                EventTarget()..notifyDataChanged(_data.valueForFilter(filter)))
        .addEventListener(type, listener);

    return true;
  }

  void adoptEventTarget(QueryFilter filter, EventTarget target) {
    assert(observers[filter] == null);
    observers[filter] = target;
    target.notifyDataChanged(_data.valueForFilter(filter));
  }

  /// Removes the event listener.
  void removeEventListener(
      String type, QueryFilter filter, EventListener listener) {
    var target = observers[filter];
    if (target == null) return;
    target.removeEventListener(type, listener);
    if (!target.hasEventRegistrations) {
      observers.remove(filter);
    }
  }

  /// Applies an operation.
  ///
  /// Removes and returns queries that are no longer contained by this master
  /// view.
  Map<QueryFilter, EventTarget> applyOperation(
      Operation operation, ViewOperationSource source, int? writeId) {
    _data = _data.applyOperation(operation, source, writeId);

    var out = <QueryFilter, EventTarget>{};
    for (var q in observers.keys.toList()) {
      if (!contains(q)) {
        out[q] = observers.remove(q)!;
      }
    }

    for (var q in observers.keys) {
      var t = observers[q]!;

      var newValue = _data.valueForFilter(q);
      t.notifyDataChanged(newValue);
    }
    return out;
  }
}

/// Represents a remote resource and holds local (partial) views and local
/// changes of its value.
class SyncPoint {
  final String debugName;

  final Map<QueryFilter, MasterView> views = {};

  bool _isCompleteFromParent = false;

  final PersistenceManager persistenceManager;

  final Path<Name> path;

  final Map<QueryFilter, EventTarget> _newQueries = {};

  SyncPoint(this.debugName, this.path,
      {ViewCache? data, required this.persistenceManager}) {
    if (data == null) return;
    var q = QueryFilter();
    views[q] = MasterView(q, debugName: debugName).._data = data;
  }

  SyncPoint child(Name child) {
    var p = SyncPoint('$debugName/$child', path.child(child),
        data: viewCacheForChild(child), persistenceManager: persistenceManager);
    p.isCompleteFromParent = isCompleteForChild(child);
    return p;
  }

  bool get isCompleteFromParent => _isCompleteFromParent;

  set isCompleteFromParent(bool v) {
    if (_isCompleteFromParent == v) return;
    _isCompleteFromParent = v;
    if (_isCompleteFromParent) {
      views.putIfAbsent(const QueryFilter(),
          () => MasterView(const QueryFilter(), debugName: debugName));
      _prunable = true;
    } else {
      var defView = views[const QueryFilter()]!;
      if (!defView.observers.containsKey(const QueryFilter())) {
        views.remove(const QueryFilter());
        for (var k in defView.observers.keys.toList()) {
          var view = getMasterViewForFilter(k);
          view.adoptEventTarget(k, defView.observers.remove(k)!);
        }
      }
    }
  }

  ViewCache? viewCacheForChild(Name child) {
    for (var m in views.values) {
      if (m.isCompleteForChild(child)) return m._data.child(child);
    }
    return null;
  }

  bool isCompleteForChild(Name child) {
    if (isCompleteFromParent) return true;
    prune();
    return views.values.any((m) => m.isCompleteForChild(child));
  }

  Iterable<QueryFilter> get minimalSetOfQueries {
    processNewQueries();
    if (isCompleteFromParent) return const [];
    var queries = views.keys;
    if (queries.any((q) => !q.limits)) {
      return const [QueryFilter()];
    } else {
      return queries;
    }
  }

  @visibleForTesting
  void processNewQueries() {
    if (isCompleteFromParent) {
      _newQueries.forEach((key, value) {
        getMasterViewForFilter(key).adoptEventTarget(key, value);
      });
      _newQueries.clear();
      return;
    }
    prune();
    var queries = views.keys;
    if (queries.any((q) => !q.limits)) {
      _newQueries.forEach((key, value) {
        getMasterViewForFilter(key).adoptEventTarget(key, value);
      });
      _newQueries.clear();
    } else {
      // TODO: move this to a separate class and make it configurable
      var v = <Ordering, Map<QueryFilter, EventTarget>>{};
      _newQueries.forEach((key, value) {
        v.putIfAbsent(key.ordering, () => {})[key] = value;
      });
      _newQueries.clear();

      for (var o in v.keys) {
        var nonLimitingQueries =
            v[o]!.keys.where((v) => v.limit == null).toList();

        var intervals = KeyValueIntervalX.unionAll(
            nonLimitingQueries.map((q) => q.validInterval));

        for (var i in intervals) {
          createMasterViewForFilter(QueryFilter(
              ordering: o as TreeStructuredDataOrdering, validInterval: i));
        }

        for (var q in v[o]!.keys.toList()) {
          var view =
              views.values.firstWhereOrNull((element) => element.contains(q));
          assert(view?.observers[q] == null);
          if (view != null) {
            view.adoptEventTarget(q, v[o]!.remove(q)!);
          }
        }

        var forwardLimitingQueries = v[o]!
            .keys
            .where((v) => v.limit != null && !v.reversed)
            .toList()
          ..sort((a, b) =>
              Comparable.compare(a.validInterval.start, b.validInterval.start));

        while (forwardLimitingQueries.isNotEmpty) {
          var view = createMasterViewForFilter(forwardLimitingQueries.first);

          for (var q in forwardLimitingQueries.toList()) {
            if (view.contains(q)) {
              forwardLimitingQueries.remove(q);
              view.adoptEventTarget(q, v[o]!.remove(q)!);
            }
          }
        }

        var backwardLimitingQueries = v[o]!
            .keys
            .where((v) => v.limit != null && v.reversed)
            .toList()
          ..sort((a, b) =>
              -Comparable.compare(a.validInterval.end, b.validInterval.end));

        while (backwardLimitingQueries.isNotEmpty) {
          var view = createMasterViewForFilter(backwardLimitingQueries.first);

          for (var q in backwardLimitingQueries.toList()) {
            if (view.contains(q)) {
              backwardLimitingQueries.remove(q);
              view.adoptEventTarget(q, v[o]!.remove(q)!);
            }
          }
        }
      }
    }
  }

  TreeStructuredData valueForFilter(QueryFilter filter) {
    return views.values
            .firstWhereOrNull((v) => v.contains(filter))
            ?._data
            .valueForFilter(filter)
            .value ??
        TreeStructuredData();
  }

  /// Adds an event listener for events of [type] and for data filtered by
  /// [filter].
  void addEventListener(
      String type, QueryFilter filter, EventListener listener) {
    var v = getMasterViewIfExistsForFilter(filter);
    if (v != null) {
      v.addEventListener(type, filter, listener);
    } else {
      _newQueries
          .putIfAbsent(filter, () => EventTarget())
          .addEventListener(type, listener);
    }
  }

  MasterView? getMasterViewIfExistsForFilter(QueryFilter filter) {
    // first check if filter already in one of the master views
    for (var v in views.values) {
      if (v.masterFilter == filter || v.observers.containsKey(filter)) {
        return v;
      }
    }

    // secondly, check if filter might be contained by one of the master views
    for (var v in views.values) {
      if (v.contains(filter)) {
        return v;
      }
    }
    return null;
  }

  MasterView getMasterViewForFilter(QueryFilter filter) {
    // first check if filter already in one of the master views
    for (var v in views.values) {
      if (v.masterFilter == filter || v.observers.containsKey(filter)) {
        return v;
      }
    }

    // secondly, check if filter might be contained by one of the master views
    for (var v in views.values) {
      if (v.contains(filter)) {
        return v;
      }
    }

    // lastly, create a new master view
    return createMasterViewForFilter(filter);
  }

  MasterView createMasterViewForFilter(QueryFilter filter) {
    var unlimitedFilter = views.keys.firstWhereOrNull((q) => !q.limits);
    // TODO: do not create new master views when already an unlimited view exists
    assert(views[filter] == null);
    if (unlimitedFilter != null) {
      filter =
          QueryFilter(ordering: filter.ordering as TreeStructuredDataOrdering);
      return views[filter] = views[unlimitedFilter]!.withFilter(filter);
    }

    var serverVersion = persistenceManager
        .serverCache(QuerySpec(path, filter))
        .withFilter(filter);
    var cache = ViewCache(serverVersion, serverVersion);
    // TODO: apply user operations from persistence storage
    return views[filter] = MasterView(filter, debugName: debugName)
      .._data = cache;
  }

  bool _prunable = false;

  /// Removes an event listener for events of [type] and for data filtered by
  /// [filter].
  void removeEventListener(
      String type, QueryFilter filter, EventListener listener) {
    for (var v in views.values) {
      v.removeEventListener(type, filter, listener);
      if (v.observers.isEmpty) _prunable = true;
    }
  }

  /// Applies an operation to the view for [filter] at this [SyncPoint] or all
  /// views when [filter] is `null`.
  void applyOperation(TreeOperation operation, QueryFilter? filter,
      ViewOperationSource source, int? writeId) {
    if (filter == null || filter == const QueryFilter()) {
      if (source == ViewOperationSource.server) {
        if (operation.path.isEmpty) {
          if (views.isNotEmpty &&
              views.values.every((v) => v.masterFilter.limits)) {
            _logger.fine('no filter: upgrade ${views.keys}');
            for (var v in views.values) {
              v.upgrade();
            }
          }
        }
      }
      for (var v in views.values.toList()) {
        var d = v.applyOperation(operation, source, writeId);
        for (var q in d.keys) {
          _newQueries[q] = d[q]!;
        }
      }
    } else {
      var d = views[filter]?.applyOperation(operation, source, writeId);
      if (d != null) {
        for (var q in d.keys) {
          _newQueries[q] = d[q]!;
        }
      }
    }
  }

  void prune() {
    if (!_prunable) return;
    _prunable = false;
    for (var e in views.entries.toList()) {
      var k = e.key;
      var v = e.value;
      if (v.observers.isEmpty &&
          !(k == const QueryFilter() && isCompleteFromParent)) views.remove(k);
    }
  }

  @override
  String toString() => 'SyncPoint[$debugName]';
}

/// Registers listeners for queries
abstract class QueryRegistrar {
  Future<void> register(QuerySpec query, String? hash);

  Future<void> unregister(QuerySpec query);
}

/// This query registrar delegates (un)registrations to another query registrar
/// making sure that registrations and unregistrations for the same query are
/// handled in order and sequentially.
class SequentialQueryRegistrar extends QueryRegistrar {
  final QueryRegistrar delegateTo;

  final Map<QuerySpec, Future<void>> _activeRegistrations = {};

  SequentialQueryRegistrar(this.delegateTo);

  @override
  Future<void> register(QuerySpec query, String? hash) {
    return _activeRegistrations[query] ??= Future(() async {
      try {
        await delegateTo.register(query, hash);
      } catch (e) {
        _activeRegistrations.remove(query); // ignore: unawaited_futures
        rethrow;
      }
    });
  }

  @override
  Future<void> unregister(QuerySpec query) {
    if (!_activeRegistrations.containsKey(query)) return Future.value();
    var f = _activeRegistrations.remove(query);
    return f!.then((_) async {
      await delegateTo.unregister(query);
    });
  }
}

class PersistActiveQueryRegistrar extends QueryRegistrar {
  final PersistenceManager persistenceManager;

  final QueryRegistrar delegateTo;

  PersistActiveQueryRegistrar(this.persistenceManager, this.delegateTo);

  @override
  Future<void> register(QuerySpec query, String? hash) async {
    await delegateTo.register(query, hash);
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryActive(query);
    });
  }

  @override
  Future<void> unregister(QuerySpec query) async {
    await delegateTo.unregister(query);
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryInactive(query);
    });
  }
}

class QueryRegistrarTree {
  final QueryRegistrar queryRegistrar;

  final Map<Path<Name>, Set<QueryFilter>> _activeQueries = {};

  QueryRegistrarTree(this.queryRegistrar);

  void setActiveQueriesOnPath(Path<Name> path, Iterable<QueryFilter> filters,
      String? Function(QueryFilter filter) hashFcn) {
    var activeFilters = _activeQueries.putIfAbsent(path, () => {});

    var filtersToActivate = filters.toSet().difference(activeFilters);

    var filtersToDeactivate = activeFilters.difference(filters.toSet());

    for (var f in filtersToActivate) {
      queryRegistrar.register(QuerySpec(path, f), hashFcn(f));
    }

    for (var f in filtersToDeactivate) {
      queryRegistrar.unregister(QuerySpec(path, f));
    }

    activeFilters =
        activeFilters.union(filtersToActivate).difference(filtersToDeactivate);

    if (activeFilters.isEmpty) {
      _activeQueries.remove(path);
    } else {
      _activeQueries[path] = activeFilters;
    }
  }
}

class NoopQueryRegistrar extends QueryRegistrar {
  @override
  Future<void> register(QuerySpec query, String? hash) {
    return Future.value();
  }

  @override
  Future<void> unregister(QuerySpec query) {
    return Future.value();
  }
}

class SyncTree {
  final String name;
  final QueryRegistrarTree registrar;

  final ModifiableTreeNode<Name, SyncPoint> root;

  final PersistenceManager persistenceManager;

  SyncTree(String name,
      {QueryRegistrar? queryRegistrar, PersistenceManager? persistenceManager})
      : this._(name,
            queryRegistrar: queryRegistrar,
            persistenceManager: persistenceManager ?? NoopPersistenceManager());

  SyncTree._(this.name,
      {QueryRegistrar? queryRegistrar, required this.persistenceManager})
      : root = ModifiableTreeNode(
            SyncPoint(name, Path(), persistenceManager: persistenceManager)),
        registrar = QueryRegistrarTree(SequentialQueryRegistrar(
            PersistActiveQueryRegistrar(
                persistenceManager, queryRegistrar ?? NoopQueryRegistrar())));

  static ModifiableTreeNode<Name, SyncPoint> _createNode(
      SyncPoint parent, Name childName) {
    return ModifiableTreeNode(parent.child(childName));
  }

  final Set<Path<Name>> _invalidPaths = {};

  DelayedCancellableFuture<void>? _handleInvalidPointsFuture;

  Future<void> waitForAllProcessed() async {
    while (_handleInvalidPointsFuture != null) {
      await _handleInvalidPointsFuture;
    }
  }

  void handleInvalidPaths() {
    for (var path in _invalidPaths) {
      var node = root.subtree(path, _createNode);
      var point = node.value;
      var queries = point.minimalSetOfQueries.toList();

      registrar.setActiveQueriesOnPath(
          path,
          queries,
          (f) => point.views[f]?._data.serverVersion.isComplete == true
              ? point.views[f]!._data.serverVersion.value.hash
              : null);
    }
    _invalidPaths.clear();
    _handleInvalidPointsFuture?.cancel();
    _handleInvalidPointsFuture = null;
  }

  void _invalidate(Path<Name> path) {
    var node = root.subtree(path, _createNode);
    var point = node.value;

    var children = node.children;
    for (var child in children.keys) {
      var v = children[child]!;

      var newIsCompleteFromParent = point.isCompleteForChild(child);

      if (v.value.isCompleteFromParent != newIsCompleteFromParent) {
        v.value.isCompleteFromParent = newIsCompleteFromParent;
        _invalidate(path.child(child));
      }
    }

    _invalidPaths.add(path);

    _handleInvalidPointsFuture ??=
        DelayedCancellableFuture(Duration(milliseconds: 1), handleInvalidPaths);
  }

  Future<void> _doOnSyncPoint(
      Path<Name> path, void Function(SyncPoint point) action) {
    var point = root.subtree(path, _createNode).value;

    action(point);

    _invalidate(path);

    return _handleInvalidPointsFuture!;
  }

  /// Adds an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<void> addEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    return _doOnSyncPoint(path, (point) {
      point.addEventListener(type, filter, listener);
    });
  }

  /// Removes an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<void> removeEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    return _doOnSyncPoint(path, (point) {
      point.removeEventListener(type, filter, listener);
    });
  }

  /// Applies a user overwrite at [path] with [newData]
  void applyUserOverwrite(
      Path<Name> path, TreeStructuredData newData, int writeId) {
    _logger.fine(() => 'apply user overwrite ($writeId) $path -> $newData');
    var operation = TreeOperation.overwrite(path, newData);
    _applyUserOperation(operation, writeId);
  }

  void _applyUserOperation(TreeOperation operation, int writeId) {
    persistenceManager.runInTransaction(() {
      persistenceManager.saveUserOperation(operation, writeId);
      _applyOperationToSyncPoints(
          root, null, operation, ViewOperationSource.user, writeId);
    });
  }

  void applyServerOperation(TreeOperation operation, QuerySpec? query) {
    _logger.fine(() => 'apply server operation $operation');
    persistenceManager.runInTransaction(() {
      query ??= QuerySpec(operation.path);
      persistenceManager.updateServerCache(query!, operation);
      _applyOperationToSyncPoints(
          root, query, operation, ViewOperationSource.server, null);
    });
  }

  void applyListenRevoked(Path<Name> path, QueryFilter? filter) {
    var view = root.subtreeNullable(path)?.value.views.remove(filter);
    if (view == null) return;
    for (var t in view.observers.values) {
      t.dispatchEvent(CancelEvent(
          FirebaseDatabaseException.permissionDenied()
              .replace(message: 'Access to ${path.join('/')} denied'),
          null));
    } // TODO is this always because of permission denied?
    view.observers.clear();
  }

  /// Applies a user merge at [path] with [changedChildren]
  void applyUserMerge(Path<Name> path,
      Map<Path<Name>, TreeStructuredData> changedChildren, int writeId) {
    _logger.fine(() => 'apply user merge ($writeId) $path -> $changedChildren');
    var operation = TreeOperation.merge(path, changedChildren);
    _applyUserOperation(operation, writeId);
  }

  /// Helper function to recursively apply an operation to a node in the
  /// sync tree and all the relevant descendants.
  void _applyOperationToSyncPoints(
      ModifiableTreeNode<Name, SyncPoint>? tree,
      QuerySpec? query,
      TreeOperation? operation,
      ViewOperationSource type,
      int? writeId,
      [Path<Name>? path]) {
    if (tree == null || operation == null) return;
    path ??= Path();
    var filter = query?.path == path ? query?.params : null;
    _doOnSyncPoint(path,
        (point) => point.applyOperation(operation, filter, type, writeId));
    if (operation.path.isEmpty) {
      for (var k in tree.children.keys) {
        var childOp = operation.operationForChild(k);
        if (childOp == null) continue;
        if (filter != null &&
            (childOp.nodeOperation is Overwrite) &&
            (childOp.nodeOperation as Overwrite).value.isNil &&
            tree.value.views[filter] != null &&
            !tree.value.views[filter]!.isCompleteForChild(k)) {
          continue;
        }
        _applyOperationToSyncPoints(
            tree.children[k], null, childOp, type, writeId, path.child(k));
      }
      return;
    }
    var child = operation.path.first;
    _applyOperationToSyncPoints(tree.children[child], query,
        operation.operationForChild(child), type, writeId, path.child(child));
  }

  void applyAck(Path<Name> path, int writeId, bool success) {
    _logger.fine(() => 'apply ack ($writeId) $path -> $success');
    var operation = TreeOperation.ack(path, success);
    persistenceManager.runInTransaction(() {
      persistenceManager.removeUserOperation(writeId);
      _applyOperationToSyncPoints(
          root, null, operation, ViewOperationSource.ack, writeId);
    });
  }

  void destroy() {
    _handleInvalidPointsFuture?.cancel();
    root.forEachNode((key, value) {
      for (var v in value.views.values) {
        for (var o in v.observers.values.toList()) {
          o.dispatchEvent(CancelEvent(null, null));
        }
        v.observers.clear();
      }
      for (var o in value._newQueries.values) {
        o.dispatchEvent(CancelEvent(null, null));
      }
      value._newQueries.clear();
    });
  }
}

class DelayedCancellableFuture<T> extends DelegatingFuture<T> {
  final void Function() cancel;

  DelayedCancellableFuture._(Future<T> future, this.cancel) : super(future);
  factory DelayedCancellableFuture(
      Duration duration, FutureOr<T> Function() computation) {
    var c = Completer<T>();
    var t = Timer(duration, () {
      c.complete(Future(computation));
    });

    return DelayedCancellableFuture._(c.future, () {
      t.cancel();
    });
  }
}
