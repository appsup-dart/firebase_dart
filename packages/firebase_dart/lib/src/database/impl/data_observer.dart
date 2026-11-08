// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:sortedmap/sortedmap.dart';

import 'event.dart';
import 'package:collection/collection.dart';
import 'events/value.dart';
import 'operations/tree.dart';
import 'tree.dart';
import 'utils.dart';
import 'treestructureddata.dart';

abstract class Operation {
  /// Applies this operation to [value].
  ///
  /// When the operation does not change [value], returns [value] itself (same
  /// instance), not merely an equal value. Callers may use [identical] to detect
  /// no-op applications.
  TreeStructuredData apply(TreeStructuredData value);

  Iterable<Path<Name>> get completesPaths;

  Operation? operationForChild(Name key);
}

extension _FilterX on Filter<Name, TreeStructuredData> {
  QueryFilter toQueryFilter() {
    if (this is QueryFilter) return this as QueryFilter;
    return QueryFilter(
      limit: limit,
      validInterval: validInterval,
      reversed: reversed,
      ordering: ordering as TreeStructuredDataOrdering,
    );
  }
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
  final WriteTree _writeTree;
  final QueryFilter filter;

  IncompleteData.empty([QueryFilter filter = const QueryFilter()])
      : this._(WriteTree(null, TreeMap()), filter);
  IncompleteData.complete(TreeStructuredData data)
      : this._(WriteTree(data, TreeMap()), data.filter.toQueryFilter());
  IncompleteData._(WriteTree writeTree, [this.filter = const QueryFilter()])
      : _writeTree = writeTree.withFilter(filter);

  bool get isNil => _writeTree.isNil;

  factory IncompleteData.fromLeafs(Map<Path<Name>, TreeStructuredData> leafs) {
    var tree = WriteTree(null, TreeMap());
    for (var e in leafs.entries) {
      tree.subtree(e.key, (parent, name) => WriteTree(null, TreeMap())).value =
          e.value;
    }
    return IncompleteData._(tree);
  }

  /// Registers [ordering] on the write tree so [value] can use its sorted map.
  void addIndex(TreeStructuredDataOrdering ordering) {
    _writeTree.addIndex(ordering);
  }

  /// Orderings registered with [addIndex].
  Set<TreeStructuredDataOrdering> get indexedOrderings =>
      _writeTree.indexedOrderings;

  /// Returns a view of this data with [filter] applied when composing [value].
  ///
  /// When [filter] is unchanged, returns [this] (same instance).
  IncompleteData withFilter(QueryFilter filter) {
    if (filter == this.filter) return this;
    return IncompleteData._(_writeTree.withFilter(filter), filter);
  }

  TreeStructuredData? _cachedValue;
  TreeStructuredData get value {
    return _cachedValue ??= _composeValue(_writeTree, filter);
  }

  WriteTree get writeTree => _writeTree;

  static TreeStructuredData _composeValue(WriteTree tree, QueryFilter filter) {
    if (tree.value != null) return tree.value!.withFilter(filter);

    final ordering = filter.ordering;
    final index = ordering is TreeStructuredDataOrdering
        ? tree.sortedValues(ordering)
        : null;
    if (index == null) {
      return TreeStructuredData.nonLeaf({
        for (var k in tree.children.keys)
          k: _composeValue(tree.children[k]! as WriteTree, const QueryFilter())
      }).withFilter(filter);
    }

    return TreeStructuredData.nonLeaf(index.filteredMap(
      start: Pair.min(filter.startKey, filter.startValue),
      end: Pair.max(filter.endKey, filter.endValue),
      limit: filter.limit,
      reversed: filter.reversed,
    ));
  }

  /// Returns true if all the data is complete
  bool get isComplete => _writeTree.value != null;

  /// Returns true if the data at [path] is complete
  bool isCompleteForPath(Path<Name> path) =>
      _writeTree.findRootMostPathWithValue(path) != null;

  /// Creates an [IncompleteData] structure for the direct [child]
  IncompleteData directChild(Name child) {
    if (isComplete) {
      var c = _writeTree.value!.children[child];
      if (c != null) {
        return IncompleteData._(WriteTree(c, TreeMap()));
      }

      var f = value.filter;
      if (f.validInterval.isUnlimited &&
          (f.limit == null || f.limit! > value.children.length)) {
        return IncompleteData._(WriteTree(TreeStructuredData(), TreeMap()));
      }
      if (f.ordering == KeyOrdering() &&
          value.childrenAsFilteredMap.completeInterval.containsPoint(
              KeyOrdering().mapKeyValue(child, TreeStructuredData()))) {
        return IncompleteData._(WriteTree(TreeStructuredData(), TreeMap()));
      }
    }
    var tree = _writeTree.children[child] as WriteTree?;
    if (tree != null) return IncompleteData._(tree);
    return IncompleteData._(WriteTree(null, TreeMap()));
  }

  IncompleteData child(Path<Name> path) {
    if (path.isEmpty) return this;
    return directChild(path.first).child(path.skip(1));
  }

