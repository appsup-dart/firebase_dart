// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:firebase_dart/database.dart' show FirebaseDatabaseException;
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
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

enum QueryRegistrationState implements Comparable<QueryRegistrationState> {
  registering(3),
  registered(4),
  unregistering(2),
  unregistered(1);

  final int order;

  const QueryRegistrationState(this.order);

  @override
  int compareTo(QueryRegistrationState other) {
    return order.compareTo(other.order);
  }
}

class MasterView {
  QueryFilter masterFilter;

  final String? debugName;

  ViewCache _data;

  QueryRegistrationState _state = QueryRegistrationState.unregistered;

  QueryRegistrationState? _parentState;

  QueryRegistrationState? _unlimitingSiblingState;

  QueryRegistrationState get state => _state;

  final bool persistenceEnabled;

  set state(QueryRegistrationState v) {
    if (_state == v) return;

    _state = v;
    for (var q in observers.keys) {
      var t = observers[q]!;

      var newValue = _valueForFilter(q);
      t.notifyDataChanged(newValue);
    }
  }

  QueryRegistrationState get effectiveState {
    var states = [
      if (_parentState != null) _parentState!,
      if (_unlimitingSiblingState != null) _unlimitingSiblingState!,
      _state,
    ];
    return states.reduce((a, b) => a.compareTo(b) > 0 ? a : b);
  }

  bool get isInSync => effectiveState == QueryRegistrationState.registered;

  final Map<QueryFilter, EventTarget> observers = {};

  MasterView(this.masterFilter,
      {this.debugName, required this.persistenceEnabled})
      : _data = ViewCache(IncompleteData.empty(masterFilter),
            IncompleteData.empty(masterFilter));

  MasterView withFilter(QueryFilter filter) => MasterView(filter,
      debugName: debugName, persistenceEnabled: persistenceEnabled)
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
    if (!masterFilter.limits) return true;
    if (!f.limits) return false;
    if (f.orderBy != masterFilter.orderBy) return false;
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
        .putIfAbsent(filter, () => EventTarget())
        .addEventListener(type, listener, _valueForFilter(filter));

    return true;
  }

  void adoptEventTarget(QueryFilter filter, EventTarget target) {
    assert(observers[filter] == null);
    observers[filter] = target;
    target.notifyDataChanged(_valueForFilter(filter));
  }

  /// Removes the event listener.
  ///
  /// Returns true when this operation removed the last listener for the filter.
  bool removeEventListener(
      String type, QueryFilter filter, EventListener listener) {
    var target = observers[filter];
    if (target == null) return false;
    if (!target.hasEventRegistrations) return false;
    target.removeEventListener(type, listener);
    return !target.hasEventRegistrations;
  }

  /// Removes all observers that do not have any listeners since [from].
  ///
  /// Returns the new [DateTime] when the last listener was removed.
  DateTime? pruneObservers(DateTime from) {
    DateTime? next;
    for (var e in observers.entries.toList()) {
      var target = e.value;
      var emptySince = target.emptyListenersSince;
      if (emptySince == null) continue;

      if (!emptySince.isAfter(from)) {
        observers.remove(e.key);
      } else if (next == null || emptySince.isBefore(next)) {
        next = emptySince;
      }
    }
    return next;
  }

  /// Applies an operation.
  ///
  /// Removes and returns queries that are no longer contained by this master
  /// view.
  Map<QueryFilter, EventTarget> applyOperation(
      Operation operation, ViewOperationSource source, int? writeId) {
    var localVersionChanged = false;
    if (source == ViewOperationSource.ack &&
        (operation as Ack).success &&
        effectiveState == QueryRegistrationState.unregistered) {
      // The query is not registered, so we probably did not receive an updated value for the operation.
      // As the operation was successful, we will apply it to the current view we have of the server.
      // If the server value is different, we will receive the correct value when the query is registered.
      // We cannot do this if the state is registering or unregistering, as we cannot be sure wether or not we already received the updated value and therefore cannot assume we will receive a correction later.
      // TODO: this does not update the persistent storage
      var operation = _data.pendingOperations[writeId];
      if (operation != null) {
        final result =
            _data.applyOperation(operation, ViewOperationSource.server, null);
        _data = result.viewCache;
        localVersionChanged = localVersionChanged || result.localVersionChanged;
      }
    }
    final result = _data.applyOperation(operation, source, writeId);
    _data = result.viewCache;
    localVersionChanged = localVersionChanged || result.localVersionChanged;

    if (!localVersionChanged) {
      return {};
    }

    var out = <QueryFilter, EventTarget>{};
    for (var q in observers.keys.toList()) {
      if (!contains(q)) {
        out[q] = observers.remove(q)!;
      }
    }

    for (var q in observers.keys) {
      var t = observers[q]!;

      var newValue = _valueForFilter(q);
      t.notifyDataChanged(newValue);
    }
    return out;
  }

  IncompleteData _valueForFilter(QueryFilter filter) {
    if (!persistenceEnabled && !isInSync) {
      return IncompleteData.empty();
    }
    return _data.valueForFilter(filter);
  }
}

