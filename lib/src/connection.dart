
library firebase.connection;

import 'dart:async';
import 'tree.dart';
import 'treestructureddata.dart';
import 'operations/tree.dart';
import 'repo.dart';
import 'connections/protocol.dart';

class ServerError implements Exception {
  final String code;
  final String message;

  ServerError(this.code, this.message);

  String get reason =>
      const {
        "too_big":
        "The data requested exceeds the maximum size that can be accessed with a single request.",
        "permission_denied":
        "Client doesn't have permission to access the desired data.",
        "unavailable": "The service is unavailable"
      }[code] ??
          "Unknown Error";

  @override
  String toString() => "$code: $reason";
}

enum OperationEventType {overwrite, merge, listenRevoked}

class OperationEvent {
  final Path<Name> path;
  final OperationEventType type;
  final QueryFilter query;
  final TreeStructuredData data;

  OperationEvent(this.type, this.path, this.data, this.query);

  TreeOperation get operation {
    switch (type) {
      case OperationEventType.overwrite:
        if (path.isNotEmpty&&path.last==new Name(".priority"))
          return new TreeOperation.setPriority(path.parent, data.value);
        return new TreeOperation.overwrite(path, data);
      case OperationEventType.merge:
        return new TreeOperation.merge(path, data.children);
      default:
        return null;
    }
  }
}

abstract class Connection {
  final String host;

  Connection.base(this.host);

  factory Connection(Uri uri) {
    return new ProtocolConnection(uri.host);
  }

  DateTime get serverTime;

  Future<Iterable<String>> listen(String path, {QueryFilter query, String hash});

  Future<Null> unlisten(String path, {QueryFilter query});

  Future<Null> put(String path, dynamic value, {String hash, int writeId});

  Future<Null> merge(String path, dynamic value, {String hash, int writeId});

  Stream<bool> get onConnect;
  Stream<OperationEvent> get onDataOperation;
  Stream<Map> get onAuth;

  Future<Null> disconnect();

  Future<Null> close();

  Future<Map> auth(String token);

  Future<Null> unauth();

  Future<Null> onDisconnectPut(String path, dynamic value);

  Future<Null> onDisconnectMerge(String path, Map<String, dynamic> childrenToMerge);

  Future<Null> onDisconnectCancel(String path);
}
