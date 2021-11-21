// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

@immutable
abstract class TreeStructuredData extends ComparableTreeNode<Name, Value?> {
  Value? get priority;

  TreeStructuredData._();

  factory TreeStructuredData(
          {Value? priority, Value? value, QueryFilter? filter}) =>
      TreeStructuredDataImpl._(
          value, FilteredMap(filter ?? QueryFilter()), priority);

  factory TreeStructuredData.leaf(Value value, [Value? priority]) =>
      TreeStructuredDataImpl._(value, null, priority);

  factory TreeStructuredData.nonLeaf(Map<Name, TreeStructuredData> children,
          [Value? priority]) =>
      TreeStructuredDataImpl._(
          null,
          children is FilteredMap
              ? children as FilteredMap<Name, TreeStructuredData>
              : (FilteredMap(const QueryFilter())..addAll(children)),
          priority);

  factory TreeStructuredData.fromJson(json, [priority]) {
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

  TreeStructuredData withPriority(Value? priority) =>
      TreeStructuredDataImpl._(value, children, priority);

  @override
  UnmodifiableFilteredMap<Name, TreeStructuredData> get children;

  TreeStructuredData view(
          {required Pair start,
          required Pair end,
          int? limit,
          bool reversed = false}) =>
      TreeStructuredDataImpl._(
          value,
          children.filteredMapView(
              start: start, end: end, limit: limit, reversed: reversed),
          priority);

  TreeStructuredData withFilter(Filter<Name, TreeStructuredData> f) {
    if (children.filter == f) return this;
    if (f.ordering == children.filter.ordering) {
      return TreeStructuredDataImpl._(
          value,
          children.filteredMap(
              start: Pair.min(f.startKey, f.startValue),
              end: Pair.max(f.endKey, f.endValue),
              limit: f.limit,
              reversed: f.reversed),
          priority);
    }
    return TreeStructuredDataImpl._(
        value, FilteredMap(f)..addAll(children), priority);
  }

  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
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
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    return other is TreeStructuredData &&
        other.priority == priority &&
        (isLeaf
            ? other.isLeaf && value == other.value
            : !other.isLeaf &&
                const MapEquality().equals(children, other.children));
  }

  @override
  late final int hashCode =
      quiver.hash3(value, priority, const MapEquality().hash(children));

  @override
  String toString() => 'TreeStructuredData[${toJson(true)}]';

  late final String? hash = _computeHash();

  String? _computeHash() {
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
        children._map.clone()..remove(k), priority);
  }

  TreeStructuredData withChild(Name k, TreeStructuredData newChild) {
    return TreeStructuredData.nonLeaf(
        children._map.clone()..[k] = newChild, priority);
  }
}

class TreeStructuredDataImpl extends TreeStructuredData {
  @override
  final Value? priority;

  @override
  final Value? value;

  @override
  final UnmodifiableFilteredMap<Name, TreeStructuredData> children;

  TreeStructuredDataImpl._(this.value,
      FilteredMap<Name, TreeStructuredData>? children, Value? priority)
      : priority = priority,
        assert(children == null || children is FilteredMap),
        children = UnmodifiableFilteredMap<Name, TreeStructuredData>(
            children ?? FilteredMap(const QueryFilter())),
        super._();
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

  UnmodifiableFilteredMap._(FilteredMap<K, V> map)
      : _map = map,
        super(map);

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
