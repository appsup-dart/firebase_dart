// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of '../treestructureddata.dart';

class Snapshot extends UnmodifiableMapBase<Name, Snapshot> {
  final dynamic _exportJson;

  Snapshot(this._exportJson);

  late final Value? priority = _extractPriority();

  late final Value? value = _extractValue();

  Value? _extractValue() {
    if (_exportJson == null) {
      return null;
    }

    var json = _exportJson;
    if (json is Map && json.containsKey('.value') && json['.value'] != null) {
      json = json['.value'];
    }

    if (json is! List && (json is! Map || json.containsKey('.sv'))) {
      return Value(json);
    }

    return null;
  }

  Value? _extractPriority() {
    if (_exportJson == null) {
      return null;
    }

    if (_exportJson is Map && _exportJson.containsKey('.priority')) {
      return Value(_exportJson['.priority']);
    }
    return null;
  }

  @override
  Snapshot? operator [](Object? key) {
    if (key is! Name) return null;
    var v = _exportJson;
    if (v is Map && v.containsKey('.value')) v = v['.value'];

    var s = v is List
        ? v[key.asInt()!]
        : v is Map
            ? v[key.asString()]
            : null;

    return Snapshot(s);
  }

  @override
  late final Iterable<Name> keys = _extractKeys();

  Iterable<Name> _extractKeys() {
    var v = _exportJson;
    if (v is Map && v.containsKey('.value')) v = v['.value'];
    if (v is List) {
      return Iterable.generate(v.length, (i) => Name('$i')).toList();
    }
    if (v is Map) {
      return v.keys
          .cast<String>()
          .where((v) => !v.startsWith('.'))
          .map((v) => Name(v))
          .toList();
    }
    return const [];
  }

  bool get isNil => isEmpty && value == null;
  bool get isLeaf => isEmpty && value != null;

  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
    Object? v;
    if (isLeaf) {
      v = value!.toJson();
    } else {
      if (exportFormat) {
        v = map((k, v) => MapEntry(k.asString(), v.toJson(exportFormat)));
      } else {
        final listLength = keys.listLengthOrNull;
        if (listLength != null) {
          final l = List<Object?>.filled(listLength, null, growable: false);
          final vIter = values.iterator;
          for (final key in keys) {
            final moved = vIter.moveNext();
            assert(moved);
            l[key.asInt()!] = vIter.current.toJson(exportFormat);
          }
          v = l;
        } else {
          v = map((k, v) => MapEntry(k.asString(), v.toJson(exportFormat)));
        }
      }
    }

    if (exportFormat && priority != null) {
      return {
        if (v is Map) ...v else '.value': v,
        '.priority': priority!.toJson(),
      };
    }
    return v;
  }
}

class LeafTreeStructuredData extends TreeStructuredData {
  @override
  final Value? priority;

  @override
  final Value? value;

  static final UnmodifiableFilteredMap<Name, TreeStructuredData>
      _emptyChildren = UnmodifiableFilteredMap<Name, TreeStructuredData>(
          FilteredMap(const QueryFilter()));

  LeafTreeStructuredData(this.value, this.priority) : super._();

  @override
  UnmodifiableFilteredMap<Name, TreeStructuredData> get children =>
      _emptyChildren;

  @override
  dynamic toJson([bool exportFormat = false]) {
    if (priority == null || !exportFormat) {
      return value?.toJson();
    } else {
      return {
        '.priority': priority?.toJson(),
        '.value': value?.toJson(),
      };
    }
  }

  @override
  UnmodifiableFilteredMap<Name, TreeStructuredData> get childrenAsFilteredMap =>
      children;

  @override
  Filter<Name, TreeStructuredData> get filter => const QueryFilter();
}

@immutable
abstract class TreeStructuredData extends ComparableTreeNode<Name, Value?> {
  Value? get priority;

  TreeStructuredData._();

  static final TreeStructuredData _nill = LeafTreeStructuredData(null, null);

  factory TreeStructuredData({QueryFilter? filter}) {
    if (filter == null || filter == const QueryFilter()) {
      return _nill;
    }
    return TreeStructuredDataImpl._(null, FilteredMap(filter), null);
  }

  factory TreeStructuredData.leaf(Value value, [Value? priority]) =>
      LeafTreeStructuredData(value, priority);

  factory TreeStructuredData.nonLeaf(Map<Name, TreeStructuredData> children,
          [Value? priority]) =>
      TreeStructuredDataImpl._(
          null,
          children is FilteredMap
              ? children as FilteredMap<Name, TreeStructuredData>
              : (FilteredMap(const QueryFilter())
                ..addAll({
                  for (var e in children.entries)
                    if (!e.value.isNil) e.key: e.value
                })),
          priority);

