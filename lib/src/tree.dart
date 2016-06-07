// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:sortedmap/sortedmap.dart';

class Path<K> extends UnmodifiableListView<K> {
  Path() : super([]);

  Path.from(Iterable<K> source) : super(source);

  Path skip(int count) => new Path.from(super.skip(1));
}

class TreeNode<K,V> implements Comparable<TreeNode<K,V>> {

  V value;

  final Map<K,TreeNode<K,V>> children;

  TreeNode([this.value, Map<K,TreeNode<K,V>> children]) :
        children = (_cloneMap(children ?? {}));

  static _cloneMap(Map map) => map is SortedMap ? map.clone() : new Map.from(map);

  TreeNode<K,V> subtree(Path<K> path, [TreeNode<K,V> newInstance()]) =>
      path.isEmpty ? this
          : children.putIfAbsent(path.first, newInstance ?? ()=>null)
          ?.subtree(path.skip(1), newInstance);


  TreeNode<K,V> clone() => new TreeNode(value,children);


  bool get isLeaf => isEmpty&&value!=null;
  bool get isNil => isEmpty&&value==null;
  bool get isEmpty => children.isEmpty;

  /**
   * Order: nil, leaf, node with children
   */
  @override
  int compareTo(TreeNode<K, V> other) {
    if (isLeaf) {
      if (other.isLeaf) {
        return Comparable.compare(value as Comparable,other.value as Comparable);
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

  bool hasChild(Path<K> path) => path.isEmpty||
      children.containsKey(path.first)&&children[path.first].hasChild(path.skip(1));


  Iterable<TreeNode<K,V>> nodesOnPath(Path<K> path) sync* {
    if (path.isEmpty) return;
    var c = path.first;
    if (!children.containsKey(c)) return;
    yield children[c];
    yield* children[c].nodesOnPath(path.skip(1));
  }

  toString() => "TreeNode[$value]$children";


}