/// Represents a remote resource and holds local (partial) views and local
/// changes of its value.
class SyncPoint {
  final String debugName;

  final Map<QueryFilter, MasterView> views = {};

  QueryRegistrationState? _parentState;

  final PersistenceManager persistenceManager;

  final Path<Name> path;

  final Map<QueryFilter, EventTarget> _newQueries = {};

  /// User operations that are not yet acknowledged by the server
  final SortedMap<int, TreeOperation> pendingOperations = SortedMap();

  SyncPoint(this.debugName, this.path,
      {ViewCache? data, required this.persistenceManager}) {
    if (data == null) return;
    var q = QueryFilter();
    views[q] = MasterView(q,
        debugName: debugName, persistenceEnabled: persistenceManager.isEnabled)
      .._data = data;
  }

  SyncPoint child(Name child) {
    var p = SyncPoint('$debugName/$child', path.child(child),
        data: viewCacheForChild(child), persistenceManager: persistenceManager);
    p.parentState = registrationStateForChild(child);
    return p;
  }

  bool get isCompleteFromParent => _parentState != null;

  set parentState(QueryRegistrationState? v) {
    if (_parentState == v) return;
    var wasComplete = isCompleteFromParent;

    _parentState = v;
    if (wasComplete != isCompleteFromParent) {
      if (isCompleteFromParent) {
        views.putIfAbsent(const QueryFilter(),
            () => createMasterViewForFilter(const QueryFilter()));
      } else {
        var defView = views[const QueryFilter()]!;
        if (!defView.observers.containsKey(const QueryFilter())) {
          views.remove(const QueryFilter());
          for (var v in views.values) {
            v._unlimitingSiblingState = null;
          }
          for (var k in defView.observers.keys.toList()) {
            var view = getMasterViewForFilter(k);
            view.adoptEventTarget(k, defView.observers.remove(k)!);
          }
        }
      }
    }
    for (var v in views.values) {
      v._parentState = _parentState;
    }
  }

  ViewCache? viewCacheForChild(Name child) {
    for (var m in views.values) {
      if (m.isCompleteForChild(child)) return m._data.child(child);
    }
    return null;
  }

  QueryRegistrationState? registrationStateForChild(Name child) {
    if (_parentState != null) return _parentState!;
    return views.values.fold(null, (s, v) {
      if (s == null || s.compareTo(v._state) < 0) {
        if (v.isCompleteForChild(child)) {
          return v._state;
        }
      }
      return s;
    });
  }

  Iterable<QueryFilter> get minimalSetOfQueries {
    processNewQueries();
    if (isCompleteFromParent) return const [];
    var queries = views.keys.where((k) => views[k]!.observers.isNotEmpty);
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
          .addEventListener(type, listener, IncompleteData.empty());
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
    return getMasterViewIfExistsForFilter(filter) ??
        createMasterViewForFilter(filter);
  }

  MasterView createMasterViewForFilter(QueryFilter filter) {
    if (filter != const QueryFilter() && !filter.limits) {
      return createMasterViewForFilter(const QueryFilter());
    }
    if (views[filter] != null) return views[filter]!;

    var unlimitedFilter = views.keys.firstWhereOrNull((q) => !q.limits);
    assert(views[filter] == null);
    if (unlimitedFilter != null) {
      return views[unlimitedFilter]!;
    }

    var serverVersion = persistenceManager
        .serverCache(QuerySpec(path, filter))
        .withFilter(filter);
    var cache = ViewCache(serverVersion, serverVersion);
    for (var op in pendingOperations.entries) {
      cache = cache
          .applyOperation(op.value, ViewOperationSource.user, op.key)
          .viewCache;
    }
    // TODO: apply user operations from persistence storage
    return views[filter] = MasterView(filter,
        debugName: debugName, persistenceEnabled: persistenceManager.isEnabled)
      .._data = cache;
  }

