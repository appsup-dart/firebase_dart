// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

extension ServerValueX on ServerValue {
  static const Map<String, ServerValue> values = {
    'timestamp': ServerValue.timestamp
  };

  static TreeStructuredData resolve(
      TreeStructuredData value, Map<ServerValue, Value> serverValues) {
    if (value.isLeaf) {
      return value.value!.value is ServerValue
          ? TreeStructuredData.leaf(serverValues[value.value!.value]!)
          : value;
    }

    for (var k in value.children.keys.toList()) {
      var newChild = resolve(value.children[k]!, serverValues);
      if (newChild != value.children[k]) {
        value = value.withChild(k, newChild);
      }
    }
    return value;
  }
}

class Value implements Comparable<Value> {
  final dynamic value;

  factory Value(dynamic value) {
    if (value is bool) return Value.bool(value);
    if (value is num) return Value.num(value);
    if (value is String) return Value.string(value);
    if (value is Map && value.containsKey('.sv')) {
      return Value.server(value['.sv']);
    }
    ServerValue;
    throw ArgumentError('Unsupported value type ${value.runtimeType}');
  }

  const Value._(this.value);

  const Value.bool(bool value) : this._(value);

  const Value.num(num value) : this._(value);

  const Value.string(String value) : this._(value);

  Value.server(String? type) : this._(ServerValueX.values[type!]);

  bool get isBool => value is bool;

  bool get isNum => value is num;

  bool get isString => value is String;

  bool get isServerValue => value is ServerValue;

  int get typeOrder => isServerValue
      ? 0
      : isBool
          ? 1
          : isNum
              ? 2
              : isString
                  ? 3
                  : 4;

  @override
  int compareTo(Value other) {
    var thisIndex = typeOrder;
    var otherIndex = other.typeOrder;

    if (otherIndex == thisIndex) {
      if (isServerValue) return 0;
      if (isBool) {
        if (!other.isBool) return -1;
        if (value == other.value) return 0;
        return !value ? -1 : 1;
      }
      return Comparable.compare(value, other.value);
    }
    return thisIndex - otherIndex;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(dynamic other) => other is Value && value == other.value;

  dynamic toJson() => value;

  @override
  String toString() => 'Value[$value]';

  String get _hashText {
    if (value is num) {
      return 'number:${_doubleToIEEE754String(value)}';
    } else if (value is bool) {
      return 'boolean:$value';
    } else if (value is String) {
      return 'string:$value';
    }
    throw StateError('Invalid value to hash $value');
  }
}