  factory TreeStructuredData.fromExportJson(dynamic json,
          [QueryFilter filter = const QueryFilter()]) =>
      TreeStructuredDataFromExportJson(json, filter);

  factory TreeStructuredData.fromJson(dynamic json, [dynamic priority]) {
    if (json == null) {
      return TreeStructuredData();
    }
    if (json is! Map &&
        json is! bool &&
        json is! num &&
        json is! String &&
        json is! List) {
      try {
        json = json.asMap();
      } on NoSuchMethodError {
        // ignore
        try {
          json = json.toJson();
        } on NoSuchMethodError {
          // ignore
        }
      }
    }

    if (json is Map && json.containsKey('.priority')) {
      priority = json['.priority'];
    }
    priority = priority == null ? null : Value(priority);

    if (json is Map && json.containsKey('.value') && json['.value'] != null) {
      json = json['.value'];
    }

    if (json is List) {
      json = <int, dynamic>{...json.asMap()}..removeWhere((k, v) => v == null);
    }
    if (json is! Map || json.containsKey('.sv')) {
      var value = Value(json);
      return TreeStructuredData.leaf(value, priority);
    }

    var children = {
      for (var k in json.keys.where((k) => k is! String || !k.startsWith('.')))
        Name(k.toString()): TreeStructuredData.fromJson(json[k], null)
    };

    return TreeStructuredData.nonLeaf(children, priority);
  }

  Filter<Name, TreeStructuredData> get filter;

  TreeStructuredData withPriority(Value? priority) {
    if (this.priority == priority) return this;
    return TreeStructuredDataImpl._(value, childrenAsFilteredMap, priority);
  }

  @override
  Map<Name, TreeStructuredData> get children;

  UnmodifiableFilteredMap<Name, TreeStructuredData> get childrenAsFilteredMap;

  TreeStructuredData view(
          {required Pair start,
          required Pair end,
          int? limit,
          bool reversed = false}) =>
      TreeStructuredDataImpl._(
          value,
          childrenAsFilteredMap.filteredMapView(
              start: start, end: end, limit: limit, reversed: reversed),
          priority);

  TreeStructuredData withFilter(Filter<Name, TreeStructuredData> f) {
    if (filter == f) return this;
    if (f.ordering == filter.ordering) {
      return TreeStructuredDataImpl._(
          f.limits ? null : value,
          childrenAsFilteredMap.filteredMap(
              start: Pair.min(f.startKey, f.startValue),
              end: Pair.max(f.endKey, f.endValue),
              limit: f.limit,
              reversed: f.reversed),
          f.limits ? null : priority);
    }
    return TreeStructuredDataImpl._(f.limits ? null : value,
        FilteredMap(f)..addAll(children), f.limits ? null : priority);
  }

  dynamic toJson([bool exportFormat = false]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TreeStructuredData) return false;
    if (isNil && other.isNil) return true;
    return other.priority == priority &&
        (isLeaf
            ? other.isLeaf && value == other.value
            : !other.isLeaf &&
                const MapEquality().equals(children, other.children));
  }

  @override
  late final int hashCode = Object.hash(
      value, isNil ? null : priority, const MapEquality().hash(children));

  @override
  String toString() => 'TreeStructuredData[${toJson(true)}]';

  late final String hash = _computeHash();

  String _computeHash() {
    var toHash = '';

    if (priority != null) {
      toHash += 'priority:${priority!._hashText}';
    }

    if (isLeaf) {
      toHash += value!._hashText;
    }
    children.forEach((key, child) {
      toHash += ':${key.asString()}:${child.hash}';
    });
    return (toHash == ''
        ? ''
        : base64.encode(sha1.convert(utf8.encode(toHash)).bytes));
  }

  TreeStructuredData withoutChild(Name k) {
    if (!children.containsKey(k)) return this;
    return TreeStructuredData.nonLeaf(
        childrenAsFilteredMap._map.clone()..remove(k), priority);
  }

  TreeStructuredData withChild(Name k, TreeStructuredData newChild) {
    if (children[k] == newChild) return this;
    return TreeStructuredData.nonLeaf(
        childrenAsFilteredMap._map.clone()..[k] = newChild, priority);
  }
}

class TreeStructuredDataFromExportJson extends TreeStructuredData {
  final Snapshot _data;

  @override
  final QueryFilter filter;

  static bool _hasNulls(dynamic v) {
    if (v is List) {
      // nulls is a list are allowed
      return v.any((v) => v != null && _hasNulls(v));
    }
    if (v is Map) {
      return v.values.any((v) => v == null || _hasNulls(v));
    }
    return false;
  }

