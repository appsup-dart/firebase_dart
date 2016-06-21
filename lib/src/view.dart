// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'data_observer.dart';
import 'event.dart';
import 'tree.dart';
import 'package:sortedmap/sortedmap.dart';

class ViewCache<T> {
  T localVersion;
  T serverVersion;

  SortedMap<int, Operation<T>> pendingOperations;

  ViewCache(this.localVersion, this.serverVersion, [this.pendingOperations]) {
    pendingOperations ??= new SortedMap();
  }

  void recalcLocalVersion() {
    localVersion = pendingOperations.values
        .fold/*<T>*/(serverVersion, (T v, o) => o.apply(v));
  }

  ViewCache<T> updateServerVersion(T newValue) {
    return new ViewCache(localVersion, newValue, pendingOperations)
      ..recalcLocalVersion();
  }

  ViewCache<T> addOperation(int writeId, Operation<T> op) {
    return new ViewCache(op.apply(localVersion), serverVersion,
        pendingOperations.clone()..[writeId] = op);
  }

  ViewCache<T> removeOperation(int writeId, bool recalc) {
    var viewCache = new ViewCache<T>(localVersion, serverVersion,
        pendingOperations.clone()..remove(writeId));
    if (recalc) viewCache.recalcLocalVersion();
    return viewCache;
  }
}

class View<T> extends DataObserver<ViewCache<T>> {
  View(T initialVersion, EventGenerator<ViewCache<T>> eventGenerator)
      : super(new ViewCache(initialVersion, initialVersion), eventGenerator);

  @override
  String toString() => "View[$hashCode]";
}

class ViewEventGenerator<T> extends EventGenerator<ViewCache<T>> {
  final EventGenerator<T> baseEventGenerator;

  const ViewEventGenerator(this.baseEventGenerator);

  @override
  Iterable<Event> generateEvents(
      String eventType,
      IncompleteData<ViewCache<T>> oldValue,
      IncompleteData<ViewCache<T>> newValue) {
    return baseEventGenerator.generateEvents(
        eventType,
        oldValue.childData/*<T>*/(
            ViewOperationSource.user, oldValue.value?.localVersion),
        newValue.childData/*<T>*/(
            ViewOperationSource.user, newValue.value.localVersion));
  }
}

enum ViewOperationSource { user, server, ack }

abstract class Ack {
  bool get success;
}

class ViewOperation<T> extends Operation<ViewCache<T>> {
  final Operation<T> dataOperation;
  final ViewOperationSource source;
  final int writeId;

  ViewOperation(this.source, this.dataOperation, this.writeId);

  @override
  ViewCache<T> apply(ViewCache<T> value) {
    switch (source) {
      case ViewOperationSource.user:
        return value.addOperation(writeId, dataOperation);
      case ViewOperationSource.ack:
        return value.removeOperation(writeId, !(dataOperation as Ack).success);
      case ViewOperationSource.server:
        var result = dataOperation.apply(value.serverVersion);
        return value.updateServerVersion(result);
      default:
        throw new Exception("SHOULD NEVER HAPPEN");
    }
  }

  @override
  Iterable<Path> get completesPaths => dataOperation.completesPaths
      .expand/*<Path>*/((p) => source == ViewOperationSource.user
          ? [
              new Path.from(<dynamic>[source]..addAll(p))
            ]
          : [
              new Path.from(<dynamic>[ViewOperationSource.server]..addAll(p)),
              new Path.from(<dynamic>[ViewOperationSource.user]..addAll(p))
            ]);
}
