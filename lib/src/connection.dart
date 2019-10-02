library firebase.connection;

import 'dart:async';
import 'tree.dart';
import 'treestructureddata.dart';
import 'operations/tree.dart';
import 'connections/protocol.dart';
import 'connections/mem.dart';

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

enum OperationEventType { overwrite, merge, listenRevoked }

class OperationEvent {
  final Path<Name> path;
  final OperationEventType type;
  final QueryFilter query;
  final dynamic data;

  OperationEvent(this.type, this.path, this.data, this.query) {
    if (type==OperationEventType.merge&&data is! Map)
      throw new ArgumentError.value(data, 'data', "should be a map");
    
    bool _isBaseType(dynamic v) {
      if (v is num||v is bool||v is String||v==null) return true;
      if (v is Map) return v.keys.every((k)=>k is String)&&v.values.every(_isBaseType);
      return false;
    }
    
    if (!_isBaseType(data))
      throw new ArgumentError.value(data, 'data', "should be a base type");
  }

  TreeOperation get operation {
    switch (type) {
      case OperationEventType.overwrite:
        return new TreeOperation.overwrite(path, new TreeStructuredData.fromJson(data));
      case OperationEventType.merge:
        return new TreeOperation.merge(path,
            new Map.fromIterables(
                (data as Map).keys.map((k)=>Name.parsePath(k.toString())),
                (data as Map).values.map((v)=>new TreeStructuredData.fromJson(v))
            ));
      default:
        return null;
    }
  }
}

/// Handles the connection to a remote database.
abstract class Connection {
  final String host;

  factory Connection(Uri uri) {
    switch (uri.scheme) {
      case "http":
        return new ProtocolConnection("${uri.host}:${uri.port ?? 80}", namespace: uri.queryParameters["ns"], ssl: false);
      case "https":
        return new ProtocolConnection("${uri.host}:${uri.port ?? 443}", namespace: uri.queryParameters["ns"], ssl: true);
      case "mem":
        return new MemConnection(uri.host);
      default:
        throw new ArgumentError("No known connection for uri '$uri'.");
    }
  }

  Connection.base(this.host);

  DateTime get serverTime;

  /// Generates the special server values
  Map<ServerValue, Value> get serverValues =>
      {ServerValue.timestamp: new Value(serverTime.millisecondsSinceEpoch)};

  /// Registers a listener.
  ///
  /// Returns possible warning messages.
  Future<Iterable<String>> listen(String path,
      {QueryFilter query, String hash});

  /// Unregisters a listener
  Future<Null> unlisten(String path, {QueryFilter query});

  /// Overwrites some value at a particular path.
  Future<Null> put(String path, dynamic value, {String hash, int writeId});

  /// Merges children at a particular path.
  Future<Null> merge(String path, Map<String, dynamic> value, {String hash, int writeId});

  /// Stream of connect events.
  Stream<bool> get onConnect;

  /// Stream of remote data changes.
  Stream<OperationEvent> get onDataOperation;

  /// Stream of auth events.
  Stream<Map> get onAuth;

  /// Trigger a disconnection.
  Future<Null> disconnect();

  /// Closes the connection.
  Future<Null> close();

  /// Authenticates with the token.
  Future<Map> auth(String token);

  /// Unauthenticates.
  Future<Null> unauth();

  /// Registers an onDisconnectPut
  Future<Null> onDisconnectPut(String path, dynamic value);

  /// Registers an onDisconnectMerge
  Future<Null> onDisconnectMerge(
      String path, Map<String, dynamic> childrenToMerge);

  /// Registers an onDisconnectCancel
  Future<Null> onDisconnectCancel(String path);
}
