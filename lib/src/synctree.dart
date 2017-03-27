// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'event.dart';
import 'data_observer.dart';
import 'treestructureddata.dart';
import 'view.dart';
import 'operations/tree.dart';
import 'package:sortedmap/sortedmap.dart';
import 'tree.dart';
import 'repo.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'connection.dart';

final _logger = new Logger("firebase-synctree");

class MasterView {
  QueryFilter masterFilter;

  void upgrade() {
    masterFilter = new QueryFilter(ordering: masterFilter.ordering);
    _data = _data.withFilter(masterFilter);
  }

  ViewCache _data;

  ViewCache get data => _data;

  final Map<QueryFilter,EventTarget> observers = {};

  MasterView(this.masterFilter) : _data = new ViewCache(
    new IncompleteData(new TreeStructuredData(filter: masterFilter)),
    new IncompleteData(new TreeStructuredData(filter: masterFilter))
  ) {
    assert(masterFilter!=null);
  }

  MasterView withFilter(QueryFilter filter) => new MasterView(filter)
      .._data = _data.withFilter(filter);

  bool contains(QueryFilter f) {
    if (f==masterFilter) return true;
    if (f.orderBy!=masterFilter.orderBy) return false;
    if (!masterFilter.limits) return true;
    return _data.localVersion.value.children.filteredMapView(
      start: f.validInterval.start, end: f.validInterval.end, limit: f.limit,
      reversed: f.reversed).isComplete;
  }

  bool isCompleteForChild(Name child) {
    var l = _data.localVersion;
    if (!l.isComplete) return true;
    if (!masterFilter.limits) return true;
    if (l.value.children.containsKey(child)) return true;
    if (masterFilter.ordering is KeyOrdering) {
      if (l.value.children.completeInterval.containsPoint(masterFilter.ordering.mapKeyValue(child, null)))
        return true;
    }
    return false;
  }

