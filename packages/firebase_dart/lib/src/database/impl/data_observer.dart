// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'event.dart';
import 'package:collection/collection.dart';
import 'events/value.dart';
import 'operations/tree.dart';
import 'tree.dart';
import 'utils.dart';
import 'treestructureddata.dart';

abstract class Operation {
  TreeStructuredData apply(TreeStructuredData value);

  Iterable<Path<Name>> get completesPaths;

  Operation operationForChild(Name key);
}

/// This class holds a collection of writes that can be applied to nodes in
/// unison.
///
/// It abstracts away the logic with dealing with priority writes and multiple
/// nested writes.
///
/// At any given path there is only allowed to be one write modifying that path.
/// Any write to an existing path or shadowing an existing path will modify that
/// existing write to reflect the write added.
class IncompleteData {
  final TreeNode<Name, TreeStructuredData /*?*/ > _writeTree;
  final QueryFilter /*!*/ filter;

  IncompleteData.empty([QueryFilter filter = const QueryFilter()])
      : this._(TreeNode(null), filter);
  IncompleteData.complete(TreeStructuredData data)
      : this._(TreeNode(data), data.children.filter);
  IncompleteData._(this._writeTree, [this.filter = const QueryFilter()])
      : assert(_writeTree != null);

  IncompleteData withFilter(QueryFilter filter) {
    return IncompleteData._(_writeTree, filter);
  }

  TreeStructuredData _cachedValue;
  TreeStructuredData get value {
    return _cachedValue ??=
        toOperation().apply(TreeStructuredData(filter: filter));
  }

  /// Returns true if all the data is complete
  bool get isComplete => _writeTree.value != null;

  /// Returns true if the data at [path] is complete
  bool isCompleteForPath(Path<Name> path) =>
      _writeTree.findRootMostPathWithValue(path) != null;

  /// Returns true if the data for the direct [child] is complete
  bool isCompleteForChild(Name child) => _writeTree.children[child] != null;

  /// Creates an [IncompleteData] structure for the direct [child]
  IncompleteData directChild(Name child) {
    if (isComplete) {
      return IncompleteData._(
          TreeNode(_writeTree.value.children[child] ?? TreeStructuredData()));
    }
    var tree = _writeTree.children[child];
    if (tree != null) return IncompleteData._(tree);
    return IncompleteData._(TreeNode(null));
  }

  IncompleteData child(Path<Name> path) {
    if (path.isEmpty) return this;
    return directChild(path.first).child(path.skip(1));
  }

  TreeStructuredData get completeValue => isComplete ? value : null;

  /// Returns the value at [path] when it is complete, null otherwise
  TreeStructuredData getCompleteDataAtPath(Path<Name> path) {
    Path rootMost = _writeTree.findRootMostPathWithValue(path);
    if (rootMost != null) {
      var v = _writeTree
          .subtreeNullable(rootMost)
          .value
          .getChild(path.skip(rootMost.length));
      if (v.isNil) return TreeStructuredData();
      return v;
    } else {
      return null;
    }
  }

  Map<Name, TreeStructuredData> get completeChildren {
    if (_writeTree.value != null) {
      return _writeTree.value.children;
    } else {
      return Map.fromEntries(_writeTree.children.entries
          .where((v) => v.value.value != null)
          .map((e) => MapEntry(e.key,
              e.value.value.isNil ? TreeStructuredData() : e.value.value)));
    }
  }

  @override
  String toString() => 'IncompleteData[$_writeTree]';

  IncompleteData applyOperation(TreeOperation operation) {
    var n = operation.nodeOperation;
    if (n is SetPriority) {
      return IncompleteData._(
          _writeTree.addPriority(operation.path, n.priority), filter);
    } else if (n is Overwrite) {
      var v = IncompleteData._(
          _writeTree.addOverwrite(operation.path, n.value), filter);
      return v;
    } else if (n is Merge) {
      var v = this;
      for (var o in n.overwrites) {
        v = v.applyOperation(TreeOperation.overwrite(
            Path.from([...operation.path, ...o.path]),
            (o.nodeOperation as Overwrite).value));
      }
      return v;
    }
    throw UnsupportedError('Operation of type ${n.runtimeType} not supported');
  }

  IncompleteData removeWrite(Path<Name> path) {
    if (path.isEmpty) {
      return IncompleteData._(TreeNode(null), filter);
    } else {
      var newWriteTree = _writeTree.setPath(path, TreeNode(null));
      return IncompleteData._(newWriteTree, filter);
    }
  }

  void forEachCompleteNode(Function(Path<Name> k, TreeStructuredData v) f,
          [Path<Name> path]) =>
      _writeTree.subtreeNullable(path ?? Path())?.forEachNode((k, v) {
        if (v == null) return;
        f(Path.from([...?path, ...k]), v);
      });

  TreeOperation toOperation() {
    var overwrites = <Path<Name>, TreeStructuredData>{};
    _writeTree.forEachNode((key, value) {
      if (value == null) return;
      overwrites[key] = value.isNil ? TreeStructuredData() : value;
    });
    if (overwrites.length == 1) {
      return TreeOperation.overwrite(
          overwrites.keys.first, overwrites.values.first);
    }
    return TreeOperation.merge(Path(), overwrites);
  }
}

class EventGenerator {
  const EventGenerator();

  static bool _equals(a, b) {
    if (a is Map && b is Map) return const MapEquality().equals(a, b);
    if (a is Iterable && b is Iterable) {
      return const IterableEquality().equals(a, b);
    }
    return a == b;
  }

  Iterable<Event> generateEvents(String eventType, IncompleteData oldValue,
      IncompleteData newValue) sync* {
    if (eventType != 'value') return;
    if (!newValue.isComplete) return;
    if (oldValue.isComplete && _equals(oldValue.value, newValue.value)) return;
    yield ValueEvent(newValue.value);
  }
}

extension _WriteTreeX on TreeNode<Name, TreeStructuredData> {
  TreeNode<Name, TreeStructuredData> addOverwrite(
      Path<Name> path, TreeStructuredData data) {
    if (value != null) {
      return TreeNode(TreeOperation.overwrite(path, data).apply(value));
    }

    if (path.isEmpty) return TreeNode(data);
    var c = path.first;
    return clone()
      ..children[c] =
          (children[c] ?? TreeNode(null)).addOverwrite(path.skip(1), data);
  }

  TreeNode<Name, TreeStructuredData> addPriority(Path<Name> path, Value data) {
    return addOverwrite(
        path.child(Name('.priority')), TreeStructuredData.leaf(data));
  }
}