  /// Removes an event listener for events of [type] and for data filtered by
  /// [filter].
  ///
  /// Returns true when this operation removed the last listener for the filter.
  bool removeEventListener(
      String type, QueryFilter filter, EventListener listener) {
    var isEmpty = false;
    for (var v in views.values) {
      isEmpty = isEmpty || v.removeEventListener(type, filter, listener);
    }
    return isEmpty;
  }

  /// Applies an operation to the view for [filter] at this [SyncPoint] or all
  /// views when [filter] is `null`.
  ///
  /// Returns true when the operation was applied to at least one view.
  bool applyOperation(TreeOperation operation, QueryFilter? filter,
      ViewOperationSource source, int? writeId) {
    if (source == ViewOperationSource.user) {
      pendingOperations[writeId!] = operation;
    } else if (source == ViewOperationSource.ack) {
      pendingOperations.remove(writeId);
    }
    if (filter == null || filter == const QueryFilter()) {
      if (views.isEmpty) return false;
      if (source == ViewOperationSource.server) {
        if (operation.mayUpgrade && operation.path.isEmpty) {
          if (views.isNotEmpty &&
              views.values.every((v) => v.masterFilter.limits)) {
            _logger.fine('no filter: upgrade $debugName ${views.keys}');

            // one of the queries uses a not defined index, so we received the full content
            // we will only know which query should become the master filter after
            // a `no_index` warning is received and the applyUpgrade is called
            // so we will upgrade all queries here and adopt all event targets
            // once we know the master filter.
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
      return true;
    } else {
      var view = views[filter];
      if (view == null) return false;
      var d = view.applyOperation(operation, source, writeId);
      for (var q in d.keys) {
        _newQueries[q] = d[q]!;
      }
      return true;
    }
  }

  @override
  String toString() => 'SyncPoint[$debugName]';

  bool applyUpgrade(QueryFilter filter) {
    var masterView = views[filter];
    if (masterView == null) return false;

    var appliedOnViews = false;
    for (var v in views.values) {
      if (v == masterView) continue;
      if (v.masterFilter == const QueryFilter()) continue;

      appliedOnViews = true;
      for (var e in v.observers.entries) {
        masterView.adoptEventTarget(e.key, e.value);
      }
    }
    views.removeWhere((k, v) => k != const QueryFilter() && v != masterView);
    return appliedOnViews;
  }

  /// Removes all observers that do not have any listeners since [from].
  ///
  /// Returns the new [DateTime] when the last listener was removed.
  DateTime? pruneObservers(DateTime from) {
    DateTime? next;
    for (var v in views.values) {
      var emptySince = v.pruneObservers(from);
      if (emptySince == null) continue;
      if (next == null || emptySince.isBefore(next)) {
        next = emptySince;
      }
    }
    return next;
  }
}

/// Registers listeners for queries
abstract class QueryRegistrar {
  /// Registers a listener for [query] with the given [hash] and [priority].
  ///
  /// The [priority] is used to determine the order in which queries are
  /// registered. Queries with a higher priority are registered first.
  ///
  /// The future completes with true when the query was registered and false
  /// when the registration was cancelled by a later call to [unregister] or the
  /// registration was denied by the server.
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority});

  Future<void> unregister(QuerySpec query);

  void revoke(QuerySpec query);

  Future<void> close();
}

/// This query registrar delegates (un)registrations to another query registrar
/// making sure that registrations and unregistrations for the same query are
/// handled in order and sequentially.
class SequentialQueryRegistrar extends QueryRegistrar {
  final QueryRegistrar delegateTo;

  final Map<QuerySpec, bool> _localStates = {};
  final Map<QuerySpec, Future<bool>> _remoteStates = {};

