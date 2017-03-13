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
    if (path.isNotEmpty&&path.last==new Name(".priority"))
      return new TreeOperation(path.parent, new SetPriority(value.value));
    return new TreeOperation(path, new Overwrite(value));
  }

  TreeOperation.merge(Path<Name> path, Map<Name, TreeStructuredData> children)
      : this(path, new Merge(children));

  factory TreeOperation.ack(Path<Name> path, bool success) =>
      new Ack(path, success);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    return _applyOnPath(path, value);
  }

  @override
  TreeOperation operationForChild(Name key) {
    if (path.isEmpty) {
      var op = nodeOperation.operationForChild(key);
      if (op==null) return null;
      return new TreeOperation(path, op);
    }
    if (path.first != key) return null;
    return new TreeOperation(path.skip(1), nodeOperation);
  }

  @override
  String toString() => "TreeOperation[$path,$nodeOperation]";

  @override
  Iterable<Path<Name>> get completesPaths => nodeOperation.completesPaths
      .map<Path<Name>>((p) => new Path.from(new List.from(this.path)..addAll(p)));

  TreeStructuredData _applyOnPath(Path<Name> path, TreeStructuredData value) {
    if (path.isEmpty) {
      return nodeOperation.apply(value);
    } else {
      var k = path.first;
      TreeStructuredData child = value.children[k] ?? new TreeStructuredData();
      var newChild = _applyOnPath(path.skip(1), child);
      var newValue = value.clone();
      if (newValue.isLeaf && !newChild.isNil) newValue.value = null;
      if (newChild.isNil)
        newValue.children.remove(k);
      else
        newValue.children[k] = newChild;
      return newValue;
    }
  }
}

class Ack extends TreeOperation {
  @override
  final bool success;

  Ack(Path<Name> path, this.success) : super(path, null);

  @override
  Ack operationForChild(Name key) {
    if (path.isEmpty) return this;
    if (path.first != key) return null;
    return new Ack(path.skip(1), success);
  }
}

class Merge extends Operation {
  final Map<Name, TreeStructuredData> children;

  Merge(this.children);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    var n = value.clone();
    children.forEach((k,v) {
      if (v.isNil) n.children.remove(k);
    });
    children.forEach((k,v) {
      if (!v.isNil) n.children[k] = children[k];
    });
    return n;
  }

  @override
  Iterable<Path<Name>> get completesPaths =>
      children.keys.map<Path<Name>>((c) => new Path<Name>.from([c]));

  @override
  Operation operationForChild(Name key) {
    if (!children.containsKey(key)) return null;
    return new Overwrite(children[key]);
  }

  @override
  String toString() => "Merge[$children]";
}

class Overwrite extends Operation {
  final TreeStructuredData value;

  Overwrite(this.value);

  @override
  TreeStructuredData apply(TreeStructuredData value) {
    return this.value.withFilter(value.children.filter);
  }

  @override
  String toString() => "Overwrite[$value]";

  @override
  Iterable<Path<Name>> get completesPaths => [new Path()];

  @override
  Operation operationForChild(Name key) {
    var child = value.children[key] ?? new TreeStructuredData();
    return new Overwrite(child);
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
  String toString() => "SetPriority[$value]";

  @override
  Iterable<Path<Name>> get completesPaths => [];

  @override
  Operation operationForChild(Name key) => null;
}

class TreeEventGenerator extends EventGenerator {
  const TreeEventGenerator();

  @override
  Iterable<Event> generateEvents(
      String eventType,
      IncompleteData oldValue,
      IncompleteData newValue) sync* {
    var newChildren = newValue.value.children;
    Map<Name, TreeStructuredData> oldChildren = oldValue.value?.children ?? const {};
    switch (eventType) {
      case "child_added":
        var newPrevKey;
        for (var key in newChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (!oldChildren.containsKey(key)) {
            yield new ChildAddedEvent(key, newChildren[key], newPrevKey);
          }
          newPrevKey = key;
        }
        return;
      case "child_changed":
        var newPrevKey;
        for (var key in newChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (oldChildren.containsKey(key)) {
            if (oldChildren[key] != newChildren[key]) {
              yield new ChildChangedEvent(key, newChildren[key], newPrevKey);
            }
          }
          newPrevKey = key;
        }
        return;
      case "child_removed":
        var oldPrevKey;
        for (var key in oldChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (!newChildren.containsKey(key)) {
            yield new ChildRemovedEvent(key, oldChildren[key], oldPrevKey);
          }
          oldPrevKey = key;
        }
        return;
      case "child_moved":
        Name lastKeyBefore(List<Name> list, Name key) {
          var index = list.indexOf(key);
          if (index <= 0) return null;
          return list[index - 1];
        }
        var newKeys = newChildren.keys.toList();

        var oldPrevKey;
        for (var key in oldChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (newChildren.containsKey(key)) {
            var newPrevKey = lastKeyBefore(newKeys, key);
            if (oldPrevKey != newPrevKey) {
              yield new ChildMovedEvent(key, lastKeyBefore(newKeys, key));
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
