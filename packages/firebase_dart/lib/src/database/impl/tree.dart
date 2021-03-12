// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'dart:collection';
import 'package:sortedmap/sortedmap.dart';
import 'package:collection/collection.dart';

class Path<K> extends UnmodifiableListView<K> {
  Path() : super([]);

  Path.from(Iterable<K> source) : super(source);

  @override
  Path<K> skip(int count) => Path.from(super.skip(count));

  Path<K> child(K child) => Path.from(List.from(this)..add(child));

  Path<K> get parent => isEmpty ? null : Path.from(take(length - 1));

  @override
  int get hashCode => const ListEquality().hash(this);

  @override
  bool operator ==(dynamic other) =>
      other is Path && const ListEquality().equals(this, other);
}

class TreeNode<K extends Comparable, V>
    implements Comparable<TreeNode<K, V> /*!*/ > {
  V /*!*/ value;

  final Map<K, TreeNode<K, V> /*!*/ > _children;

  TreeNode(this.value, [Map<K, TreeNode<K, V>> children])
      : _children = (_cloneMap<K, TreeNode<K, V>>(children ?? {}));

  Map<K, TreeNode<K, V>> get children => _children;

  static Map<K, V> _cloneMap<K extends Comparable, V>(Map<K, V> map) {
    if (map is SortedMap<K, V>) {
      return map.clone();
    }
    return Map<K, V>.from(map);
  }

  TreeNode<K, V> subtreeNullable(Path<K> path) {
    if (path.isEmpty) return this;
    if (!children.containsKey(path.first)) {
      return null;
    }
    var child = children[path.first];
    return child.subtreeNullable(path.skip(1));
  }

  TreeNode<K, V> subtree(
      Path<K> path, TreeNode<K, V> Function(V parent, K name) newInstance) {
    if (path.isEmpty) return this;
    if (!children.containsKey(path.first)) {
      children[path.first] = newInstance(value, path.first);
    }
    var child = children[path.first];
    return child.subtree(path.skip(1), newInstance);
  }

  TreeNode<K, V> clone() => TreeNode(value, children);

  bool get isLeaf => isEmpty && value != null;

  bool get isNil => isEmpty && value == null;

  bool get isEmpty => children.isEmpty;

  /// Order: nil, leaf, node with children
  @override
  int compareTo(TreeNode<K, V> other) {
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

  bool hasChild(Path<K> path) =>
      path.isEmpty ||
      children.containsKey(path.first) &&
          children[path.first].hasChild(path.skip(1));

  Iterable<TreeNode<K, V>> nodesOnPath(Path<K> path) sync* {
    yield this;
    if (path.isEmpty) return;
    var c = path.first;
    if (!children.containsKey(c)) return;
    yield* children[c].nodesOnPath(path.skip(1));
  }

  @override
  String toString() => 'TreeNode[$value]$children';

  void forEachNode(void Function(Path<K> key, V value) f) {
    void _forEach(TreeNode<K, V> node, Path<K> p) {
      f(p, node.value);
      node.children.forEach((c, v) {
        _forEach(v, p.child(c));
      });
    }

    _forEach(this, Path());
  }
}