  /// Immediately sets the local state (i.e. the requested state) to on or off
  /// and then performs the action to set the remote state (i.e. the actual
  /// state).
  ///
  /// Setting the remote state is only performed after all pending actions to
  /// set the remote state have been performed. This ensures that the remote
  /// state is always set in the order of the requests. If the remote state is
  /// already correct, the action is not performed. This can happen when the
  /// state is set to on and then immediately set to off again.
  ///
  /// The future completes with the new remote state.
  Future<bool> _setState(
      QuerySpec query, bool state, Future<void> Function() action) async {
    assert((_localStates[query] ?? false) != state);
    _localStates[query] = state;
    var f = _remoteStates[query] ?? Future.value(false);
    _remoteStates[query] = f.then((v) async {
      if (_localStates[query] == v) {
        // The state is already correct, nothing to do
        return v;
      }

      // The state is not correct, perform action
      await action();
      return state;
    });
    await _remoteStates[query];
    // This is the bug fix. We need to wait for the remote state
    // to be updated with the new state, otherwise we might not
    // see it in the next call to _setState.
    return _remoteStates[query]!;
  }

  SequentialQueryRegistrar(this.delegateTo);

  @override
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority}) {
    return _setState(query, true,
        () => delegateTo.register(query, hash: hash, priority: priority));
  }

  @override
  Future<void> unregister(QuerySpec query) {
    return _setState(query, false, () => delegateTo.unregister(query));
  }

  @override
  Future<void> close() {
    return delegateTo.close();
  }

  @override
  void revoke(QuerySpec query) {
    if (_localStates[query] == true) {
      _setState(query, false, () async => delegateTo.revoke(query));
    }
  }
}

class PersistActiveQueryRegistrar extends QueryRegistrar {
  final PersistenceManager persistenceManager;

  final QueryRegistrar delegateTo;

  PersistActiveQueryRegistrar(this.persistenceManager, this.delegateTo);

  @override
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority}) async {
    // first set query active then register as otherwise the tracked query will not be stored as complete
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryActive(query);
    });
    return await delegateTo.register(query, hash: hash, priority: priority);
  }

  @override
  Future<void> unregister(QuerySpec query) async {
    await delegateTo.unregister(query);
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryInactive(query);
    });
  }

  @override
  Future<void> close() {
    return delegateTo.close();
  }

  @override
  void revoke(QuerySpec query) {
    delegateTo.revoke(query);
    persistenceManager.runInTransaction(() {
      persistenceManager.setQueryInactive(query);
    });
  }
}

class Registration {
  final String hash;

  final int priority;

  final Completer<bool> completer = Completer();

  final QuerySpec query;

  Registration(this.query, {required this.hash, required this.priority});
}

class PrioritizedQueryRegistrar extends QueryRegistrar {
  final QueryRegistrar delegateTo;

  final Map<QuerySpec, Registration> pendingRegistrations = {};

  final Map<QuerySpec, Completer<void>> pendingDeregistrations = {};

  Future<void>? _handleFuture;

  bool _isClosed = false;

  PrioritizedQueryRegistrar(this.delegateTo);

  void _handle() {
    const maxOperations = 20;

    // first handle deregistrations as it might happen that there is also a pending registration for the same query
    // in that case the pending registration came from a register call after the unregister call
    if (pendingDeregistrations.isNotEmpty) {
      var queries = pendingDeregistrations.keys.take(maxOperations).toList();
      for (var q in queries) {
        var c = pendingDeregistrations.remove(q)!;

        c.complete(delegateTo.unregister(q));
      }
      return;
    }

    if (pendingRegistrations.isNotEmpty) {
      var registrations = pendingRegistrations.values.toList()
        ..sort((a, b) => -Comparable.compare(a.priority, b.priority));

      for (var r in registrations.take(maxOperations)) {
        pendingRegistrations.remove(r.query);

        r.completer.complete(
            delegateTo.register(r.query, hash: r.hash, priority: r.priority));
      }
    }
  }

  void _scheduleHandle() {
    _handleFuture ??= Future.delayed(const Duration(milliseconds: 4), () {
      if (_handleFuture == null) return;
      _handle();
      _handleFuture = null;
      if (pendingRegistrations.isNotEmpty ||
          pendingDeregistrations.isNotEmpty) {
        _scheduleHandle();
      }
    });
  }

