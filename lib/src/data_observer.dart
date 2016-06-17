// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'event.dart';
import 'package:collection/collection.dart';
import 'events/value.dart';
import 'tree.dart';

abstract class Operation<T> {

  T apply(T value);

  Iterable<Path> get completesPaths;

}


class IncompleteData<T> {

  final TreeNode<dynamic, bool> _states;
  final T value;

  IncompleteData(this.value, [TreeNode<dynamic, bool> states]) :
        _states = states ?? new TreeNode();


  bool get isComplete => _states.value==true;

  bool isCompleteForPath(Path path) => _isCompleteForPath(_states,path);
  bool isCompleteForChild(Object child) => _isCompleteForPath(_states,new Path.from([child]));

  IncompleteData/*<S>*/ childData/*<S>*/(Object child, dynamic/*=S*/ childValue) =>
      new IncompleteData/*<S>*/(childValue, _states.children[child]);

  bool _isCompleteForPath(TreeNode<dynamic, bool> states, Path path) =>
      states.nodesOnPath(path).any((v)=>v.value==true);

  IncompleteData<T> update(T newValue, Iterable<Path> newCompletedPaths) {
    var newStates = _states;
    for (var p in newCompletedPaths) {
      if (_isCompleteForPath(newStates, p)) continue;
      newStates = _completePath(newStates, p);
    }
    return new IncompleteData(newValue, newStates);
  }

  TreeNode<dynamic, bool> _completePath(TreeNode<dynamic, bool> states, Path path) {
    if (path.isEmpty) return new TreeNode(true);
    var c = path.first;
    return states.clone()..children[c] = _completePath(states.children[c] ?? new TreeNode(), path.skip(1));
  }


  String toString() => "IncompleteData[$value,$_states]";
}

class DataObserver<T> extends EventTarget {

  IncompleteData<T> _data;

  final EventGenerator<T> eventGenerator;

  DataObserver([T initialValue, this.eventGenerator = const EventGenerator()]) :
      _data = new IncompleteData(initialValue);

  T get currentValue => _data.value;
  IncompleteData<T> get incompleteData => _data;

  void applyOperation(Operation<T> operation) {
    var oldData = _data;
    _data = _data.update(
        operation.apply(_data.value),
        operation.completesPaths);
    eventTypesWithRegistrations.expand((t)=>
        eventGenerator.generateEvents(t, oldData, _data))
        .forEach(dispatchEvent);
  }

  Iterable<Event> generateInitialEvents(String type) =>
      eventGenerator.generateEvents(type, new IncompleteData(null), _data);

}


class EventGenerator<T> {

  const EventGenerator();

  static bool _equals(a,b) {
    if (a is Map&&b is Map) return const MapEquality().equals(a,b);
    if (a is Iterable&&b is Iterable) return const IterableEquality().equals(a,b);
    return a==b;
  }


  Iterable<Event> generateEvents(String eventType, IncompleteData<T> oldValue, IncompleteData<T> newValue) sync* {
    if (eventType!="value") return;
    if (!newValue.isComplete) return;
    if (oldValue.isComplete&&_equals(oldValue.value,newValue.value)) return;
    yield new ValueEvent(newValue.value);
  }


}
