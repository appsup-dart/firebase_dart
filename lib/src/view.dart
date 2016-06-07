// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'data_observer.dart';
import 'event.dart';
import 'tree.dart';

class ViewCache<T> {

  T localVersion;
  T serverVersion;

  Iterable<Operation<T>> pendingOperations;

  ViewCache(this.localVersion, this.serverVersion, this.pendingOperations);

  void recalcLocalVersion() {
    localVersion = pendingOperations.fold(serverVersion, (v, o)=>o.apply(v));
  }
  ViewCache<T> updateServerVersion(T newValue) {
    return new ViewCache(localVersion, newValue, pendingOperations)..recalcLocalVersion();
  }
  ViewCache<T> addOperation(Operation<T> op) {
    return new ViewCache(
        op.apply(localVersion), serverVersion, new List.from(pendingOperations)..add(op)
    );
  }
}

class View<T> extends DataObserver<ViewCache<T>> {

  View(T initialVersion, EventGenerator<ViewCache<T>> eventGenerator) :
        super(new ViewCache(initialVersion, initialVersion, []), eventGenerator);


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

enum ViewOperationSource {user, server}


class ViewOperation<T> extends Operation<ViewCache<T>> {

  final Operation<T> dataOperation;
  final ViewOperationSource source;


  ViewOperation(this.source, this.dataOperation);

  @override
  ViewCache<T> apply(ViewCache<T> value) {
    switch (source) {
      case ViewOperationSource.user:
        return value.addOperation(dataOperation);
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

