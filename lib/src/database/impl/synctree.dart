// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_dart/database.dart' show FirebaseDatabaseException;
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
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

final _logger = Logger('firebase-synctree');

class MasterView {
  QueryFilter masterFilter;

  ViewCache _data;

  final Map<QueryFilter, EventTarget> observers = {};

  MasterView(this.masterFilter)
      : _data = ViewCache(IncompleteData.empty(masterFilter),
            IncompleteData.empty(masterFilter)),
        assert(masterFilter != null);

  MasterView withFilter(QueryFilter filter) =>
      MasterView(filter).._data = _data.withFilter(filter);

  ViewCache get data => _data;

  void upgrade() {
    masterFilter = QueryFilter(ordering: masterFilter.ordering);
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
    return _data.localVersion.value.children
        .filteredMapView(
            start: f.validInterval.start,
            end: f.validInterval.end,
            limit: f.limit,
            reversed: f.reversed)
        .isComplete;
  }

  bool isCompleteForChild(Name child) {
    var l = _data.localVersion;
    if (!l.isComplete) return true;
    if (!masterFilter.limits) return true;
    if (l.value.children.containsKey(child)) return true;
    if (masterFilter.ordering is KeyOrdering) {
      if (l.value.children.completeInterval
          .containsPoint(masterFilter.ordering.mapKeyValue(child, null))) {
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

  /// Removes the event listener.
  void removeEventListener(String type, Filter filter, EventListener listener) {
    if (!observers.containsKey(filter)) return;
    observers[filter].removeEventListener(type, listener);
    if (!observers[filter].hasEventRegistrations) {
      observers.remove(filter);
    }
  }

  /// Applies an operation.
  ///
  /// Removes and returns queries that are no longer contained by this master
  /// view.
  Map<QueryFilter, EventTarget> applyOperation(
      Operation operation, ViewOperationSource source, int writeId) {
    _data = _data.applyOperation(operation, source, writeId);

    var out = <QueryFilter, EventTarget>{};
    for (var q in observers.keys.toList()) {
      if (!contains(q)) {
        out[q] = observers.remove(q);
      }
    }

    for (var q in observers.keys) {
      var t = observers[q];

      var newValue = _data.valueForFilter(q);
      t.notifyDataChanged(newValue);
    }
    return out;
  }
}

/// Represents a remote resource and holds local (partial) views and local
/// changes of its value.
class SyncPoint {
  final String name;

  final Map<QueryFilter, MasterView> views = {};

  bool _isCompleteFromParent = false;

  final PersistenceManager persistenceManager;

  final Path<Name> path;

  SyncPoint(this.name, this.path, {ViewCache data, this.persistenceManager}) {
    if (data == null) return;
    var q = QueryFilter();
    views[q] = MasterView(q).._data = data;
  }

  SyncPoint child(Name child) {
    var p = SyncPoint('$name/$child', path.child(child),
        data: viewCacheForChild(child), persistenceManager: persistenceManager);
    p.isCompleteFromParent = isCompleteForChild(child);
    return p;
  }

  bool get isCompleteFromParent => _isCompleteFromParent;

  set isCompleteFromParent(bool v) {
    _isCompleteFromParent = v;
    if (_isCompleteFromParent) {
      views.putIfAbsent(QueryFilter(), () => MasterView(QueryFilter()));
    }
  }

  ViewCache viewCacheForChild(Name child) {
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

  final Set<QueryFilter> _lastMinimalSetOfQueries = {};

  Map<QueryFilter, EventTarget> _removeNewQueries() {
    return {
      for (var k in views.keys
          .toList()
          .where((k) => !_lastMinimalSetOfQueries.contains(k)))
        ...views.remove(k).observers
    };
  }

  Iterable<QueryFilter> get minimalSetOfQueries {
    var v = _minimalSetOfQueries.toList();
    _lastMinimalSetOfQueries
      ..clear()
      ..addAll(v);
    return v;
  }

  Iterable<QueryFilter> get _minimalSetOfQueries sync* {
    if (isCompleteFromParent) return;
    prune();
    var queries = views.keys;
    if (queries.any((q) => !q.limits)) {
      yield QueryFilter();
    } else {
      // TODO: move this to a separate class and make it configurable
      var v = <Ordering, Map<QueryFilter, EventTarget>>{};
      _removeNewQueries().forEach((key, value) {
        v.putIfAbsent(key.ordering, () => {})[key] = value;
      });

      for (var o in v.keys) {
        var nonLimitingQueries =
            v[o].keys.where((v) => v.limit == null).toList();

        var intervals = KeyValueIntervalX.unionAll(
            nonLimitingQueries.map((q) => q.validInterval));

        for (var i in intervals) {
          createMasterViewForFilter(QueryFilter(ordering: o, validInterval: i));
        }

        for (var q in v[o].keys.toList()) {
          var view = views.values
              .firstWhere((element) => element.contains(q), orElse: () => null);
          if (view != null) view.observers[q] = v[o].remove(q);
        }

        var forwardLimitingQueries = v[o]
            .keys
            .where((v) => v.limit != null && !v.reversed)
            .toList()
              ..sort((a, b) => Comparable.compare(
                  a.validInterval.start, b.validInterval.start));

        while (forwardLimitingQueries.isNotEmpty) {
          var view = createMasterViewForFilter(forwardLimitingQueries.first);

          for (var q in forwardLimitingQueries.toList()) {
            if (view.contains(q)) {
              forwardLimitingQueries.remove(q);
              view.observers[q] = v[o].remove(q);
            }
          }
        }

        var backwardLimitingQueries = v[o]
            .keys
            .where((v) => v.limit != null && v.reversed)
            .toList()
              ..sort((a, b) => -Comparable.compare(
                  a.validInterval.end, b.validInterval.end));

        if (backwardLimitingQueries.isNotEmpty) {
          var view = createMasterViewForFilter(backwardLimitingQueries.first);

          for (var q in backwardLimitingQueries.toList()) {
            if (view.contains(q)) {
              backwardLimitingQueries.remove(q);
              view.observers[q] = v[o].remove(q);
            }
          }
        }
      }

      yield* views.keys;
    }
  }

  TreeStructuredData valueForFilter(QueryFilter filter) {
    return views.values
            .firstWhere((v) => v.contains(filter), orElse: () => null)
            ?._data
            ?.valueForFilter(filter)
            ?.value ??
        TreeStructuredData();
  }

  /// Adds an event listener for events of [type] and for data filtered by
  /// [filter].
  void addEventListener(
      String type, QueryFilter filter, EventListener listener) {
    if (views.values.any((m) => m.addEventListener(type, filter, listener))) {
      return;
    }

    createMasterViewForFilter(filter).addEventListener(type, filter, listener);
  }

  MasterView createMasterViewForFilter(QueryFilter filter) {
    filter ??= QueryFilter();
    var unlimitedFilter =
        views.keys.firstWhere((q) => !q.limits, orElse: () => null);
    // TODO: do not create new master views when already an unlimited view exists
    if (unlimitedFilter != null) {
      filter = QueryFilter(ordering: filter.ordering);
      return views[filter] = views[unlimitedFilter].withFilter(filter);
    }

    var serverVersion =
        persistenceManager.serverCache(path, filter).withFilter(filter);
    var cache = ViewCache(serverVersion, serverVersion);
    // TODO: apply user operations from persistence storage
    return views[filter] = MasterView(filter).._data = cache;
  }

  /// Removes an event listener for events of [type] and for data filtered by
  /// [filter].
  void removeEventListener(String type, Filter filter, EventListener listener) {
    views.values.forEach((v) => v.removeEventListener(type, filter, listener));
  }

  /// Applies an operation to the view for [filter] at this [SyncPoint] or all
  /// views when [filter] is `null`.
  void applyOperation(TreeOperation operation, Filter filter,
      ViewOperationSource source, int writeId) {
    if (filter == null || isCompleteFromParent) {
      if (source == ViewOperationSource.server) {
        if (operation.path.isEmpty) {
          if (views.isNotEmpty &&
              views.values.every((v) => v.masterFilter.limits)) {
            _logger.fine('no filter: upgrade ${views.keys}');
            views.values.forEach((v) => v.upgrade());
          }
        }
      }
      for (var v in views.values.toList()) {
        var d = v.applyOperation(operation, source, writeId);
        for (var q in d.keys) {
          createMasterViewForFilter(q).observers[q] = d[q];
        }
      }
    } else {
      var d = views[filter]?.applyOperation(operation, source, writeId);
      if (d != null) {
        for (var q in d.keys) {
          createMasterViewForFilter(q).observers[q] = d[q];
        }
      }
    }
  }

  void prune() {
    for (var k in views.keys.toList()) {
      if (views[k].observers.isEmpty &&
          !(k == QueryFilter() && isCompleteFromParent)) views.remove(k);
    }
  }

  @override
  String toString() => 'SyncPoint[$name]';
}

abstract class RemoteListenerRegistrar {
  final TreeNode<Name, Map<QueryFilter, Future<Null>>> _queries = TreeNode({});
  final PersistenceManager persistenceManager;

  RemoteListenerRegistrar(this.persistenceManager);

  factory RemoteListenerRegistrar.fromCallbacks(
      PersistenceManager persistenceManager,
      {RemoteRegister remoteRegister,
      RemoteUnregister remoteUnregister}) = _RemoteListenerRegistrarImpl;

  Future<Null> registerAll(Path<Name> path, Iterable<QueryFilter> filters,
      String Function(QueryFilter filter) hashFcn) async {
    var node = _queries.subtree(
        path, (parent, name) => TreeNode(<QueryFilter, Future<Null>>{}));
    for (var f in filters.toSet()) {
      if (node.value.containsKey(f)) continue;
      var hash = hashFcn(f);
      await register(path, f, hash);
    }
    for (var f in node.value.keys.toSet().difference(filters.toSet())) {
      await unregister(path, f);
    }
  }

  Future<Null> register(Path<Name> path, QueryFilter filter, String hash) {
    var node = _queries.subtree(
        path, (parent, name) => TreeNode(<QueryFilter, Future<Null>>{}));
    return node.value.putIfAbsent(filter, () async {
      try {
        await remoteRegister(path, filter, hash);
        persistenceManager.runInTransaction(() {
          persistenceManager.setQueryActive(path, filter);
        });
      } catch (e) {
        node.value.remove(filter); // ignore: unawaited_futures
        rethrow;
      }
    });
  }

  Future<Null> remoteRegister(Path<Name> path, QueryFilter filter, String hash);

  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter);

  Future<Null> unregister(Path<Name> path, QueryFilter filter) async {
    var node = _queries.subtree(
        path, (parent, name) => TreeNode(<QueryFilter, Future<Null>>{}));
    if (!node.value.containsKey(filter)) return;
    node.value.remove(filter); // ignore: unawaited_futures
    await remoteUnregister(path, filter);
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryInactive(path, filter);
    });
  }
}

typedef RemoteRegister = Future<Null> Function(
    Path<Name> path, QueryFilter filter, String hash);
typedef RemoteUnregister = Future<Null> Function(
    Path<Name> path, QueryFilter filter);

class _RemoteListenerRegistrarImpl extends RemoteListenerRegistrar {
  final RemoteRegister _remoteRegister;
  final RemoteUnregister _remoteUnregister;

