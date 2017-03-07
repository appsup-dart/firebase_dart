// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'event.dart';
import 'package:collection/collection.dart';
import 'events/value.dart';
import 'tree.dart';
import 'treestructureddata.dart';

abstract class Operation {
  TreeStructuredData apply(TreeStructuredData value);

  Iterable<Path<Name>> get completesPaths;

  Operation operationForChild(Name key);
}

class IncompleteData {
  final TreeNode<Name, bool> _states;
  final TreeStructuredData value;

  IncompleteData(this.value, [TreeNode<Name, bool> states])
      : _states = states ?? new TreeNode(false) {
    assert(value!=null);
  }

  bool get isComplete => _states.value == true;

  bool isCompleteForPath(Path<Comparable> path) => _isCompleteForPath(_states, path);
  bool isCompleteForChild(Comparable child) =>
      _isCompleteForPath(_states, new Path<Comparable>.from([child]));

  IncompleteData child(Name child) =>
      new IncompleteData(value.children[child] ?? new TreeStructuredData(), _states.value ? new TreeNode(true) : _states.children[child]);

  bool _isCompleteForPath(TreeNode<Comparable, bool> states, Path<Comparable> path) =>
      states.nodesOnPath(path).any((v) => v.value == true);

  IncompleteData update(TreeStructuredData newValue, [Iterable<Path<Name>> newCompletedPaths=const[]]) {
    var newStates = _states;
    for (var p in newCompletedPaths) {
      if (_isCompleteForPath(newStates, p)) continue;
      newStates = _completePath(newStates, p);
    }
    return new IncompleteData(newValue, newStates);
  }

  TreeNode<Name, bool> _completePath(
      TreeNode<Name, bool> states, Path<Name> path) {
    if (path.isEmpty) return new TreeNode(true);
    var c = path.first;
    return states.clone()
      ..children[c] =
          _completePath(states.children[c] ?? new TreeNode(), path.skip(1));
  }

  @override
  String toString() => "IncompleteData[$value,$_states]";

  IncompleteData applyOperation(Operation op) =>
      update(op.apply(value), op.completesPaths);

}

class EventGenerator {
  const EventGenerator();

  static bool _equals(a, b) {
    if (a is Map && b is Map) return const MapEquality().equals(a, b);
    if (a is Iterable && b is Iterable)
      return const IterableEquality().equals(a, b);
    return a == b;
  }

  Iterable<Event> generateEvents(String eventType, IncompleteData oldValue,
      IncompleteData newValue) sync* {
    if (eventType != "value") return;
    if (!newValue.isComplete) return;
    if (oldValue.isComplete && _equals(oldValue.value, newValue.value)) return;
    yield new ValueEvent(newValue.value);
  }
}