  @override
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority}) {
    assert(!_isClosed);

    // if pendingDerigstration contains query, we don't remove it and add it again to the pendingRegistrations
    // if we would remove it, and not register again, the current value would not be advertised again to the client

    if (pendingRegistrations.containsKey(query)) {
      // this means register was called for the same query twice without an unregister in between
      throw StateError('Query $query registration already in progress');
    }

    var registration = pendingRegistrations[query] =
        Registration(query, priority: priority, hash: hash);

    _scheduleHandle();
    return registration.completer.future;
  }

  @override
  Future<void> unregister(QuerySpec query) {
    assert(!_isClosed);

    var r = pendingRegistrations.remove(query);

    if (r != null) {
      // not yet registered
      r.completer.complete(false);
      return Future.value();
    }

    var c = pendingDeregistrations[query] ??= Completer();
    _scheduleHandle();
    return c.future;
  }

  @override
  Future<void> close() {
    _isClosed = true;
    _handleFuture = null;
    return delegateTo.close();
  }

  @override
  void revoke(QuerySpec query) {
    pendingDeregistrations.remove(query);
    pendingRegistrations.remove(query);
    delegateTo.revoke(query);
  }
}

class QueryRegistrarTree {
  final QueryRegistrar queryRegistrar;

  final Map<Path<Name>, Set<QueryFilter>> _activeQueries = {};

  QueryRegistrarTree(this.queryRegistrar);

  Future<void> close() {
    return queryRegistrar.close();
  }

  void revokeActiveQuery(Path<Name> path, QueryFilter filter) {
    _activeQueries.remove(path);
    queryRegistrar.revoke(QuerySpec(path, filter));
  }

