library firebase.connection;

import 'dart:async';

import 'package:firebase_dart/database.dart' show ServerValue;
import 'package:firebase_dart/src/implementation.dart';

import 'connections/protocol.dart';
import 'operations/tree.dart';
import 'tree.dart';
import 'treestructureddata.dart';

enum OperationEventType { overwrite, merge, listenRevoked }

class OperationEvent {
  final Path<Name>? path;
  final OperationEventType? type;
  final QueryFilter? query;
  final dynamic data;

  OperationEvent(this.type, this.path, this.data, this.query) {
    if (type == OperationEventType.merge && data is! Map) {
      throw ArgumentError.value(data, 'data', 'should be a map');
    }

    bool _isBaseType(dynamic v) {
      if (v is num || v is bool || v is String || v == null) return true;
      if (v is Map) {
        return v.keys.every((k) => k is String) && v.values.every(_isBaseType);
      }
      return false;
    }

    if (!_isBaseType(data)) {
      throw ArgumentError.value(data, 'data', 'should be a base type');
    }
  }

  TreeOperation? get operation {
    switch (type) {
      case OperationEventType.overwrite:
        return TreeOperation.overwrite(
            path!, TreeStructuredData.fromJson(data));
      case OperationEventType.merge:
        return TreeOperation.merge(
            path!,
            Map.fromIterables(
                (data as Map).keys.map((k) => Name.parsePath(k.toString())),
                (data as Map)
                    .values
                    .map((v) => TreeStructuredData.fromJson(v))));
      default:
        return null;
    }
  }
}

/// Handles the connection to a remote database.
///
/// A [PersistentConnection] reconnects to the server whenever the connection is
/// lost and will restore the state (i.e. the registered listeners, the
/// authentication credentials and on disconnect writes) and reattempt any
/// outstanding writes.
abstract class PersistentConnection {
  factory PersistentConnection(Uri uri,
      {required AuthTokenProvider authTokenProvider}) {
    return PersistentConnectionImpl(uri, authTokenProvider: authTokenProvider);
  }

  PersistentConnection.base();

  DateTime get serverTime;

  ConnectionState get connectionState;

  /// Generates the special server values
  Map<ServerValue, Value> get serverValues =>
      {ServerValue.timestamp: Value(serverTime.millisecondsSinceEpoch)};

  /// Stream of connect events.
  Stream<bool> get onConnect;

  /// Stream of remote data changes.
  Stream<OperationEvent> get onDataOperation;

  /// Stream of auth events.
  Stream<Map<String, dynamic>?> get onAuth;

  Map<String, dynamic>? get authData;

  // Lifecycle

  /// Initializes the connection
  ///
  /// Should be called before using
  void initialize();

  /// Shuts down the connection
  void shutdown();

  // auth

  /// Authenticates with the token.
  Future<void> refreshAuthToken(FutureOr<String>? token);

  // listens

  /// Registers a listener.
  ///
  /// Returns possible warning messages.
  Future<Iterable<String>> listen(String path,
      {QueryFilter? query, String? hash});

  /// Unregisters a listener
  Future<Null> unlisten(String path, {QueryFilter? query});

  // writes

  /// Removes all outstanding writes
  void purgeOutstandingWrites();

  /// Overwrites some value at a particular path.
  Future<Null> put(String path, dynamic value, {String? hash});

  /// Merges children at a particular path.
  Future<Null> merge(String path, Map<String, dynamic> value, {String? hash});

  // disconnects

  /// Registers an onDisconnectPut
  Future<Null> onDisconnectPut(String path, dynamic value);

  /// Registers an onDisconnectMerge
  Future<Null> onDisconnectMerge(
      String path, Map<String, dynamic> childrenToMerge);

  /// Registers an onDisconnectCancel
  Future<Null> onDisconnectCancel(String path);
  // Connection management

  void interrupt(String reason);

  void resume(String reason);

  bool isInterrupted(String reason);

  /// Trigger a disconnection.
  Future<void> disconnect();

  /// Closes the connection.
  Future<void> close();

  void mockConnectionLost();
  void mockResetMessage();
}

enum ConnectionState {
  disconnected,
  gettingToken,
  connecting,
  authenticating,
  connected,
}