  TreeStructuredDataFromExportJson._(this._data, this.filter)
      : assert(!_hasNulls(_data._exportJson)),
        super._();

  TreeStructuredDataFromExportJson(dynamic exportJson,
      [QueryFilter filter = const QueryFilter()])
      : this._(Snapshot(exportJson), filter);

  @override
  late final Map<Name, TreeStructuredData> children = _data.map((k, v) =>
      MapEntry(k, TreeStructuredDataFromExportJson._(v, const QueryFilter())));

  @override
  Value? get priority => _data.priority;

  @override
  Value? get value => _data.value;

  @override
  dynamic toJson([bool exportFormat = false]) => _data.toJson(exportFormat);

  @override
  bool get isEmpty => _data.isEmpty;

  @override
  bool get isNil => _data.isNil;

  @override
  bool get isLeaf => _data.isLeaf;

  @override
  late final UnmodifiableFilteredMap<Name, TreeStructuredData>
      childrenAsFilteredMap = UnmodifiableFilteredMap<Name, TreeStructuredData>(
          FilteredMap(filter)..addAll(children));
}

class TreeStructuredDataImpl extends TreeStructuredData {
  @override
  final Value? priority;

  @override
  final Value? value;

  @override
  final UnmodifiableFilteredMap<Name, TreeStructuredData> children;

  TreeStructuredDataImpl._(this.value,
      FilteredMap<Name, TreeStructuredData>? children, this.priority)
      : children = UnmodifiableFilteredMap<Name, TreeStructuredData>(
            children ?? FilteredMap(const QueryFilter())),
        assert(children == null || children.values.every((v) => !v.isNil)),
        super._();

  @override
  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
    if (!exportFormat) {
      final listLength = children.keys.listLengthOrNull;
      if (listLength != null) {
        return [
          for (var i = 0; i < listLength; i++) children[Name('$i')]?.toJson()
        ];
      }
    }

    var c = Map<String, dynamic>.fromIterables(
        children.keys.map((k) => k.toString()),
        children.values.map((v) => v.toJson(exportFormat)));

    if (exportFormat && priority != null) {
      if (isLeaf) c = {'.value': value!.toJson()};
      return <String, dynamic>{'.priority': priority!.toJson()}..addAll(c);
    }
    return isLeaf ? value!.toJson() : c;
  }

  @override
  Filter<Name, TreeStructuredData> get filter => children.filter;

  @override
  UnmodifiableFilteredMap<Name, TreeStructuredData> get childrenAsFilteredMap =>
      children;
}

/// A [TreeStructuredData] stored with the default filter: unlimited, ordered
/// by priority.
///
/// [addIndex] keeps an extra sorted map of these children. A node with any
/// other filter is a plain [TreeStructuredData] and cannot be indexed.
class IndexedTreeStructuredData extends TreeStructuredDataImpl {
  final Map<TreeStructuredDataOrdering, SortedMap<Name, TreeStructuredData>>
      _indexes;

  /// An indexed copy of [node].
  ///
  /// [node] must use the default filter: unlimited, ordered by priority.
  factory IndexedTreeStructuredData.from(TreeStructuredData node) {
    return IndexedTreeStructuredData._(
      node.value,
      node.childrenAsFilteredMap._map,
      node.priority,
      {},
    );
  }

  IndexedTreeStructuredData._(
    Value? value,
    FilteredMap<Name, TreeStructuredData> children,
    Value? priority,
    this._indexes,
  )   : assert(children.filter == const QueryFilter()),
        super._(value, children, priority);

  /// Remembers [ordering] as a sorted map of [children].
  ///
  /// The default priority ordering is already how [children] are stored, so
  /// registering it does nothing. A later [withFilter] for [ordering] reads
  /// this map instead of sorting every child again.
  void addIndex(TreeStructuredDataOrdering ordering) {
    if (ordering == const TreeStructuredDataOrdering.byPriority()) return;
    if (_indexes.containsKey(ordering)) return;
    _indexes[ordering] = SortedMap<Name, TreeStructuredData>(ordering)
      ..addAll(children);
  }

  /// Orderings registered with [addIndex], plus this node's priority ordering.
  Set<TreeStructuredDataOrdering> get indexedOrderings => {
        ..._indexes.keys,
        filter.ordering as TreeStructuredDataOrdering,
      };