  _RemoteListenerRegistrarImpl(PersistenceManager persistenceManager,
      {RemoteRegister remoteRegister, RemoteUnregister remoteUnregister})
      : _remoteRegister = remoteRegister,
        _remoteUnregister = remoteUnregister,
        super(persistenceManager);
  @override
  Future<Null> remoteRegister(
      Path<Name> path, QueryFilter filter, String hash) async {
    if (_remoteRegister == null) return;
    return _remoteRegister(path, filter, hash);
  }

  @override
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter) async {
    if (_remoteUnregister == null) return;
    return _remoteUnregister(path, filter);
  }
}

class SyncTree {
  final String name;
  final RemoteListenerRegistrar registrar;

  final TreeNode<Name, SyncPoint> root;

  final PersistenceManager persistenceManager;

  SyncTree(String name,
      {RemoteRegister remoteRegister,
      RemoteUnregister remoteUnregister,
      PersistenceManager persistenceManager})
      : this._(name,
            remoteRegister: remoteRegister,
            remoteUnregister: remoteUnregister,
            persistenceManager: persistenceManager ?? NoopPersistenceManager());

  SyncTree._(this.name,
      {RemoteRegister remoteRegister,
      RemoteUnregister remoteUnregister,
      @required PersistenceManager persistenceManager})
      : assert(persistenceManager != null),
        root = TreeNode(
            SyncPoint(name, Path(), persistenceManager: persistenceManager)),
        persistenceManager = persistenceManager,
        registrar = RemoteListenerRegistrar.fromCallbacks(persistenceManager,
            remoteRegister: remoteRegister, remoteUnregister: remoteUnregister);

