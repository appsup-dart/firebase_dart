// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../data_observer.dart';
import '../event.dart';
import '../events/child.dart';
import '../tree.dart';

typedef TreeNode<K,V> NodeFactory<K,V>();

class TreeOperation<K,V> extends Operation<TreeNode<K,V>> {

  final Path<K> path;
  final Operation<TreeNode<K,V>> nodeOperation;
  final NodeFactory<K,V> factory;


  TreeOperation(this.path, this.nodeOperation, this.factory);

  @override
  TreeNode<K, V> apply(TreeNode<K, V> value) {
    return _applyOnPath(path, value);
  }

  TreeOperation<K,V> operationForChild(K key) {
    if (path.isEmpty) return null;
    if (path.first!=key) return null;
    return new TreeOperation(path.skip(1), nodeOperation, factory);
  }

  @override
  String toString() => "TreeOperation[$path,$nodeOperation]";


  @override
  Iterable<Path> get completesPaths =>
      nodeOperation.completesPaths.map/*<Path>*/((p)=>new Path.from(new List.from(this.path)..addAll(p)));


  TreeNode<K,V> _applyOnPath(Path<K> path, TreeNode<K,V> value) {
    if (path.isEmpty) {
      return nodeOperation.apply(value);
    } else {
      var k = path.first;
      TreeNode<K,V> child = value.children[k] ?? factory();
      var newChild = _applyOnPath(path.skip(1), child);
      var newValue = value.clone();
      if (newValue.isLeaf&&!newChild.isNil) newValue.value = null;
      if (newChild.isNil) newValue.children.remove(k);
      else newValue.children[k] = newChild;
      return newValue;
    }
  }

}

class Merge<K,V> extends Operation<TreeNode<K,V>> {

  final Map<K,TreeNode<K,V>> children;

  Merge(this.children);

  @override
  TreeNode<K, V> apply(TreeNode<K, V> value) {
    return value.clone()..children.addAll(children);
  }


  @override
  Iterable<Path> get completesPaths => children.keys.map/*<Path>*/((c)=>new Path.from([c]));
}

class Overwrite<K,V> extends Operation<TreeNode<K,V>> {
  final TreeNode<K,V> value;

  Overwrite(this.value);

  @override
  TreeNode<K,V> apply(TreeNode<K,V> value) =>
      value.clone()..value = this.value.value..children.clear()..children.addAll(this.value.children);

  @override
  String toString() => "Overwrite[$value]";

  @override
  Iterable<Path> get completesPaths => [new Path()];
}

class TreeEventGenerator<K,V> extends EventGenerator<TreeNode<K,V>> {

  const TreeEventGenerator();

  @override
  Iterable<Event> generateEvents(String eventType,
      IncompleteData<TreeNode<K,V>> oldValue,
      IncompleteData<TreeNode<K,V>> newValue) sync* {
    var newChildren = newValue.value.children;
    Map<K,TreeNode<K,V>> oldChildren = oldValue.value?.children ?? const {};
    switch (eventType) {
      case "child_added":
        var newPrevKey = null;
        for (var key in newChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (!oldChildren.containsKey(key)) {
            yield new ChildAddedEvent(
                key, newChildren[key], newPrevKey);
          }
          newPrevKey = key;
        }
        return;
      case "child_changed":
        var newPrevKey = null;
        for (var key in newChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (oldChildren.containsKey(key)) {
            if (oldChildren[key] != newChildren[key]) {
              yield new ChildChangedEvent(
                  key, newChildren[key], newPrevKey);
            }
          }
          newPrevKey = key;
        }
        return;
      case "child_removed":
        var oldPrevKey = null;
        for (var key in oldChildren.keys) {
          if (!newValue.isCompleteForChild(key)) continue;
          if (!newChildren.containsKey(key)) {
            yield new ChildRemovedEvent(
                key, oldChildren[key], oldPrevKey);
          }
          oldPrevKey = key;
        }
        return;
      case "child_moved":
        K lastKeyBefore(List<K> list, K key) {
          var index = list.indexOf(key);
          if (index<=0) return null;
          return list[index-1];
        }
        var newKeys = newChildren.keys.toList();

        var oldPrevKey = null;
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