  @override
  TreeStructuredData withFilter(Filter<Name, TreeStructuredData> f) {
    if (filter == f) return this;
    final ordering = f.ordering;
    final index = _indexes[ordering];
    if (index == null) return super.withFilter(f);
    return TreeStructuredDataImpl._(
      f.limits ? null : value,
      index.filteredMap(
        start: Pair.min(f.startKey, f.startValue),
        end: Pair.max(f.endKey, f.endValue),
        limit: f.limit,
        reversed: f.reversed,
      ),
      f.limits ? null : priority,
    );
  }

  @override
  IndexedTreeStructuredData withPriority(Value? priority) {
    if (this.priority == priority) return this;
    return IndexedTreeStructuredData._(
      value,
      childrenAsFilteredMap._map,
      priority,
      _cloneIndexes(),
    );
  }

  @override
  IndexedTreeStructuredData withoutChild(Name k) {
    if (!children.containsKey(k)) return this;
    return _withChildren(_clonedChildren()..remove(k), {k});
  }

  @override
  IndexedTreeStructuredData withChild(Name k, TreeStructuredData newChild) {
    if (children[k] == newChild) return this;
    return _withChildren(_clonedChildren()..[k] = newChild, {k});
  }

  FilteredMap<Name, TreeStructuredData> _clonedChildren() =>
      childrenAsFilteredMap._map.clone()
          as FilteredMap<Name, TreeStructuredData>;

  IndexedTreeStructuredData _withChildren(
    FilteredMap<Name, TreeStructuredData> children,
    Set<Name> changed,
  ) {
    final next = IndexedTreeStructuredData._(
      value,
      children,
      priority,
      _cloneIndexes(),
    );
    for (final name in changed) {
      next._reindex(name);
    }
    return next;
  }

  Map<TreeStructuredDataOrdering, SortedMap<Name, TreeStructuredData>>
      _cloneIndexes() => {
            for (final entry in _indexes.entries)
              entry.key: entry.value.clone(),
          };

  void _reindex(Name name) {
    final child = children[name];
    final keep = child != null && !child.isNil;
    for (final index in _indexes.values) {
      index.remove(name);
      if (keep) index[name] = child;
    }
  }
}

String _doubleToIEEE754String(num v) {
  var l = Float64List.fromList([v.toDouble()]);
  var hex = '';
  for (var i = 0; i < 8; i++) {
    var b = l.buffer.asByteData().getUint8(i).toRadixString(16);
    if (b.length == 1) b = '0$b';
    hex = '$b$hex';
  }
  return hex;
}

class UnmodifiableFilteredMap<K extends Comparable, V>
    extends UnmodifiableMapView<K, V> implements FilteredMap<K, V> {
  final FilteredMap<K, V> _map;

  factory UnmodifiableFilteredMap(FilteredMap<K, V> map) =>
      map is UnmodifiableFilteredMap
          ? map as UnmodifiableFilteredMap<K, V>
          : UnmodifiableFilteredMap._(map);

  UnmodifiableFilteredMap._(FilteredMap<K, V> super.map) : _map = map;

  @override
  SortedMap<K, V> clone() => this;

  @override
  KeyValueInterval get completeInterval => _map.completeInterval;

  @override
  Filter<K, V> get filter => _map.filter;

  @override
  FilteredMap<K, V> filteredMap(
      {required Pair start,
      required Pair end,
      int? limit,
      bool reversed = false}) {
    return _map.filteredMap(
        start: start, end: end, limit: limit, reversed: reversed);
  }

  @override
  FilteredMapView<K, V> filteredMapView(
      {required Pair start,
      required Pair end,
      int? limit,
      bool reversed = false}) {
    return _map.filteredMapView(
        start: start, end: end, limit: limit, reversed: reversed);
  }

  @override
  K firstKeyAfter(K key, {K Function()? orElse}) => _map.firstKeyAfter(key);

  @override
  K lastKeyBefore(K key, {K Function()? orElse}) => _map.lastKeyBefore(key);

  @override
  Ordering get ordering => _map.ordering;

  @override
  Iterable<K> subkeys(
      {required Pair start,
      required Pair end,
      int? limit,
      bool reversed = false}) {
    return _map.subkeys(
        start: start, end: end, limit: limit, reversed: reversed);
  }
}

extension on Iterable<Name> {
  int? get listLengthOrNull {
    var max = 0;
    var numItems = 0;
    for (final k in this) {
      final ki = k.asInt();
      // Key must be an integer greater or equal to 0
      if (ki == null || ki < 0) {
        return null;
      }

      numItems++;
      max = ki;
    }
    // If the largest key is 1, there must at least be 2 non-null entries, so the max numItems is 4
    if (max + 1 > numItems * 2) {
      return null;
    }
    return max + 1; // List length is one more than the highest key
  }
}
