// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'data_observer.dart';
import 'package:sortedmap/sortedmap.dart';
import 'treestructureddata.dart';
import 'operations/tree.dart';

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

  /// Recalculates the local version
  void recalcLocalVersion() {
    _localVersion = serverVersion;
    for (var op in pendingOperations.values) {
      _applyPendingOperation(op);
    }
  }

  void _applyPendingOperation(TreeOperation operation) {
    // TODO: the operation might influence completeness
    // we ignore this for now and allow some queries to return incorrect intermediate values
    _localVersion = localVersion.applyOperation(operation);
  }

  /// Updates the server version
  ViewCache updateServerVersion(IncompleteData newValue) {
    return ViewCache(localVersion, newValue, pendingOperations)
      ..recalcLocalVersion();
  }

  /// Add a user operation
  ///
  /// The operation will be applied to the local version
  ViewCache addOperation(int writeId, Operation op) {
    return ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..[writeId] = op as TreeOperation)
      .._applyPendingOperation(op);
  }

  /// Remove a user operation
  ///
  /// This will cause the local version to be recalculated
  ViewCache removeOperation(int writeId) {
    var viewCache = ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..remove(writeId));
    viewCache.recalcLocalVersion();
    return viewCache;
  }

  /// Applies a user or server operation to this view and returns the updated
  /// view
  ViewCache applyOperation(
      Operation operation, ViewOperationSource source, int? writeId) {
    switch (source) {
      case ViewOperationSource.user:
        return addOperation(writeId!, operation);
      case ViewOperationSource.ack:
        return removeOperation(writeId!);
      case ViewOperationSource.server:
      default:
        var result = serverVersion.applyOperation(operation as TreeOperation);
        return updateServerVersion(result);
    }
  }
}

enum ViewOperationSource { user, server, ack }