  void setActiveQueriesOnPath(
    Path<Name> path,
    Iterable<QueryFilter> filters, {
    required String Function(QueryFilter filter) hashFcn,
    required int Function(QueryFilter filter) priorityFcn,
    required void Function(QueryFilter filter, QueryRegistrationState state)
        onRegistrationStateChanged,
  }) {
    var activeFilters = _activeQueries.putIfAbsent(path, () => {});

    var filtersToActivate = filters.toSet().difference(activeFilters);

    var filtersToDeactivate = activeFilters.difference(filters.toSet());

    for (var f in filtersToActivate) {
      onRegistrationStateChanged(f, QueryRegistrationState.registering);
      queryRegistrar
          .register(QuerySpec(path, f),
              hash: hashFcn(f), priority: priorityFcn(f))
          .then((v) {
        if (!v) return; // registration was cancelled
        onRegistrationStateChanged(f, QueryRegistrationState.registered);
      });
    }

    for (var f in filtersToDeactivate) {
      onRegistrationStateChanged(f, QueryRegistrationState.unregistering);
      queryRegistrar.unregister(QuerySpec(path, f)).then((v) {
        onRegistrationStateChanged(f, QueryRegistrationState.unregistered);
      });
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
  Future<bool> register(QuerySpec query,
      {String? hash, required int priority}) {
    return Future.value(true);
  }

  @override
  Future<void> unregister(QuerySpec query) {
    return Future.value();
  }

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  void revoke(QuerySpec query) {}
}

class SyncTree {
  final String name;
  final QueryRegistrarTree registrar;

  final ModifiableTreeNode<Name, SyncPoint> root;

  final PersistenceManager persistenceManager;

  bool _isDestroyed = false;

  final Clock _clock = clock;

  SyncTree(String name,
      {QueryRegistrar? queryRegistrar, PersistenceManager? persistenceManager})
      : this._(name,
            queryRegistrar: queryRegistrar,
            persistenceManager: persistenceManager ?? NoopPersistenceManager());

  SyncTree._(this.name,
      {QueryRegistrar? queryRegistrar, required this.persistenceManager})
      : root = ModifiableTreeNode(
            SyncPoint(name, Path(), persistenceManager: persistenceManager)),
        registrar = QueryRegistrarTree(PrioritizedQueryRegistrar(
            SequentialQueryRegistrar(PersistActiveQueryRegistrar(
                persistenceManager, queryRegistrar ?? NoopQueryRegistrar()))));

  static ModifiableTreeNode<Name, SyncPoint> _createNode(
      SyncPoint parent, Name childName) {
    return ModifiableTreeNode(parent.child(childName));
  }

  final Set<Path<Name>> _invalidPaths = {};
  final SortedMap<Path<Name>, DateTime> _pathsWithEmptyObservers = SortedMap(
      Ordering
          .byValue()); // we use a sorted map, so that we can easily find the oldest empty observer in case many listereners are registered and unregistered

  DelayedCancellableFuture<void>? _handleInvalidPointsFuture;

  Timer? _pruneObserversTimer;

  void _pruneObservers() {
    if (_pruneObserversTimer != null) {
      _pruneObserversTimer!.cancel();
      _pruneObserversTimer = null;
    }
    var next = pruneObservers(_clock
        .now()
        .subtract(Repo.databaseConfiguration.keepQueriesSyncedDuration));
    if (next != null) {
      _pruneObserversTimer = Timer(
          next
              .add(Repo.databaseConfiguration.keepQueriesSyncedDuration)
              .difference(_clock.now()),
          _pruneObservers);
    }
  }

  Future<void> waitForAllProcessed() async {
    while (_handleInvalidPointsFuture != null) {
      await _handleInvalidPointsFuture;
    }
  }

  /// Removes all observers that do not have any listeners since [from].
  ///
  /// Returns the new [DateTime] when the last listener was removed.
  DateTime? pruneObservers(DateTime from) {
    assert(!_isDestroyed);

    var entries = _pathsWithEmptyObservers.entries
        .takeWhile((e) => !e.value.isAfter(from))
        .toList();
    for (var e in entries) {
      var path = e.key;

      var node = root.subtree(path, _createNode);
      var point = node.value;
      var emptySince = point.pruneObservers(from);
      if (emptySince == null) {
        _pathsWithEmptyObservers.remove(path);
      } else {
        _pathsWithEmptyObservers[path] = emptySince;
      }
      _invalidate(path);
    }
    return _pathsWithEmptyObservers.values.firstOrNull;
  }

  void applyAckListen(Path<Name> path, QueryFilter filter) {
    if (_isDestroyed) return;
    var node = root.subtree(path, _createNode);
    var point = node.value;
    if (point.views[filter] == null) return;
    applyServerOperation(
        TreeOperation.overwrite(
            path, point.views[filter]!._data.serverVersion.value),
        QuerySpec(path, filter));
  }

  void applyAckUnlisten(Path<Name> path, QueryFilter filter) {
    var node = root.subtree(path, _createNode);
    var point = node.value;
    var v = point.views[filter];
    if (v != null && v.observers.isEmpty) {
      if (!point.isCompleteFromParent || filter != const QueryFilter()) {
        point.views.remove(filter);
        if (filter == const QueryFilter()) {
          for (var v in point.views.values) {
            v._unlimitingSiblingState = null;
          }
        }
      }
    }
  }

  void onRegistrationStateChanged(
      Path<Name> path, QueryFilter filter, QueryRegistrationState state) {
    assert(!_isDestroyed);
    var node = root.subtree(path, _createNode);
    var point = node.value;
    if (point.views[filter]?._state == state) return;

    if (point.views[filter]?.state != QueryRegistrationState.registering &&
        state == QueryRegistrationState.registered) {
      // We received a confirmation that the query is registered, but we already
      // started to unregister it. We keep the current state.
      return;
    }

    if (point.views[filter]?.state != QueryRegistrationState.unregistering &&
        state == QueryRegistrationState.unregistered) {
      // We received a confirmation that the query is unregistered, but we already
      // started to register it. We keep the current state.
      return;
    }

    point.views[filter]?.state = state;
    if (!filter.limits) {
      for (var v in point.views.values) {
        v._unlimitingSiblingState = state;
      }
    }
    switch (state) {
      case QueryRegistrationState.registered:
        applyAckListen(path, filter);
        break;
      case QueryRegistrationState.unregistered:
        applyAckUnlisten(path, filter);
        break;
      case QueryRegistrationState.unregistering:
      case QueryRegistrationState.registering:
        break;
    }
    _invalidate(path, stateChanged: true);
  }

  void handleInvalidPaths() {
    assert(!_isDestroyed);
    var paths = _invalidPaths.toList();
    _invalidPaths.clear();
    for (var path in paths) {
      var node = root.subtree(path, _createNode);
      var point = node.value;
      var queries = point.minimalSetOfQueries.toList();

      registrar.setActiveQueriesOnPath(
        path,
        queries,
        hashFcn: (f) => point.views[f]!._data.serverVersion.value.hash,
        priorityFcn: (f) =>
            point.views[f]?._data.serverVersion.isComplete == true ? 0 : 1,
        onRegistrationStateChanged: (filter, state) {
          if (_isDestroyed) return;
          onRegistrationStateChanged(
            path,
            filter,
            state,
          );
        },
      );
    }
    _handleInvalidPointsFuture?.cancel();
    _handleInvalidPointsFuture = null;
  }

  void _invalidate(Path<Name> path, {bool stateChanged = false}) {
    assert(!_isDestroyed);

    if (stateChanged) {
      var node = root.subtree(path, _createNode);
      var point = node.value;

      var children = node.children;
      for (var e in children.entries) {
        var child = e.key;
        var v = e.value;

        var newStateFromParent = point.registrationStateForChild(child);

        if (v.value._parentState != newStateFromParent) {
          v.value.parentState = newStateFromParent;
          _invalidate(path.child(child), stateChanged: stateChanged);
        }
      }
    }

    _invalidPaths.add(path);

    _handleInvalidPointsFuture ??=
        DelayedCancellableFuture(Duration(milliseconds: 1), handleInvalidPaths);
  }

  Future<void> _doOnSyncPoint(
      Path<Name> path, bool Function(SyncPoint point) action) {
    var point = root.subtree(path, _createNode).value;

    var applied = action(point);

    _invalidate(path, stateChanged: applied);

    return _handleInvalidPointsFuture!;
  }

  TreeStructuredData valueForPathAndFilter(
      Path<Name> path, QueryFilter filter) {
    var node = root.subtree(path, _createNode);
    var point = node.value;
    return point.valueForFilter(filter);
  }

  /// Adds an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<void> addEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    assert(!_isDestroyed);
    return _doOnSyncPoint(path, (point) {
      point.addEventListener(type, filter, listener);
      return false;
    });
  }

  /// Removes an event listener for events of [type] and for data at [path] and
  /// filtered by [filter].
  Future<void> removeEventListener(String type, Path<Name> path,
      QueryFilter filter, EventListener listener) {
    assert(!_isDestroyed);
    return _doOnSyncPoint(path, (point) {
      var isEmpty = point.removeEventListener(type, filter, listener);
      if (isEmpty) {
        _pathsWithEmptyObservers[path] ??= _clock.now();
        _pruneObservers();
      }
      return false;
    });
  }

  /// Applies a user overwrite at [path] with [newData]
  void applyUserOverwrite(
      Path<Name> path, TreeStructuredData newData, int writeId) {
    _logger.fine(() => 'apply user overwrite ($writeId) $path -> $newData');
    var operation = TreeOperation.overwrite(path, newData);
    applyUserOperation(operation, writeId);
  }

  void applyUserOperation(TreeOperation operation, int writeId) {
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
    var point = root.subtreeNullable(path)?.value;
    if (point == null) return;

    filter ??= const QueryFilter();

    var view = point.views[filter];

    if (view == null) return;

    if (!point.isCompleteFromParent || filter != const QueryFilter()) {
      point.views.remove(filter);
    }

    if (filter == const QueryFilter()) {
      for (var v in point.views.values) {
        v._unlimitingSiblingState = null;
      }
    }

    var filtersToRemove = filter.limits
        ? [filter]
        : view.observers.keys.where((v) => !v.limits).toList();

    for (var f in filtersToRemove) {
      var target = view.observers.remove(f);

      target?.dispatchEvent(CancelEvent(
          FirebaseDatabaseException.permissionDenied()
              .replace(message: 'Access to ${path.join('/')} denied'),
          null));

      // TODO is this always because of permission denied?
    }

    point._newQueries.addEntries(view.observers.entries);
    view.observers.clear();

    registrar.revokeActiveQuery(path, filter);

    _invalidate(path, stateChanged: true);
  }

  /// Applies a user merge at [path] with [changedChildren]
  void applyUserMerge(Path<Name> path,
      Map<Path<Name>, TreeStructuredData> changedChildren, int writeId) {
    _logger.fine(() => 'apply user merge ($writeId) $path -> $changedChildren');
    var operation = TreeOperation.merge(path, changedChildren);
    applyUserOperation(operation, writeId);
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
    _isDestroyed = true;
    _handleInvalidPointsFuture?.cancel();
    _pruneObserversTimer?.cancel();
    registrar.close();
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

  void applyUpgrade(Path<Name> path, QueryFilter filter) {
    _logger.fine(() => 'apply upgrade on $path $filter');
    _doOnSyncPoint(path, (point) => point.applyUpgrade(filter));
  }
}
