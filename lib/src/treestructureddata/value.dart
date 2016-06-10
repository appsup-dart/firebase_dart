// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;

class ServerValue {
  final String type;
  const ServerValue._(this.type);

  static const timestamp = const ServerValue._("TIMESTAMP");

  static const values = const {
    "TIMESTAMP": timestamp
  };

  toJson() => {".sv": type};
}

class Value implements Comparable<Value> {

  final dynamic value;

  const Value._(this.value);
  const Value.bool(bool value) : this._(value);
  const Value.num(num value) : this._(value);
  const Value.string(String value) : this._(value);
  Value.server(String type) : this._(ServerValue.values[type]);

  factory Value(dynamic value) {
    if (value==null) return null;
    if (value is bool) return new Value.bool(value);
    if (value is num) return new Value.num(value);
    if (value is String) return new Value.string(value);
    if (value is Map&&value.containsKey(".sv")) return new Value.server(value[".sv"]);
    throw new ArgumentError("Unsupported value type ${value.runtimeType}");
  }

  bool get isBool => value is bool;
  bool get isNum => value is num;
  bool get isString => value is String;
  bool get isServerValue => value is ServerValue;

  int get typeOrder => isServerValue ? 0 : isBool ? 1 : isNum ? 2 : isString ? 3 : 4;

  @override
  int compareTo(Value other) {
    var thisIndex = typeOrder;
    var otherIndex = other.typeOrder;

    if (otherIndex == thisIndex) {
      if (isServerValue) return 0;
      if (isBool) {
        if (!other.isBool) return -1;
        if (value==other.value) return 0;
        return !value ? -1 : 1;
      }
      return Comparable.compare(value, other.value);
    }
    return thisIndex - otherIndex;
  }

  int get hashCode => value.hashCode;
  bool operator==(other) => other is Value&&value==other.value;

  toJson() => value;

  toString() => "Value[$value]";
}