  static TreeNode<Name, SyncPoint> _createNode(
      SyncPoint parent, Name childName) {
    return TreeNode(parent?.child(childName));
  }

  final Map<SyncPoint, Future<Null>> _invalidPoints = {};

  Future<Null> _invalidate(Path<Name> path) {
    var node = root.subtree(path, _createNode);
    var point = node.value;

    var children = node.children;
    for (var child in children.keys) {
      var v = children[child];

      v.value.isCompleteFromParent = point.isCompleteForChild(child);

      _invalidate(path.child(child));
    }

    return _invalidPoints.putIfAbsent(
        point,
        () => Future<Null>.microtask(() {
              _invalidPoints.remove(point);
              registrar
                  .registerAll(
                      path,
                      point.minimalSetOfQueries,
                      (f) => point.views[f]?._data?.serverVersion?.isComplete ==
                              true
                          ? point.views[f]._data.serverVersion.value.hash
                          : null)
                  .catchError((e, tr) {
                if (e is FirebaseDatabaseException &&
                    e.code == 'permission_denied') {
                  point.views.values.expand((v) => v.observers.values).forEach(
                      (t) => t.dispatchEvent(CancelEvent(
                          e.replace(
                              message: 'Access to ${path.join('/')} denied'),
                          tr)));
                  point.views.clear();
                } else {
                  throw e;
                }
              }, test: (e) => e is FirebaseDatabaseException);
            }));
  }