  TreeStructuredData? get completeValue => isComplete ? value : null;

  /// Returns the value at [path] when it is complete, null otherwise
  TreeStructuredData? getCompleteDataAtPath(Path<Name> path) {
    Path? rootMost = _writeTree.findRootMostPathWithValue(path);
    if (rootMost != null) {
      var v = _writeTree
          .subtreeNullable(rootMost as Path<Name>)!
          .value!
          .getChild(path.skip(rootMost.length));
      if (v.isNil) return TreeStructuredData();
      return v;
    } else {
      return null;
    }
  }

  Map<Name, TreeStructuredData?> get completeChildren {
    if (_writeTree.value != null) {
      return _writeTree.value!.children;
    } else {
      return Map.fromEntries(_writeTree.children.entries
          .where((v) => v.value.value != null)
          .map((e) => MapEntry(e.key,
              e.value.value!.isNil ? TreeStructuredData() : e.value.value)));
    }
  }

  @override
  String toString() => 'IncompleteData[$_writeTree]';

  /// Applies [operation] to this write tree.
  ///
  /// When the operation does not change this data, returns [this] (same
  /// instance). Callers may use [identical] to detect no-op applications.
  IncompleteData applyOperation(TreeOperation operation) {
    var n = operation.nodeOperation;
    if (n is SetPriority) {
      return _rebuild(_writeTree.addPriority(operation.path, n.priority));
    } else if (n is Overwrite) {
      // when the data to overwrite with is filtered, do a merge instead
      if (n.value.filter.limits && !n.value.isLeaf) {
        // unless we overwrite the root and the filters match
        if (operation.path.isNotEmpty || filter != n.value.filter) {
          return applyOperation(TreeOperation.merge(operation.path,
              n.value.children.map((k, v) => MapEntry(Path.from([k]), v))));
        }
      }

      // check if it is safe to overwrite, meaning we do not risk setting unknown values to null

      // when overwriting the root with non filtered data it is always safe
      var safeToOverwrite = operation.path.isEmpty;

      // when overwriting a child including the priority it is safe
      safeToOverwrite =
          safeToOverwrite || operation.path.length == 1 && n is! SetValue;

      // when the path was not yet complete, we can safely overwrite
      var pathIsComplete = isCompleteForPath(operation.path);
      safeToOverwrite = safeToOverwrite || !pathIsComplete;

      // when the filter is not limiting and the data is already complete, it is safe to overwrite
      safeToOverwrite = safeToOverwrite || (!filter.limits && isComplete);

      // when the path to overwrite is complete, it is safe to overwrite
      safeToOverwrite = safeToOverwrite || (!isComplete && pathIsComplete);

      // when some parent was already complete, it is safe to overwrite
      safeToOverwrite = safeToOverwrite ||
          (isComplete &&
              _writeTree.value!.children.containsKey(operation.path.first));

      if (!safeToOverwrite) {
        return this;
      }

      return _rebuild(_writeTree.addOverwrite(operation.path, n.value));
    } else if (n is Merge) {
      var v = this;
      if (isComplete && operation.path.isEmpty) {
        // use Merge.apply here as it will make sure that operations are applied
        // in the correct order (first delete, then add)
        final applied = n.apply(_writeTree.value!);
        if (identical(applied, _writeTree.value)) return this;
        return _rebuild(_writeTree.clone()..value = applied);
      }
      for (var o in n.overwrites) {
        v = v.applyOperation(TreeOperation.overwrite(
            Path.from([...operation.path, ...o.path]),
            (o.nodeOperation as Overwrite).value));
      }
      return v;
    } else if (n is Forget) {
      WriteTree forget(WriteTree tree, Path<Name> path) {
        if (path.isEmpty) {
          if (tree.isNil) return tree;
          if (tree.value == null) return WriteTree(null, TreeMap());
          return tree.clone()..value = null;
        }
        if (tree.value != null) {
          tree = WriteTree(
              null,
              TreeMap.from({
                for (var k in tree.value!.children.keys)
                  k: WriteTree(tree.value!.children[k], TreeMap())
              }));
        }
        var child = tree.children[path.first] as WriteTree?;
        if (child == null) return tree;
        var newChild = forget(child, path.skip(1));
        if (identical(newChild, child)) return tree;
        return tree._replacingChild(path.first, newChild, removeNil: true);
      }

      var tree = forget(_writeTree, operation.path);
      return _rebuild(tree);
    }
    throw UnsupportedError('Operation of type ${n.runtimeType} not supported');
  }

  /// Removes the write at [path].
  ///
  /// When there is no write at [path], returns [this] (same instance).
  IncompleteData removeWrite(Path<Name> path) {
    return _rebuild(_writeTree.removeWrite(path));
  }

  /// Returns [this] when [writeTree] and [newFilter] describe the same state.
  IncompleteData _rebuild(WriteTree writeTree) {
    final tree = writeTree.withFilter(filter);
    if (identical(tree, _writeTree)) return this;
    return IncompleteData._(writeTree, filter);
  }

  void forEachCompleteNode(Function(Path<Name> k, TreeStructuredData v) f,
          [Path<Name>? path]) =>
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

