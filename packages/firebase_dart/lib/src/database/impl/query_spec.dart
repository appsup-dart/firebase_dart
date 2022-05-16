import 'package:firebase_dart/src/database/impl/connections/protocol.dart';

import 'tree.dart';
import 'treestructureddata.dart';

class QuerySpec {
  final QueryFilter params;

  final Path<Name> path;

  const QuerySpec(this.path, [this.params = const QueryFilter()]);

  QuerySpec.fromJson(Map<dynamic, dynamic> json)
      : this(
            Name.parsePath(json['p']),
            json['q'] == null
                ? const QueryFilter()
                : QueryFilterCodec.fromJson((json['q'] as Map).cast()));

  QuerySpec normalize() {
    // If the query loadsAllData, we don't care about orderBy.
    // So just treat it as a default query.
    return !params.limits ? QuerySpec(path) : this;
  }

  Map<String, dynamic> toJson() => {
        'p': path.join('/'),
        if (params != const QueryFilter()) 'q': params.toJson()
      };

  @override
  int get hashCode => Object.hash(params, path);

  @override
  bool operator ==(other) =>
      other is QuerySpec && other.params == params && other.path == path;

  @override
  String toString() =>
      'QuerySpec{path=$path${(params != const QueryFilter()) ? ' params=$params' : ''}}';
}