  Future<Null> _doOnSyncPoint(
      Path<Name> path, void Function(SyncPoint point) action) {
    var point = root.subtree(path, _createNode).value;

    action(point);

    return _invalidate(path);
    /*_invalidPoints.putIfAbsent(point, ()=>Future<Null>.microtask(() {
      _invalidPoints.remove(point);
      registrar.registerAll(path, point.minimalSetOfQueries,
              (f)=>point.views[f]?._data?.localVersion?.isComplete==true ? point.views[f]._data.localVersion.value.hash : null);
    }));*/
  }

  /// Adds an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<Null> addEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    return _doOnSyncPoint(path, (point) {
      point.addEventListener(type, filter, listener);
    });
  }

  /// Removes an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<Null> removeEventListener(
      String type, Path<Name> path, Filter filter, EventListener listener) {
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

  void applyServerOperation(TreeOperation operation, Filter filter) {
    _logger.fine(() => 'apply server operation $operation');
    persistenceManager.runInTransaction(() {
      persistenceManager.updateServerCache(operation, filter);
      _applyOperationToSyncPoints(
          root, filter, operation, ViewOperationSource.server, null);
    });
  }

  void applyListenRevoked(Path<Name> path, Filter filter) {
    root.subtree(path).value.views.remove(filter).observers.values.forEach(
        (t) => t.dispatchEvent(CancelEvent(
            FirebaseDatabaseException.permissionDenied()
                .replace(message: 'Access to ${path.join('/')} denied'),
            null))); // TODO is this always because of permission denied?
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
      TreeNode<Name, SyncPoint> tree,
      Filter filter,
      TreeOperation operation,
      ViewOperationSource type,
      int writeId,
      [Path<Name> path]) {
    if (tree == null || operation == null) return;
    path ??= Path();
    _doOnSyncPoint(path,
        (point) => point.applyOperation(operation, filter, type, writeId));
    if (operation.path.isEmpty) {
      for (var k in tree.children.keys) {
        var childOp = operation.operationForChild(k);
        if (childOp == null) continue;
        if (filter != null &&
            (childOp.nodeOperation is Overwrite) &&
            (childOp.nodeOperation as Overwrite).value.isNil) continue;
        _applyOperationToSyncPoints(
            tree.children[k], null, childOp, type, writeId, path.child(k));
      }
      return;
    }
    var child = operation.path.first;
    _applyOperationToSyncPoints(tree.children[child], filter,
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
    root.forEachNode((key, value) {
      for (var v in value.views.values) {
        for (var o in v.observers.values) {
          o.dispatchEvent(CancelEvent(null, null));
        }
      }
    });
  }
}
