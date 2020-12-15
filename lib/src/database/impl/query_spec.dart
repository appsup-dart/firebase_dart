import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:quiver/core.dart';

import 'tree.dart';
import 'treestructureddata.dart';

class QuerySpec {
  final QueryFilter params;

  final Path<Name> path;

  QuerySpec(this.path, [this.params = const QueryFilter()]);

  QuerySpec.fromJson(Map<String, dynamic> json)
      : this(
            Name.parsePath(json['p']),
            json['q'] == null
                ? const QueryFilter()
                : Query.fromJson(json['q']).toFilter());

  QuerySpec normalize() {
    // If the query loadsAllData, we don't care about orderBy.
    // So just treat it as a default query.
    return !params.limits ? QuerySpec(path) : this;
  }

  Map<String, dynamic> toJson() => {
        'p': path.join('/'),
        if (params != const QueryFilter())
          'q': Query.fromFilter(params).toJson()
      };

  @override
  int get hashCode => hash2(params, path);

  @override
  bool operator ==(other) =>
      other is QuerySpec && other.params == params && other.path == path;

  @override
  String toString() =>
      'QuerySpec{path=$path${(params != const QueryFilter()) ? ' params=$params' : ''}}';
}
