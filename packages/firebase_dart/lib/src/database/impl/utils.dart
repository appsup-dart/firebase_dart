import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';

typedef Predicate<T> = bool Function(T);

extension TreeNodeXNonNull<T> on TreeNode<Name, T> {
  bool containsMatchingValue(Predicate<T> predicate) {
    if (predicate(value)) {
      return true;
    } else {
      for (var subtree in children.values) {
        if (subtree.containsMatchingValue(predicate)) {
          return true;
        }
      }
      return false;
    }
  }

  /// Returns the deepest value found between the root and the specified path
  /// that matches the predicate.
  T? leafMostValueMatching(Path<Name> path, Predicate<T> predicate) {
    var currentValue = predicate(value) ? value : null;
    var currentTree = this;
    for (var key in path) {
      if (!currentTree.children.containsKey(key)) {
        break;
      }
      currentTree = currentTree.children[key]!;
      if (predicate(currentTree.value)) {
        currentValue = currentTree.value;
      }
    }
    return currentValue;
  }

  T? rootMostValueMatching(Path<Name> relativePath, Predicate<T> predicate) {
    if (predicate(value)) {
      return value;
    } else {
      var currentTree = this;
      for (var key in relativePath) {
        if (!currentTree.children.containsKey(key)) {
          return null;
        }
        currentTree = currentTree.children[key]!;
        if (predicate(currentTree.value)) {
          return currentTree.value;
        }
      }
      return null;
    }
  }

  Path<Name>? findRootMostPathWithValue(Path<Name> relativePath) =>
      findRootMostMatchingPath(relativePath, (v) => v != null);

  Path<Name>? findRootMostMatchingPath(
      Path<Name> relativePath, Predicate<T> predicate) {
    if (predicate(value)) {
      return Path();
    } else {
      if (relativePath.isEmpty) {
        return null;
      } else {
        var front = relativePath.first;
        var child = children[front];
        if (child != null) {
          var path =
              child.findRootMostMatchingPath(relativePath.skip(1), predicate);
          if (path != null) {
            return Path<Name>.from([front, ...path]);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
    }
  }

  Iterable<T> get allNonNullValues sync* {
    if (value != null) yield value!;
    for (var c in children.values) {
      yield* c.allNonNullValues;
    }
  }
}

extension ModifiableTreeNodeXNonNull<T> on ModifiableTreeNode<Name, T> {
  ModifiableTreeNode<Name, T> setValue(
      Path<Name> path, T value, T Function() defaultValue) {
    if (path.isEmpty) return ModifiableTreeNode(value, children);

    var c = children[path.first] ?? ModifiableTreeNode(defaultValue());

    return ModifiableTreeNode(this.value, {
      ...children,
      path.first: c.setValue(path.skip(1), value, defaultValue)
    });
  }

  ModifiableTreeNode<Name, T>? removePath(Path<Name> path) {
    if (path.isEmpty) return null;

    if (!this.children.containsKey(path.first)) {
      return this;
    }
    var c = this.children[path.first]!.removePath(path.skip(1));

    var children = {...this.children, if (c != null) path.first: c};
    if (value == null && children.isEmpty) return null;
    return ModifiableTreeNode(value, children);
  }

  ModifiableTreeNode<Name, T> setPath(
      Path<Name> path, ModifiableTreeNode<Name, T> subtree, T defaultValue) {
    if (path.isEmpty) return subtree;

    var c = children[path.first] ?? ModifiableTreeNode(defaultValue);

    return ModifiableTreeNode(value, {
      ...children,
      path.first: c.setPath(path.skip(1), subtree, defaultValue)
    });
  }
}

class TreeNodeEquality<K extends Comparable, V>
    implements Equality<ModifiableTreeNode<K, V>> {
  static const _childrenEquality = MapEquality(values: TreeNodeEquality());
  const TreeNodeEquality();

  @override
  bool equals(ModifiableTreeNode<K, V> e1, ModifiableTreeNode<K, V> e2) {
    return e1.value == e2.value &&
        _childrenEquality.equals(e1.children, e2.children);
  }

  @override
  int hash(ModifiableTreeNode<K, V> e) {
    return Object.hash(_childrenEquality.hash(e.children), e.value);
  }

  @override
  bool isValidKey(Object? o) {
    return o is ModifiableTreeNode<K, V>;
  }
}

extension NameX on Name {
  bool get isPriorityChildName => this == Name.priorityKey;
}

extension TreeStructuredDataX on TreeStructuredData {
  TreeStructuredData getChild(Path<Name> path) {
    if (path.isEmpty) return this;
    var c = children[path.first];
    if (c == null) return TreeStructuredData();
    return c.getChild(path.skip(1));
  }

  TreeStructuredData updateChild(Path<Name> path, TreeStructuredData value) {
    if (path.isEmpty) return value;
    if (path.last.isPriorityChildName) {
      return updatePriority(path.parent!, value.value);
    }

    var c = children[path.first] ?? TreeStructuredData();

    var newChild = c.updateChild(path.skip(1), value);

    if (newChild.isNil) return withoutChild(path.first);
    return withChild(path.first, newChild);
  }

  TreeStructuredData updatePriority(Path<Name> path, Value? priority) {
    var c = getChild(path);
    if (c.isNil) return this;
    if (c.isEmpty) {
      c = TreeStructuredData.leaf(c.value!, priority);
    } else {
      c = TreeStructuredData.nonLeaf(c.children, priority);
    }
    return updateChild(path, c);
  }
}

extension KeyValueIntervalX on KeyValueInterval {
  bool intersects(KeyValueInterval other) {
    if (containsPoint(other.start)) return true;
    if (containsPoint(other.end)) return true;
    if (other.containsPoint(start)) return true;
    if (other.containsPoint(end)) return true;
    return false;
  }

  static KeyValueInterval coverAll(Iterable<KeyValueInterval> intervals) {
    assert(intervals.isNotEmpty);
    var min = intervals
        .map((i) => i.start)
        .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    var max = intervals
        .map((i) => i.end)
        .reduce((a, b) => a.compareTo(b) < 0 ? b : a);
    return KeyValueInterval.fromPairs(min, max);
  }

  static Iterable<KeyValueInterval> unionAll(
      Iterable<KeyValueInterval> intervals) sync* {
    var ordered = <KeyValueInterval>[...intervals]
      ..sort((a, b) => Comparable.compare(a.start, b.start));

    KeyValueInterval? last;
    while (ordered.isNotEmpty) {
      var i = ordered.removeAt(0);
      if (last == null) {
        last = i;
        continue;
      }
      if (i.intersects(last)) {
        last = coverAll([i, last]);
        continue;
      }
      yield last;
      last = i;
    }
    if (last != null) yield last;
  }
}

class DelayedCancellableFuture<T> extends DelegatingFuture<T> {
  final void Function() cancel;

  DelayedCancellableFuture._(Future<T> future, this.cancel) : super(future);
  factory DelayedCancellableFuture(
      Duration duration, FutureOr<T> Function() computation) {
    var c = Completer<T>();
    var t = Timer(duration, () {
      c.complete(computation());
    });

    return DelayedCancellableFuture._(c.future, () {
      t.cancel();
    });
  }
}
