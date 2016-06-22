// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

class ServerValue {
  final String type;
  const ServerValue._(this.type);

  static const ServerValue timestamp = const ServerValue._("timestamp");

  static const Map<String, ServerValue> values = const {"timestamp": timestamp};

  Map<String, String> toJson() => {".sv": type};

  static TreeStructuredData resolve(TreeStructuredData value,
      Map<ServerValue, Value> serverValues) {
    if (value.isLeaf) {
      return value.value.value is ServerValue ?
      new TreeStructuredData.leaf(serverValues[value.value.value]) : value;
    }
    var newValue = value.clone();
    for (var k in newValue.children.keys.toList()) {
      newValue.children[k] = resolve(newValue.children[k], serverValues);
    }
    return newValue;
  }
}

class Value implements Comparable<Value> {
  final dynamic value;

  factory Value(dynamic value) {
    if (value == null) return null;
    if (value is bool) return new Value.bool(value);
    if (value is num) return new Value.num(value);
    if (value is String) return new Value.string(value);
    if (value is Map && value.containsKey(".sv"))
      return new Value.server(value[".sv"]);
    throw new ArgumentError("Unsupported value type ${value.runtimeType}");
  }

  const Value._(this.value);
  const Value.bool(bool value) : this._(value);
  const Value.num(num value) : this._(value);
  const Value.string(String value) : this._(value);
  Value.server(String type) : this._(ServerValue.values[type]);

  bool get isBool => value is bool;
  bool get isNum => value is num;
  bool get isString => value is String;
  bool get isServerValue => value is ServerValue;

  int get typeOrder =>
      isServerValue ? 0 : isBool ? 1 : isNum ? 2 : isString ? 3 : 4;

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
  String toString() => "Value[$value]";

  String get _hashText {
    if (value is num) {
      return "number:${_doubleToIEEE754String(value)}";
    } else if (value is bool) {
      return "boolean:$value";
    } else if (value is String) {
      return "string:$value";
    }
    throw new StateError("Invalid value to hash $value");
  }
}
