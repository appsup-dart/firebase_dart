// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:sortedmap/sortedmap.dart';
import 'package:collection/collection.dart';

class Path<K> extends UnmodifiableListView<K> implements Comparable<Path<K>> {
  Path() : super([]);

  Path.from(super.source);

  @override
  Path<K> skip(int count) => Path.from(super.skip(count));

  Path<K> child(K child) => Path.from(List.from(this)..add(child));

  Path<K>? get parent => isEmpty ? null : Path.from(take(length - 1));

  @override
  late final int hashCode = const ListEquality().hash(this);

  @override
  bool operator ==(Object other) =>
      other is Path && const ListEquality().equals(this, other);

  bool isDescendantOf(Path<K> other) {
    if (other.length >= length) return false;
    return Path.from(take(other.length)) == other;
  }

  @override
  int compareTo(Path<K> other) {
    // dummy implementation, so that it can be used as key in a SortedMap
    return Comparable.compare(hashCode, other.hashCode);
  }
}

abstract class TreeNode<K, V> {
  V get value;

  Map<K, TreeNode<K, V>> get children;

  const TreeNode();

  TreeNode<K, V>? subtreeNullable(Path<K> path) {
    if (path.isEmpty) return this;
    if (!children.containsKey(path.first)) {
      return null;
    }
    var child = children[path.first]!;
    return child.subtreeNullable(path.skip(1));
  }

  bool get isLeaf => isEmpty && value != null;

  bool get isNil => isEmpty && value == null;

  bool get isEmpty => children.isEmpty;

  bool hasChild(Path<K> path) =>
      path.isEmpty ||
      children.containsKey(path.first) &&
          children[path.first]!.hasChild(path.skip(1));

  Iterable<TreeNode<K, V>> nodesOnPath(Path<K> path) sync* {
    yield this;
    if (path.isEmpty) return;
    var c = path.first;
    if (!children.containsKey(c)) return;
    yield* children[c]!.nodesOnPath(path.skip(1));
  }

  @override
  String toString() => 'TreeNode[$value]$children';

  void forEachNode(void Function(Path<K> key, V value) f) {
    void forEach(TreeNode<K, V> node, Path<K> p) {
      f(p, node.value);
      node.children.forEach((c, v) {
        forEach(v, p.child(c));
      });
    }

    forEach(this, Path());
  }
}

class LeafTreeNode<K, V> extends TreeNode<K, V> {
  const LeafTreeNode(this.value);

  @override
  Map<K, TreeNode<K, V>> get children => const {};

  @override
  final V value;
}

abstract class ComparableTreeNode<K extends Comparable, V>
    extends TreeNode<K, V> implements Comparable<ModifiableTreeNode<K, V>> {
  /// Order: nil, leaf, node with children
  @override
  int compareTo(ComparableTreeNode<K, V> other) {
    if (isLeaf) {
      if (other.isLeaf) {
        return Comparable.compare(
            value as Comparable, other.value as Comparable);
      } else if (other.isNil) {
        return 1;
      }
      return -1;
    } else if (isNil) {
      return other.isNil ? 0 : -1;
    } else {
      if (other.isEmpty) {
        return 1;
      } else {
        return 0;
      }
    }
  }
}

class ModifiableTreeNode<K extends Comparable, V>
    extends ComparableTreeNode<K, V> {
  @override
  V value;

  final Map<K, ModifiableTreeNode<K, V>> _children;

  ModifiableTreeNode(this.value, [Map<K, ModifiableTreeNode<K, V>>? children])
      : _children = TreeMap.from(children ?? {});

  @override
  Map<K, ModifiableTreeNode<K, V>> get children => _children;

  ModifiableTreeNode<K, V> subtree(Path<K> path,
      ModifiableTreeNode<K, V> Function(V parent, K name) newInstance) {
    if (path.isEmpty) return this;
    var child = children[path.first];
    child ??= children[path.first] = newInstance(value, path.first);
    return child.subtree(path.skip(1), newInstance);
  }

  ModifiableTreeNode<K, V> clone() => ModifiableTreeNode(value, children);
}