  static bool _equals(dynamic a, dynamic b) {
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

/// Write tree used by [IncompleteData].
///
/// [addIndex] keeps a sorted map of each child that composes to a value.
/// A child with no value of its own is stored as the composition of its
/// children, so a filtered read is the window of that map.
class WriteTree extends ModifiableTreeNode<Name, TreeStructuredData?> {
  final Map<TreeStructuredDataOrdering, SortedMap<Name, TreeStructuredData>>
      _indexes = {};

  WriteTree(super.value, [super.children]);

  /// Records [ordering] for every child that composes to a value.
  ///
  /// A complete node stores that map on an [IndexedTreeStructuredData]. A
  /// second call for the same ordering does nothing. The map is updated by
  /// later overwrites and removals on the trees copied from this one.
  void addIndex(TreeStructuredDataOrdering ordering) {
    final current = value;
    if (current != null) {
      if (current.children.isEmpty || current.filter != const QueryFilter()) {
        return;
      }
      final indexed = current is IndexedTreeStructuredData
          ? current
          : IndexedTreeStructuredData.from(current);
      if (!identical(indexed, current)) value = indexed;
      indexed.addIndex(ordering);
      return;
    }
    if (_indexes.containsKey(ordering)) return;
    final index = SortedMap<Name, TreeStructuredData>(ordering);
    for (final entry in children.entries) {
      final value = _indexedValue(entry.value as WriteTree);
      if (value != null) index[entry.key] = value;
    }
    _indexes[ordering] = index;
  }

  /// Complete child values in [ordering], when [addIndex] has recorded it.
  SortedMap<Name, TreeStructuredData>? sortedValues(
          TreeStructuredDataOrdering ordering) =>
      _indexes[ordering];

  /// Orderings registered with [addIndex].
  Set<TreeStructuredDataOrdering> get indexedOrderings {
    final current = value;
    if (current is IndexedTreeStructuredData) return current.indexedOrderings;
    return {..._indexes.keys};
  }

  static TreeStructuredData? _indexedValue(WriteTree child) {
    final value = child.value;
    if (value != null) return value.isNil ? null : value;
    final composed = IncompleteData._composeValue(child, const QueryFilter());
    return composed.isNil ? null : composed;
  }

  void _syncIndexes(Name name, WriteTree child) {
    final value = _indexedValue(child);
    for (final index in _indexes.values) {
      index.remove(name);
      if (value != null) index[name] = value;
    }
  }

  WriteTree _replacingChild(Name name, WriteTree child,
      {required bool removeNil}) {
    if (identical(children[name], child)) return this;
    final copy = clone();
    if (removeNil && child.isNil) {
      copy.children.remove(name);
    } else {
      copy.children[name] = child;
    }
    copy._syncIndexes(name, child);
    return copy;
  }

  /// Adds an overwrite at [path].
  ///
  /// When the overwrite does not change this tree, returns [this] (same
  /// instance). Callers may use [identical] to detect no-op updates.
  WriteTree addOverwrite(Path<Name> path, TreeStructuredData data) {
    if (value != null) {
      var newValue = TreeOperation.overwrite(path, data).apply(value!);
      if (identical(newValue, value)) return this;
      return WriteTree(newValue, TreeMap());
    }

    if (path.isEmpty) {
      if (identical(value, data)) return this;
      return WriteTree(data, TreeMap());
    }

    var c = path.first;
    var existing = children[c] as WriteTree?;
    var newChild = (existing ?? WriteTree(null, TreeMap()))
        .addOverwrite(path.skip(1), data);
    if (identical(newChild, existing)) return this;
    return _replacingChild(c, newChild, removeNil: false);
  }

  /// Sets priority at [path].
  ///
  /// When the priority does not change this tree, returns [this].
  WriteTree addPriority(Path<Name> path, Value? data) {
    return addOverwrite(path.child(Name('.priority')),
        data == null ? TreeStructuredData() : TreeStructuredData.leaf(data));
  }

  /// Applies [filter] to the value at this node.
  ///
  /// When filtering does not change this tree, returns [this].
  WriteTree withFilter(QueryFilter filter) {
    if (value == null) return this;
    final filtered = value!.withFilter(filter);
    if (identical(filtered, value)) return this;
    return clone()..value = filtered;
  }

  /// Removes the write at [path].
  ///
  /// When there is no write at [path], returns [this] (same instance).
  WriteTree removeWrite(Path<Name> path) {
    if (path.isEmpty) {
      if (isNil) return this;
      return WriteTree(null, TreeMap());
    }
    var c = children[path.first] as WriteTree?;
    if (c == null) return this;
    var newChild = c.removeWrite(path.skip(1));
    if (identical(newChild, c)) return this;
    return _replacingChild(path.first, newChild, removeNil: false);
  }

  WriteTree clone() {
    final copy = WriteTree(value, TreeMap.from(children));
    for (final entry in _indexes.entries) {
      copy._indexes[entry.key] = entry.value.clone();
    }
    return copy;
  }
}
