// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'data_observer.dart';
import 'package:sortedmap/sortedmap.dart';
import 'treestructureddata.dart';
import 'operations/tree.dart';

/// Result of applying an operation to a [ViewCache].
typedef ViewCacheApplyResult = ({
  ViewCache viewCache,
  bool localVersionChanged
});

/// Contains a view of a remote resource
class ViewCache {
  IncompleteData _localVersion;

  /// The current view we have of the server
  final IncompleteData serverVersion;

  /// User operations that are not yet acknowledged by the server
  final SortedMap<int, TreeOperation> pendingOperations;

  ViewCache(this._localVersion, this.serverVersion,
      [SortedMap<int, TreeOperation>? pendingOperations])
      : pendingOperations = pendingOperations ?? SortedMap();

  /// The local version of the data, i.e. the server version with the pending
  /// operations applied to
  IncompleteData get localVersion => _localVersion;

  /// Returns a local version of the data for an alternate filter
  IncompleteData valueForFilter(QueryFilter filter) =>
      localVersion.withFilter(filter);

  /// Returns a view for an alternate filter
  ViewCache withFilter(QueryFilter filter) => ViewCache(
      localVersion.withFilter(filter),
      serverVersion.withFilter(filter),
      SortedMap.from(pendingOperations));

  /// Returns a view for a child
  ViewCache child(Name c) {
    var childPendingOperations = SortedMap<int, TreeOperation>();
    for (var k in pendingOperations.keys) {
      var o = pendingOperations[k]!.operationForChild(c);
      if (o != null) {
        childPendingOperations[k] = o;
      }
    }
    var v = ViewCache(
      localVersion.directChild(c),
      serverVersion.directChild(c),
      childPendingOperations,
    );
    return v;
  }

  /// Recalculates the local version from [serverVersion] and [pendingOperations].
  ///
  /// Returns `true` when [localVersion] changed (not the same instance as before).
  bool recalcLocalVersion() {
    final previous = _localVersion;
    _localVersion = serverVersion;
    for (var op in pendingOperations.values) {
      _applyPendingOperation(op);
    }
    return !identical(_localVersion, previous);
  }

  /// Applies [operation] to the local version.
  ///
  /// Returns `false` when [localVersion] was unchanged.
  bool _applyPendingOperation(Operation operation) {
    // TODO: the operation might influence completeness
    // we ignore this for now and allow some queries to return incorrect intermediate values
    final updated = localVersion.applyOperation(operation as TreeOperation);
    if (identical(updated, localVersion)) return false;
    _localVersion = updated;
    return true;
  }

  /// Updates the server version.
  ViewCacheApplyResult updateServerVersion(IncompleteData newValue) {
    final viewCache = ViewCache(localVersion, newValue, pendingOperations);
    final localVersionChanged = viewCache.recalcLocalVersion();
    return (viewCache: viewCache, localVersionChanged: localVersionChanged);
  }

  /// Add a user operation.
  ///
  /// The operation will be applied to the local version.
  ViewCacheApplyResult addOperation(int writeId, Operation op) {
    final viewCache = ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..[writeId] = op as TreeOperation);
    final localVersionChanged = viewCache._applyPendingOperation(op);
    return (viewCache: viewCache, localVersionChanged: localVersionChanged);
  }

  /// Remove a user operation.
  ///
  /// This will cause the local version to be recalculated.
  ViewCacheApplyResult removeOperation(int writeId) {
    final viewCache = ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..remove(writeId));
    final localVersionChanged = viewCache.recalcLocalVersion();
    return (viewCache: viewCache, localVersionChanged: localVersionChanged);
  }

  /// Applies a user or server operation to this view.
  ViewCacheApplyResult applyOperation(
      Operation operation, ViewOperationSource source, int? writeId) {
    switch (source) {
      case ViewOperationSource.user:
        return addOperation(writeId!, operation);
      case ViewOperationSource.ack:
        return removeOperation(writeId!);
      case ViewOperationSource.server:
        final result = serverVersion.applyOperation(operation as TreeOperation);
        return updateServerVersion(result);
    }
  }
}

enum ViewOperationSource { user, server, ack }
