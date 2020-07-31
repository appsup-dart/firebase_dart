// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../data_observer.dart';
import '../event.dart';
import '../events/child.dart';
import '../tree.dart';
import '../treestructureddata.dart';

class TreeOperation extends Operation {
  final Path<Name> path;
  final Operation nodeOperation;

  TreeOperation(this.path, this.nodeOperation);

  factory TreeOperation.overwrite(Path<Name> path, TreeStructuredData value) {
    if (path.isNotEmpty && path.last == Name('.priority')) {
      return TreeOperation(path.parent, SetPriority(value.value));
    }
    return TreeOperation(path, Overwrite(value));
  }

  TreeOperation.merge(
      Path<Name> path, Map<Path<Name>, TreeStructuredData> children)
      : this(path, Merge(children));

  factory TreeOperation.ack(Path<Name> path, bool success) =>
      Ack(path, success);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    return _applyOnPath(path, value);
  }

  @override
  TreeOperation operationForChild(Name key) {
    if (path.isEmpty) {
      var op = nodeOperation.operationForChild(key);
      if (op == null) return null;
      return TreeOperation(path, op);
    }
    if (path.first != key) return null;
    return TreeOperation(path.skip(1), nodeOperation);
  }

  @override
  String toString() => 'TreeOperation[$path,$nodeOperation]';

  @override
  Iterable<Path<Name>> get completesPaths => nodeOperation.completesPaths
      .map<Path<Name>>((p) => Path.from(List.from(path)..addAll(p)));

  TreeStructuredData _applyOnPath(Path<Name> path, TreeStructuredData value) {
    if (path.isEmpty) {
      return nodeOperation.apply(value);
    } else {
      var k = path.first;
      var child = value.children[k] ?? TreeStructuredData();
      var newChild = _applyOnPath(path.skip(1), child);
      var newValue = value.clone();
      if (newValue.isLeaf && !newChild.isNil) newValue.value = null;
      if (newChild.isNil) {
        newValue.children.remove(k);
      } else {
        newValue.children[k] = newChild;
      }
      return newValue;
    }
  }
}

class Ack extends TreeOperation {
  final bool success;

  Ack(Path<Name> path, this.success) : super(path, null);

  @override
  Ack operationForChild(Name key) {
    if (path.isEmpty) return this;
    if (path.first != key) return null;
    return Ack(path.skip(1), success);
  }
}

class Merge extends Operation {
  final List<TreeOperation> overwrites;

  Merge._(this.overwrites);
  Merge(Map<Path<Name>, TreeStructuredData> children)
      : this._(children.keys
            .map((p) => TreeOperation.overwrite(p, children[p]))
            .toList());

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    // first do remove operations then set operations, otherwise filtered views
    // might remove some values
    var removeOperations =
        overwrites.where((t) => (t.nodeOperation as Overwrite).value.isNil);
    var setOperations =
        overwrites.where((t) => !(t.nodeOperation as Overwrite).value.isNil);
    var v = removeOperations.fold(value, (v, o) => o.apply(v));
    v = setOperations.fold(v, (v, o) => o.apply(v));
    return v;
  }

  @override
  Iterable<Path<Name>> get completesPaths =>
      overwrites.expand<Path<Name>>((c) => c.completesPaths);

  @override
  Operation operationForChild(Name key) {
    var o =
        overwrites.map((o) => o.operationForChild(key)).where((o) => o != null);
    if (o.isEmpty) return null;
    return Merge._(o.toList());
  }

  @override
  String toString() => 'Merge[$overwrites]';
}

class Overwrite extends Operation {
  final TreeStructuredData value;

  Overwrite(this.value);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    return this.value.withFilter(value.children.filter);
  }

  @override
  String toString() => 'Overwrite[$value]';

  @override
  Iterable<Path<Name>> get completesPaths => [Path()];

  @override
  Operation operationForChild(Name key) {
    var child = value.children[key] ?? TreeStructuredData();
    return Overwrite(child);
  }
}

class SetPriority extends Operation {
  final Value value;

  SetPriority(this.value);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    return value.clone()..priority = this.value;
  }

  @override
  String toString() => 'SetPriority[$value]';

  @override
  Iterable<Path<Name>> get completesPaths => [];

  @override
  Operation operationForChild(Name key) => null;
}

class TreeEventGenerator extends EventGenerator {
  const TreeEventGenerator();

  @override
  Iterable<Event> generateEvents(String eventType, IncompleteData oldValue,
      IncompleteData newValue) sync* {
    var newChildren = newValue.value.children;
    var oldChildren = oldValue.value?.children ?? const {};
    if (!newValue.isComplete) {
      // do not generate events when value is incomplete
      return;
    }
    if (!oldValue.isComplete) {
      // when old value was not complete, we didn't yet show any children
      oldChildren = const {};
    }
    switch (eventType) {
      case 'child_added':
        var newPrevKey;
        for (var key in newChildren.keys) {
          if (!oldChildren.containsKey(key)) {
            yield ChildAddedEvent(key, newChildren[key], newPrevKey);
          }
          newPrevKey = key;
        }
        return;
      case 'child_changed':
        var newPrevKey;
        for (var key in newChildren.keys) {
          if (oldChildren.containsKey(key)) {
            if (oldChildren[key] != newChildren[key]) {
              yield ChildChangedEvent(key, newChildren[key], newPrevKey);
            }
          }
          newPrevKey = key;
        }
        return;
      case 'child_removed':
        var oldPrevKey;
        for (var key in oldChildren.keys) {
          if (!newChildren.containsKey(key)) {
            yield ChildRemovedEvent(key, oldChildren[key], oldPrevKey);
          }
          oldPrevKey = key;
        }
        return;
      case 'child_moved':
        Name lastKeyBefore(List<Name> list, Name key) {
          var index = list.indexOf(key);
          if (index <= 0) return null;
          return list[index - 1];
        }
        var newKeys = newChildren.keys.toList();

        var oldPrevKey;
        for (var key in oldChildren.keys) {
          if (newChildren.containsKey(key)) {
            var newPrevKey = lastKeyBefore(newKeys, key);
            if (oldPrevKey != newPrevKey) {
              yield ChildMovedEvent(key, lastKeyBefore(newKeys, key));
            }
          }
          oldPrevKey = key;
        }
        return;
      default:
        yield* super.generateEvents(eventType, oldValue, newValue);
    }
  }
}
