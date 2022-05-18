part of firebase.treestructureddata;

abstract class TreeStructuredDataOrdering extends Ordering {
  factory TreeStructuredDataOrdering(String orderBy) {
    switch (orderBy) {
      case '.key':
        return const TreeStructuredDataOrdering.byKey();
      case '.value':
        return const TreeStructuredDataOrdering.byValue();
      case '.priority':
        return const TreeStructuredDataOrdering.byPriority();
      default:
        assert(!orderBy.startsWith('.'));
        return TreeStructuredDataOrdering.byChild(orderBy);
    }
  }

  const TreeStructuredDataOrdering._() : super.byValue();

  const factory TreeStructuredDataOrdering.byValue() = ValueOrdering;

  const factory TreeStructuredDataOrdering.byKey() = KeyOrdering;

  const factory TreeStructuredDataOrdering.byPriority() = PriorityOrdering;

  const factory TreeStructuredDataOrdering.byChild(String child) =
      ChildOrdering;

  String get orderBy;

  @override
  TreeStructuredData mapValue(covariant TreeStructuredData value);

  @override
  int get hashCode => orderBy.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TreeStructuredDataOrdering && other.orderBy == orderBy;
}

class PriorityOrdering extends TreeStructuredDataOrdering {
  const PriorityOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData value) =>
      value.priority == null
          ? TreeStructuredData()
          : TreeStructuredData.leaf(value.priority!);

  @override
  String get orderBy => '.priority';
}

class ValueOrdering extends TreeStructuredDataOrdering {
  const ValueOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData value) {
    if (value.isEmpty) return value;
    return ChildOrdering._object;
  }

  @override
  String get orderBy => '.value';
}

class KeyOrdering extends TreeStructuredDataOrdering {
  static final _empty = TreeStructuredData();

  const KeyOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData value) => _empty;

  @override
  String get orderBy => '.key';
}

class ChildOrdering extends TreeStructuredDataOrdering {
  final String child;

  const ChildOrdering(this.child) : super._();

  static final TreeStructuredData _object =
      TreeStructuredData.fromJson({'placeholder': 0});

  @override
  TreeStructuredData mapValue(TreeStructuredData value) {
    var parts = child.split('/').map((v) => Name(v));
    var d = parts.fold<TreeStructuredData>(
        value, (v, c) => v.children[c] ?? TreeStructuredData());

    if (d.isEmpty) return d;
    return _object;
  }

  @override
  String get orderBy => child;
}

extension QueryFilterX on Filter<Name, TreeStructuredData?> {
  Name? get endKey => validInterval.end.key as Name?;

  Name? get startKey => validInterval.start.key as Name?;

  TreeStructuredData? get endValue =>
      validInterval.end.value as TreeStructuredData?;

  TreeStructuredData? get startValue =>
      validInterval.start.value as TreeStructuredData?;
}

class QueryFilter extends Filter<Name, TreeStructuredData> {
  const QueryFilter(
      {KeyValueInterval validInterval = const KeyValueInterval(),
      int? limit,
      bool reversed = false,
      TreeStructuredDataOrdering ordering =
          const TreeStructuredDataOrdering.byPriority()})
      : assert(!reversed || limit != null),
        super(
            ordering: ordering,
            limit: limit,
            reversed: reversed,
            validInterval: validInterval);

  String get orderBy => (ordering as TreeStructuredDataOrdering).orderBy;

  QueryFilter copyWith(
      {String? orderBy,
      Name? startAtKey,
      TreeStructuredData? startAtValue,
      Name? endAtKey,
      TreeStructuredData? endAtValue,
      int? limit,
      bool? reverse}) {
    var ordering =
        orderBy == null ? this.ordering : TreeStructuredDataOrdering(orderBy);
    var validInterval = this.validInterval;
    if (startAtKey != null) {
      validInterval = KeyValueInterval.fromPairs(
          Pair.min(startAtKey, startAtValue), validInterval.end);
    }
    if (endAtKey != null) {
      validInterval = KeyValueInterval.fromPairs(
        validInterval.start,
        Pair.max(endAtKey, endAtValue),
      );
    }
    return QueryFilter(
        ordering: ordering as TreeStructuredDataOrdering,
        validInterval: validInterval,
        limit: limit ?? this.limit,
        reversed: reverse ?? reversed);
  }

  KeyValueInterval get validTypedInterval => validInterval;

  @override
  String toString() =>
      'QueryFilter[orderBy: $orderBy, limit: $limit, reversed: $reversed, start: (${validInterval.start.key}, ${validInterval.start.value}), end: (${validInterval.end.key}, ${validInterval.end.value})]';
}

extension FilterX<K extends Comparable, V> on Filter<K, V> {
  bool get limits => limit != null || !validInterval.isUnlimited;
}
