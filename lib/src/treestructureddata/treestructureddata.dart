// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;


class TreeStructuredData extends TreeNode<Name,Value> {

  Value priority;


  TreeStructuredData({this.priority, Value value, Filter filter}) :
      super(value, filter==null ? null : new FilteredMap(filter));

  TreeStructuredData._(Value value, Map<Name,TreeStructuredData> children,
      Value priority) :
        super(value, children), priority = priority;

  TreeStructuredData.leaf(Value value, [Value priority]) :
        this._(value, null, priority);


  TreeStructuredData.children(Map<Name,TreeStructuredData> children, [Value priority]) :
      this._(null, children, priority);

  TreeStructuredData clone() => new TreeStructuredData._(value, children, priority);

  factory TreeStructuredData.fromJson(json, [priority, Map<ServerValue, Value> serverValues]) {
    if (json == null) {
      return new TreeStructuredData();
    }
    if (json is Map && json.containsKey(".priority")) {
      priority = json[".priority"];
    }
    priority = priority==null ? null : new Value(priority);

    if (json is Map && json.containsKey(".value") && json[".value"] != null) {
      json = json[".value"];
    }

    if (json is !Map || json.containsKey(".sv") ) {
      var value = new Value(json);
      if (value is ServerValue) value = serverValues[value];
      return new TreeStructuredData.leaf(value, priority);
    }

    var children = new Map.fromIterable(
        json.keys.where((k)=>!k.startsWith(".")),
        key: (k)=>new Name(k),
        value: (k)=>new TreeStructuredData.fromJson(json[k], null, serverValues) );

    return new TreeStructuredData.children(children,priority);
  }

  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
    var c = new Map.fromIterables(children.keys.map((k)=>k.toString()),
        children.values.map((v)=>v.toJson(exportFormat)));

    if (exportFormat&&priority!=null) {
      return {".priority": priority}..addAll(isLeaf ? {".value": value} : c);
    }
    return isLeaf ? value.toJson() : c;
  }

  bool operator==(other) => other is TreeStructuredData&&(
      isLeaf ? other.isLeaf&&value==other.value :
      !other.isLeaf&&const MapEquality().equals(children, other.children));


  toString() => "TreeStructuredData[${toJson()}]";
}
