part of firebase.treestructureddata;

abstract class TreeStructuredDataOrdering extends Ordering {
  factory TreeStructuredDataOrdering(String orderBy) {
    if (orderBy == null) return null;
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
  TreeStructuredData mapValue(covariant dynamic v);

  @override
  int get hashCode => orderBy.hashCode;

  @override
  bool operator ==(Object other) =>
      other is TreeStructuredDataOrdering && other.orderBy == orderBy;
}

class PriorityOrdering extends TreeStructuredDataOrdering {
  const PriorityOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) =>
      TreeStructuredData.leaf(v?.priority);

  @override
  String get orderBy => '.priority';
}

class ValueOrdering extends TreeStructuredDataOrdering {
  const ValueOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) =>
      TreeStructuredData.leaf(v.value);

  @override
  String get orderBy => '.value';
}

class KeyOrdering extends TreeStructuredDataOrdering {
  const KeyOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) => null;

  @override
  String get orderBy => '.key';
}

class ChildOrdering extends TreeStructuredDataOrdering {
  final String child;

  const ChildOrdering(this.child) : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) {
    var parts = child.split('/').map((v) => Name(v));
    return parts.fold(v, (v, c) => v.children[c] ?? TreeStructuredData());
  }

  @override
  String get orderBy => child;
}

class QueryFilter extends Filter<Name, TreeStructuredData> {
  const QueryFilter(
      {KeyValueInterval validInterval = const KeyValueInterval(),
      int limit,
      bool reversed = false,
      TreeStructuredDataOrdering ordering =
          const TreeStructuredDataOrdering.byPriority()})
      : assert(!reversed || limit != null),
        super(
            ordering: ordering,
            limit: limit,
            reversed: reversed,
            validInterval: validInterval);

  static KeyValueInterval _updateInterval(
      KeyValueInterval validInterval,
      String startAtKey,
      dynamic startAtValue,
      String endAtKey,
      dynamic endAtValue) {
    if (startAtKey != null || startAtValue != null) {
      validInterval = validInterval.startAt(
          startAtKey == null ? null : Name(startAtKey),
          startAtValue == null
              ? null
              : TreeStructuredData(value: Value(startAtValue)));
    }
    if (endAtKey != null || endAtValue != null) {
      validInterval = validInterval.endAt(
          endAtKey == null ? null : Name(endAtKey),
          endAtValue == null
              ? null
              : TreeStructuredData(value: Value(endAtValue)));
    }
    return validInterval;
  }

  Name get endKey => validInterval?.end?.key;

  Name get startKey => validInterval?.start?.key;

  TreeStructuredData get endValue => validInterval?.end?.value;

  TreeStructuredData get startValue => validInterval?.start?.value;

  String get orderBy => (ordering as TreeStructuredDataOrdering).orderBy;

  QueryFilter copyWith(
      {String orderBy,
      String startAtKey,
      dynamic startAtValue,
      String endAtKey,
      dynamic endAtValue,
      int limit,
      bool reverse}) {
    var ordering = TreeStructuredDataOrdering(orderBy) ?? this.ordering;
    var validInterval = (ordering is KeyOrdering)
        ? _updateInterval(
            this.validInterval, startAtValue, null, endAtValue, null)
        : _updateInterval(
            this.validInterval, startAtKey, startAtValue, endAtKey, endAtValue);

    return QueryFilter(
        ordering: ordering,
        validInterval: validInterval,
        limit: limit ?? this.limit,
        reversed: reverse ?? reversed);
  }

  bool get limits => limit != null || !validInterval.isUnlimited;

  KeyValueInterval get validTypedInterval => validInterval;

  @override
  String toString() =>
      'QueryFilter[orderBy: $orderBy, limit: $limit, reversed: $reversed, start: (${validInterval.start.key}, ${validInterval.start.value}), end: (${validInterval.end.key}, ${validInterval.end.value})]';
}