  /// Adds the event listener only when the filter is contained by the master
  /// filter.
  ///
  /// Returns true when the listener was added.
  bool addEventListener(String type, QueryFilter filter, EventListener listener) {
    if (!contains(filter)) return false;
    observers.putIfAbsent(filter,()=>new EventTarget()).addEventListener(type,listener);

    var events = const TreeEventGenerator().generateEvents(type, new IncompleteData(new TreeStructuredData()), _data.valueForFilter(filter));
    events.forEach((e)=>observers[filter].dispatchEvent(e));
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
  Map<QueryFilter,EventTarget> applyOperation(Operation operation, ViewOperationSource source, int writeId) {
    var oldData = _data;
    _data = _data.applyOperation(operation, source, writeId);

    var out = <QueryFilter,EventTarget>{};
    for (var q in observers.keys.toList()) {
      if (!contains(q)) {
        out[q] = observers.remove(q);
      }
    }

    for (var q in observers.keys) {
      var t = observers[q];

      var oldValue = oldData.valueForFilter(q);
      var newValue = _data.valueForFilter(q);

      t.eventTypesWithRegistrations
          .expand((t) => const TreeEventGenerator().generateEvents(t, oldValue, newValue))
          .forEach(t.dispatchEvent);
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

  bool get isCompleteFromParent => _isCompleteFromParent;

  set isCompleteFromParent(bool v) {
    _isCompleteFromParent = v;
    if (_isCompleteFromParent) {
      views.putIfAbsent(new QueryFilter(), ()=>new MasterView(new QueryFilter()));
    }
  }

  SyncPoint(this.name, [ViewCache data]) {
    if (data==null) return;
    var q = new QueryFilter();
    views[q] = new MasterView(q).._data = data;
  }

  SyncPoint child(Name child) {
    var p = new SyncPoint("$name/$child", viewCacheForChild(child));
    p.isCompleteFromParent = isCompleteForChild(child);
    return p;
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
    return views.values.any((m)=>m.isCompleteForChild(child));
  }

  Iterable<QueryFilter> get minimalSetOfQueries sync* {
    if (isCompleteFromParent) return;
    prune();
    var queries = views.keys;
    if (queries.any((q)=>!q.limits)) {
      yield new QueryFilter();
    } else {
      yield* queries;
    }
  }

  TreeStructuredData valueForFilter(QueryFilter filter) {
    return views.values.firstWhere((v)=>v.contains(filter), orElse: ()=>null)
        ?._data?.valueForFilter(filter)?.value ?? new TreeStructuredData();
  }

  /// Adds an event listener for events of [type] and for data filtered by
  /// [filter].
  void addEventListener(String type,
      QueryFilter filter, EventListener listener) {
    if (views.values.any((m)=>m.addEventListener(type, filter, listener)))
      return;

    createMasterViewForFilter(filter).addEventListener(type, filter, listener);
  }

  MasterView createMasterViewForFilter(QueryFilter filter) {
    filter ??= new QueryFilter();
    var unlimitedFilter = views.keys.firstWhere((q)=>!q.limits, orElse: ()=>null);
    if (unlimitedFilter!=null) {
      filter = new QueryFilter(ordering: filter.ordering);
      return views[filter] = views[unlimitedFilter].withFilter(filter);
    }
    return views[filter] = new MasterView(filter);
  }

  /// Removes an event listener for events of [type] and for data filtered by
  /// [filter].
  void removeEventListener(String type, Filter filter, EventListener listener) {
    views.values.forEach((v)=>v.removeEventListener(type, filter, listener));
  }

  /// Applies an operation to the view for [filter] at this [SyncPoint] or all
  /// views when [filter] is [null].
  void applyOperation(TreeOperation operation, Filter filter,
      ViewOperationSource source, int writeId) {
    if (filter == null||isCompleteFromParent) {
      if (source==ViewOperationSource.server) {
        if (operation.path.isEmpty) {
          if (views.isNotEmpty&&views.values.every((v)=>v.masterFilter.limits)) {
            _logger.fine("no filter: upgrade ${views.keys}");
            views.values.forEach((v)=>v.upgrade());
          }
        }
      }
      for (var v in views.values.toList()) {
        var d = v.applyOperation(operation,source,writeId);
        for (var q in d.keys) {
          createMasterViewForFilter(q).observers[q] = d[q];
        }
      }
    } else {
      var d = views[filter]?.applyOperation(operation,source,writeId);
      if (d!=null) {
        for (var q in d.keys) {
          createMasterViewForFilter(q).observers[q] = d[q];
        }
      }
    }
  }

  void prune() {
    for (var k in views.keys.toList()) {
      if (views[k].observers.isEmpty&&!(k==new QueryFilter()&&isCompleteFromParent)) views.remove(k);
    }
  }

  @override
  String toString() => "SyncPoint[$name]";
}

abstract class RemoteListenerRegistrar {
  final TreeNode<Name,Map<QueryFilter,Future<Null>>> _queries = new TreeNode({});

  Future<Null> registerAll(Path<Name> path, Iterable<QueryFilter> filters, String hashFcn(QueryFilter filter)) async {
    var node = _queries.subtree(path, (parent,name)=>new TreeNode(<QueryFilter,Future<Null>>{}));
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
    var node = _queries.subtree(path, (parent,name)=>new TreeNode(<QueryFilter,Future<Null>>{}));
    return node.value.putIfAbsent(filter, () async {
      try {
        await remoteRegister(path, filter, hash);
      } catch (e) {
        node.value.remove(filter); // ignore: unawaited_futures
        rethrow;
      }
    });
  }

  Future<Null> remoteRegister(Path<Name> path, QueryFilter filter, String hash);
  Future<Null> remoteUnregister(Path<Name> path, QueryFilter filter);

  Future<Null> unregister(Path<Name> path, QueryFilter filter) async {
    var node = _queries.subtree(path, (parent,name)=>new TreeNode(<QueryFilter,Future<Null>>{}));
    if (!node.value.containsKey(filter)) return;
    node.value.remove(filter); // ignore: unawaited_futures
    await remoteUnregister(path, filter);
  }

}


class SyncTree {
  final String name;
  final RemoteListenerRegistrar registrar;

  final TreeNode<Name, SyncPoint> root;

  SyncTree(this.name, this.registrar) : root = new TreeNode(new SyncPoint(name));

  static TreeNode<Name, SyncPoint> _createNode(SyncPoint parent, Name childName) {
    return new TreeNode(parent?.child(childName));
  }

  final Map<SyncPoint,Future<Null>> _invalidPoints = {};

  Future<Null> _invalidate(Path<Name> path) {
    var node = root.subtree(path, _createNode);
    var point = node.value;

    var children = node.children;
    for (var child in children.keys) {
      var v = children[child];


      v.value.isCompleteFromParent = point.isCompleteForChild(child);

      _invalidate(path.child(child));
    }

    return _invalidPoints.putIfAbsent(point, ()=>new Future<Null>.microtask(() {
      _invalidPoints.remove(point);
      registrar.registerAll(path, point.minimalSetOfQueries,
              (f)=>point.views[f]?._data?.localVersion?.isComplete==true ? point.views[f]._data.localVersion.value.hash : null)
          .catchError((e) {
        if (e.code == "permission_denied") {
          point.views.values.expand((v)=>v.observers.values)
              .forEach((t)=>t.dispatchEvent(new Event("cancel")));
          point.views.clear();
        } else {
          throw e;
        }
      }, test: (e)=>e is ServerError);
    }));

  }

  Future<Null> _doOnSyncPoint(Path<Name> path, void action(SyncPoint point)) {
    var point = root.subtree(path, _createNode).value;

    action(point);

    return _invalidate(path);/*_invalidPoints.putIfAbsent(point, ()=>new Future<Null>.microtask(() {
      _invalidPoints.remove(point);
      registrar.registerAll(path, point.minimalSetOfQueries,
              (f)=>point.views[f]?._data?.localVersion?.isComplete==true ? point.views[f]._data.localVersion.value.hash : null);
    }));*/

  }

  /// Adds an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<Null> addEventListener(String type, Path<Name> path,
      Filter<Name, TreeStructuredData> filter, EventListener listener) {
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
    var operation = new TreeOperation.overwrite(path, newData);
    _applyOperationToSyncPoints(
        root, null, operation, ViewOperationSource.user, writeId);
  }

  void applyServerOperation(TreeOperation operation, Filter filter) {
    _applyOperationToSyncPoints(
        root, filter, operation, ViewOperationSource.server, null);
  }

  void applyListenRevoked(Path<Name> path, Filter filter) {
    root.subtree(path).value.views.remove(filter).observers.values
        .forEach((t)=>t.dispatchEvent(new Event("cancel")));
  }

  /// Applies a user merge at [path] with [changedChildren]
  void applyUserMerge(Path<Name> path,
      Map<Name, TreeStructuredData> changedChildren, int writeId) {
    var operation = new TreeOperation.merge(path, changedChildren);
    _applyOperationToSyncPoints(
        root, null, operation, ViewOperationSource.user, writeId);
  }

  /// Helper function to recursively apply an operation to a node in the
  /// sync tree and all the relevant descendants.
  void _applyOperationToSyncPoints(
      TreeNode<Name, SyncPoint> tree,
      Filter filter,
      TreeOperation operation,
      ViewOperationSource type,
      int writeId, [Path<Name> path]) {
    if (tree == null||operation==null) return;
    path ??= new Path();
    _doOnSyncPoint(path, (point)=>point.applyOperation(operation, filter, type, writeId));
    if (operation.path.isEmpty) {
      for (var k in tree.children.keys) {
        var childOp = operation.operationForChild(k);
        if (filter!=null&&(childOp.nodeOperation is Overwrite)&&(childOp.nodeOperation as Overwrite).value.isNil)
          continue;
        _applyOperationToSyncPoints(tree.children[k], null,
            operation.operationForChild(k), type, writeId, path.child(k));
      }
      return;
    }
    var child = operation.path.first;
    _applyOperationToSyncPoints(tree.children[child], filter,
        operation.operationForChild(child), type, writeId, path.child(child));
  }

  void applyAck(Path<Name> path, int writeId, bool success) {
    var operation = new TreeOperation.ack(path, success);
    _applyOperationToSyncPoints(
        root, null, operation, ViewOperationSource.ack, writeId);
  }
}



