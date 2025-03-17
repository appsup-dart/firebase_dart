// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of '../treestructureddata.dart';

extension ServerValueX on ServerValue {
  static final Map<String, ServerValue Function(dynamic)> factories = {
    'timestamp': (v) => ServerValue.timestamp,
    'increment': (v) => ServerValue.increment(v),
  };

  static TreeStructuredData resolve(TreeStructuredData value,
      TreeStructuredData existing, Map<ServerValue, Value> serverValues) {
    if (value.isLeaf) {
      var s = value.value!.value;
      if (s is ServerValue) {
        if (s['.sv'] is String) {
          return TreeStructuredData.leaf(serverValues[s]!);
        }
        var op = s['.sv'] as Map;
        if (op.keys.single == 'increment') {
          var delta = op.values.single;
          if (existing.isLeaf) {
            var existingValue = existing.value!.value;
            if (existingValue is num) {
              return TreeStructuredData.leaf(Value.num(existingValue + delta));
            }
          }
          return TreeStructuredData.leaf(Value.num(delta));
        }
        throw StateError('Invalid server value $s');
      }
      return value;
    }

    for (var k in value.children.keys.toList()) {
      var newChild = resolve(value.children[k]!,
          existing.children[k] ?? TreeStructuredData._nill, serverValues);
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
    if (value is num) {
      if (value.isNaN) throw ArgumentError('NaN is not supported');
      if (value.isInfinite) throw ArgumentError('Infinity is not supported');
      return Value.num(value);
    }
    if (value is String) return Value.string(value);
    if (value is Map && value.containsKey('.sv')) {
      return Value.server(value['.sv']);
    }
    throw ArgumentError('Unsupported value type ${value.runtimeType}');
  }

  const Value._(this.value);

  const Value.bool(bool value) : this._(value);

  const Value.num(num value) : this._(value);

  const Value.string(String value) : this._(value);

  Value.server(dynamic value)
      : this._(ServerValueX.factories[
                value is String ? value : (value as Map).keys.single]!(
            value is String ? null : (value as Map).values.single));

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
  bool operator ==(Object other) => other is Value && value == other.value;

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
