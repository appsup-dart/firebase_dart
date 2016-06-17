// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.treestructureddata;


class TreeStructuredData extends TreeNode<Name,Value> {

  Value priority;


  TreeStructuredData({this.priority, Value value, Filter<Pair<Name,TreeStructuredData>> filter}) :
      super(value, filter==null ? null : new FilteredMap(filter));

  TreeStructuredData._(Value value, Map<Name,TreeStructuredData> children,
      Value priority) :
        priority = priority, super(value, children);

  TreeStructuredData.leaf(Value value, [Value priority]) :
        this._(value, null, priority);


  TreeStructuredData.nonLeaf(Map<Name,TreeStructuredData> children, [Value priority]) :
      this._(null, children, priority);

  @override
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

    var children = new Map<Name,TreeStructuredData>.fromIterable(
        json.keys.where((k)=>!k.startsWith(".")),
        key: (k)=>new Name(k),
        value: (k)=>new TreeStructuredData.fromJson(json[k], null, serverValues) );

    return new TreeStructuredData.nonLeaf(children,priority);
  }

  @override
  Map<Name,TreeStructuredData> get children => super.children;

  dynamic toJson([bool exportFormat = false]) {
    if (isNil) return null;
    var c = new Map<String,dynamic>.fromIterables(children.keys.map((k)=>k.toString()) as Iterable<String>,
        children.values.map((v)=>v.toJson(exportFormat)));

    if (exportFormat&&priority!=null) {
      if (isLeaf) c = {".value" : value};
      return <String,dynamic>{".priority": priority}..addAll(c);
    }
    return isLeaf ? value.toJson() : c;
  }

  @override
  bool operator==(other) => other is TreeStructuredData&&(
      isLeaf ? other.isLeaf&&value==other.value :
      !other.isLeaf&&const MapEquality().equals(children, other.children));

  @override
  int get hashCode => quiver.hash2(value, const MapEquality().hash(children));

  @override
  String toString() => "TreeStructuredData[${toJson()}]";
}
