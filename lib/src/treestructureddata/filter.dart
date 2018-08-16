part of firebase.treestructureddata;

abstract class TreeStructuredDataOrdering extends Ordering {
  factory TreeStructuredDataOrdering(String orderBy) {
    if (orderBy == null) return null;
    switch (orderBy) {
      case ".key":
        return const TreeStructuredDataOrdering.byKey();
      case ".value":
        return const TreeStructuredDataOrdering.byValue();
      case ".priority":
        return const TreeStructuredDataOrdering.byPriority();
      default:
        assert(!orderBy.startsWith("."));
        return new TreeStructuredDataOrdering.byChild(orderBy);
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
      new TreeStructuredData.leaf(v?.priority);

  @override
  String get orderBy => ".priority";
}

class ValueOrdering extends TreeStructuredDataOrdering {
  const ValueOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) =>
      new TreeStructuredData.leaf(v.value);

  @override
  String get orderBy => ".value";
}

class KeyOrdering extends TreeStructuredDataOrdering {
  const KeyOrdering() : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) => null;

  @override
  String get orderBy => ".key";
}

class ChildOrdering extends TreeStructuredDataOrdering {
  final String child;

  const ChildOrdering(this.child) : super._();

  @override
  TreeStructuredData mapValue(TreeStructuredData v) {
    var parts = child.split("/").map((v) => new Name(v));
    return parts.fold(v, (v, c) => v.children[c] ?? new TreeStructuredData());
  }

  @override
  String get orderBy => child;
}

class QueryFilter extends Filter<Name, TreeStructuredData> {
  const QueryFilter(
      {KeyValueInterval validInterval: const KeyValueInterval(),
      int limit,
      bool reversed: false,
      TreeStructuredDataOrdering ordering:
          const TreeStructuredDataOrdering.byPriority()})
      : super(
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
          startAtKey == null ? null : new Name(startAtKey),
          startAtValue == null
              ? null
              : new TreeStructuredData(value: new Value(startAtValue)));
    }
    if (endAtKey != null || endAtValue != null) {
      validInterval = validInterval.endAt(
          endAtKey == null ? null : new Name(endAtKey),
          endAtValue == null
              ? null
              : new TreeStructuredData(value: new Value(endAtValue)));
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
    var ordering = new TreeStructuredDataOrdering(orderBy) ?? this.ordering;
    var validInterval = (ordering is KeyOrdering)
        ? _updateInterval(
            this.validInterval, startAtValue, null, endAtValue, null)
        : _updateInterval(
            this.validInterval, startAtKey, startAtValue, endAtKey, endAtValue);

    return new QueryFilter(
        ordering: ordering,
        validInterval: validInterval,
        limit: limit ?? this.limit,
        reversed: reverse ?? this.reversed);
  }

  bool get limits => limit != null || !validInterval.isUnlimited;

  KeyValueInterval get validTypedInterval => validInterval;

  @override
  String toString() =>
      "QueryFilter[orderBy: $orderBy, limit: $limit, reversed: $reversed, start: (${validInterval.start.key}, ${validInterval.start.value}), end: (${validInterval.end.key}, ${validInterval.end.value})]";
}
