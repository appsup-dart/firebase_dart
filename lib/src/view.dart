// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'data_observer.dart';
import 'package:sortedmap/sortedmap.dart';
import 'treestructureddata.dart';
import 'operations/tree.dart';

/// Contains a view of a remote resource
class ViewCache {
  IncompleteData localVersion;
  IncompleteData serverVersion;

  SortedMap<int, TreeOperation> pendingOperations;

  ViewCache(this.localVersion, this.serverVersion, [this.pendingOperations]) {
    pendingOperations ??= new SortedMap();
  }

  IncompleteData valueForFilter(Filter<Name,TreeStructuredData> filter) {
    return localVersion.update(localVersion.value.view(
      start: filter.validInterval.start,
      end: filter.validInterval.end,
      limit: filter.limit,
      reversed: filter.reversed));
  }

  ViewCache withFilter(Filter<Name,TreeStructuredData> filter) =>
      new ViewCache(
          localVersion.update(localVersion.value.withFilter(filter)),
          serverVersion.update(serverVersion.value.withFilter(filter)),
          new SortedMap.from(pendingOperations)
      );

  ViewCache child(Name c) {
    var childPendingOperations = new SortedMap();
    for (var k in pendingOperations.keys) {
      var o = pendingOperations[k].operationForChild(c);
      if (o!=null) {
        childPendingOperations[k] = o;
      }
    }
    var v = new ViewCache(
      localVersion.child(c),
      serverVersion.child(c),
      childPendingOperations,
    );
    return v;
  }

  void recalcLocalVersion() {
    localVersion = pendingOperations.values
        .fold<IncompleteData>(serverVersion,
            (IncompleteData v, o) => v.applyOperation(o));
  }

  ViewCache updateServerVersion(IncompleteData newValue) {
    return new ViewCache(localVersion, newValue, pendingOperations)
      ..recalcLocalVersion();
  }

  ViewCache addOperation(int writeId, Operation op) {
    if (op==null) throw new ArgumentError("Trying to add null operation");
    return new ViewCache(localVersion.applyOperation(op), serverVersion,
        pendingOperations.clone()..[writeId] = op);
  }

  ViewCache removeOperation(int writeId, bool recalc) {
    var viewCache = new ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..remove(writeId));
    if (recalc) viewCache.recalcLocalVersion();
    return viewCache;
  }


  ViewCache applyOperation(Operation operation, ViewOperationSource source, int writeId) {
    switch (source) {
      case ViewOperationSource.user:
        return addOperation(writeId, operation);
      case ViewOperationSource.ack:
        return removeOperation(writeId, true); // TODO doesn't need recalculate when no server values?
      case ViewOperationSource.server:
        var result = serverVersion.applyOperation(operation);
        return updateServerVersion(result);
      default:
        throw new Exception("SHOULD NEVER HAPPEN");
    }
  }
}


enum ViewOperationSource { user, server, ack }


