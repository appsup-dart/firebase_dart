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
    localVersion = pendingOperations.values.fold(serverVersion, (v, o)=>o.apply(v));
  }
  ViewCache<T> updateServerVersion(T newValue) {
    return new ViewCache(localVersion, newValue, pendingOperations)..recalcLocalVersion();
  }
  ViewCache<T> addOperation(int writeId, Operation<T> op) {
    return new ViewCache(
        op.apply(localVersion), serverVersion, pendingOperations.clone()..[writeId] = op
    );
  }

  ViewCache removeOperation(int writeId, bool recalc) {
    var viewCache = new ViewCache(localVersion, serverVersion,
        pendingOperations.clone()..remove(writeId));
    if (recalc) viewCache.recalcLocalVersion();
    return viewCache;
  }
}

class View<T> extends DataObserver<ViewCache<T>> {

  View(T initialVersion, EventGenerator<ViewCache<T>> eventGenerator) :
        super(new ViewCache(initialVersion, initialVersion), eventGenerator);


  toString() => "View[$hashCode]";




}

class ViewEventGenerator<T> extends EventGenerator<ViewCache<T>> {

  final EventGenerator<T> baseEventGenerator;

  const ViewEventGenerator(this.baseEventGenerator);

  @override
  Iterable<Event> generateEvents(String eventType,
      IncompleteData<ViewCache<T>> oldValue,
      IncompleteData<ViewCache<T>> newValue) {
    return baseEventGenerator.generateEvents(eventType,
        oldValue.childData(ViewOperationSource.user, oldValue.value?.localVersion),
        newValue.childData(ViewOperationSource.user, newValue.value.localVersion));
  }
}

enum ViewOperationSource {user, server, ack}

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
    }
  }

  @override
  Iterable<Path> get completesPaths =>
      dataOperation.completesPaths.expand(
          (p)=>source==ViewOperationSource.user ? [new Path.from([source]..addAll(p))] :
  [new Path.from([ViewOperationSource.server]..addAll(p)), new Path.from([ViewOperationSource.user]..addAll(p))]);
}

