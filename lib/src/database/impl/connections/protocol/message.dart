// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

/// Represents a message to be sent over a communication channel
abstract class Message {
  factory Message.fromJson(Map<String, dynamic> json) =
      _JsonObjectMessage.fromJson;

  dynamic toJson();
}

/// A message that is structured as a JSON-object
///
/// All normal messages are of this type. Only the keep-alive message is not of
/// this type.
abstract class _JsonObjectMessage implements Message {
  static const String typeData = 'd';
  static const String typeControl = 'c';
  static const String messageType = 't';
  static const String messageData = 'd';

  _JsonObjectMessage();

  factory _JsonObjectMessage.fromJson(Map<String, dynamic> json) {
    var layer = json[messageType];
    switch (layer) {
      case typeData:
        return DataMessage.fromJson(json);
      case typeControl:
        return ControlMessage.fromJson(json);
      default:
        throw ArgumentError('Invalid message $json');
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        messageType: this is ControlMessage ? typeControl : typeData,
        messageData: _payloadJson
      };

  Map<String, dynamic> get _payloadJson;
}

/// A simple message send to the backend to keep the connection alive
class KeepAliveMessage implements Message {
  @override
  dynamic toJson() => 0;
}

/// A message that is not meant for controlling the connection, but contains
/// actual meaningful data
class DataMessage extends _JsonObjectMessage {
  // send
  static const String actionListen = 'q';
  static const String actionUnlisten = 'n';
  static const String actionOnDisconnectPut = 'o';
  static const String actionOnDisconnectMerge = 'om';
  static const String actionOnDisconnectCancel = 'oc';
  static const String actionPut = 'p';
  static const String actionMerge = 'm';
  static const String actionStats = 's';
  static const String actionAuth = 'auth';
  static const String actionGauth = 'gauth';
  static const String actionUnauth = 'unauth';

  // receive
  static const String actionSet = 'd';
  static const String actionListenRevoked = 'c';
  static const String actionAuthRevoked = 'ac';
  static const String actionSecurityDebug = 'sd';

  /// The action to be performed
  final String action;

  /// A request number
  ///
  /// This number links requests sent to the server to responses received from
  /// the server.
  final int reqNum;

  /// The body
  final MessageBody body;

  /// Contains an error in case the request could not be executed
  final String error;

  DataMessage(this.action, this.body, {this.error, this.reqNum});

  factory DataMessage.fromJson(Map<String, dynamic> json) {
    var data = json[_JsonObjectMessage.messageData];
    return DataMessage(
        data['a'], MessageBody.fromJson(data['b'] as Map<String, dynamic>),
        reqNum: data['r'], error: data['error']);
  }

  @override
  Map<String, dynamic> get _payloadJson => {
        if (action != null) 'a': action,
        if (body != null) 'b': body,
        if (reqNum != null) 'r': reqNum,
        if (error != null) 'error': error,
      };
}

/// Represents a query definition
class Query {
  static const String indexStartValue = 'sp';
  static const String indexStartName = 'sn';
  static const String indexEndValue = 'ep';
  static const String indexEndName = 'en';
  static const String limitTo = 'l';
  static const String viewFrom = 'vf';
  static const String viewFromLeft = 'l';
  static const String viewFromRight = 'r';
  static const String indexOn = 'i';

  final int limit;
  final bool isViewFromRight;
  final String index;
  final dynamic endValue;
  final String endName;
  final dynamic startValue;
  final String startName;

  Query(
      {this.limit,
      this.isViewFromRight = false,
      this.index,
      this.endName,
      this.endValue,
      this.startName,
      this.startValue});

  factory Query.fromJson(Map<String, dynamic> json) {
    return Query(
        limit: json[limitTo],
        isViewFromRight: json[viewFrom] == viewFromRight,
        index: json[indexOn],
        endName: json[indexEndName],
        endValue: json[indexEndValue],
        startName: json[indexStartName],
        startValue: json[indexStartValue]);
  }

  factory Query.fromFilter(QueryFilter filter) {
    if (filter == null) return null;
    return Query(
        limit: filter.limit,
        isViewFromRight: filter.reversed,
        index: filter.orderBy,
        endName: filter.orderBy == '.key' ? null : filter.endKey?.asString(),
        endValue: filter.orderBy != '.key'
            ? filter.endValue?.value?.value
            : filter.endKey?.asString(),
        startName:
            filter.orderBy == '.key' ? null : filter.startKey?.asString(),
        startValue: filter.orderBy != '.key'
            ? filter.startValue?.value?.value
            : filter.startKey?.asString());
  }

  QueryFilter toFilter() {
    var f = QueryFilter(
        limit: limit,
        reversed: isViewFromRight,
        ordering: TreeStructuredDataOrdering(index));
    return f.copyWith(
        startAtKey: startName,
        startAtValue: startValue,
        endAtKey: endName,
        endAtValue: endValue);
  }

  @override
  int get hashCode => quiver.hash4(limit, isViewFromRight, index,
      quiver.hash4(endName, endValue, startName, startValue));

  @override
  bool operator ==(dynamic other) =>
      other is Query &&
      other.limit == limit &&
      other.isViewFromRight == isViewFromRight &&
      other.index == index &&
      other.endName == endName &&
      other.endValue == endValue &&
      other.startName == startName &&
      other.startValue == startValue;

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (limit != null) {
      json[limitTo] = limit;
      json[viewFrom] = isViewFromRight ? viewFromRight : viewFromLeft;
    }
    if (index != null) {
      json[indexOn] = index;
    }
    if (endName != null) json[indexEndName] = endName;
    if (endValue != null) json[indexEndValue] = endValue;
    if (startName != null) json[indexStartName] = startName;
    if (startValue != null) json[indexStartValue] = startValue;
    return json;
  }
}

/// The body of a message
class MessageBody {
  static const String statusOk = 'ok';

  final int tag;
  final Query query;
  final String path;
  final String hash;
  final dynamic data;
  final dynamic stats;
  final String cred;
  final String message;
  final String status;

  MessageBody(
      {this.tag,
      this.query,
      this.path,
      this.hash,
      this.data,
      this.stats,
      this.cred,
      this.message,
      this.status});

  factory MessageBody.fromJson(Map<String, dynamic> json) {
    return MessageBody(
        tag: json['t'],
        query: json['q'] is Map
            ? Query.fromJson(json['q'] as Map<String, dynamic>)
            : json['q'] is List && json['q'].isNotEmpty
                ? Query.fromJson(json['q'].first as Map<String, dynamic>)
                : null,
        path: json['p'],
        hash: json['h'],
        data: json['d'],
        stats: json['c'],
        cred: json['cred'],
        message: json['msg'],
        status: json['s']);
  }

  Iterable<String> get warnings =>
      data is Map ? (data['w'] as Iterable)?.map((v) => v as String) : const [];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (cred != null) json['cred'] = cred;
    if (path != null) json['p'] = path;
    if (hash != null) json['h'] = hash;
    if (tag != null) json['t'] = tag;
    if (query != null) json['q'] = query;
    if (data != null) json['d'] = data;
    if (stats != null) json['c'] = stats;
    if (message != null) json['msg'] = message;
    if (status != null) json['s'] = status;
    return json;
  }
}

/// A message to control the connection
abstract class ControlMessage extends _JsonObjectMessage {
  static const String typeHandshake = 'h';
  static const String typeEndTransmission = 'n';
  static const String typeControlShutdown = 's';
  static const String typeControlReset = 'r';
  static const String typeControlError = 'e';
  static const String typeControlPong = 'o';
  static const String typeControlPing = 'p';

  ControlMessage();

  factory ControlMessage.fromJson(Map<String, dynamic> json) {
    var data = json[_JsonObjectMessage.messageData];
    var cmd = data[_JsonObjectMessage.messageType];
    switch (cmd) {
      case typeHandshake:
        return HandshakeMessage.fromJson(json);
      case typeEndTransmission:
        throw UnimplementedError('Received control message: $json');
      case typeControlShutdown:
        return ShutdownMessage(data[_JsonObjectMessage.messageData]);
      case typeControlReset:
        return ResetMessage.fromJson(json);
      case typeControlError:
        throw UnimplementedError('Received control message: $json');
      case typeControlPing:
        return PingMessage();
      case typeControlPong:
        return PongMessage();
      default:
        throw ArgumentError('Unknown control message $json');
    }
  }

  String get type;

  dynamic get jsonData;

  @override
  Map<String, dynamic> get _payloadJson => {
        _JsonObjectMessage.messageType: type,
        _JsonObjectMessage.messageData: jsonData
      };
}

/// A ping message
class PingMessage extends ControlMessage {
  @override
  String get type => ControlMessage.typeControlPing;

  @override
  Map<String, dynamic> get jsonData => {};
}

/// A pong message, the response of a ping message
class PongMessage extends ControlMessage {
  @override
  String get type => ControlMessage.typeControlPong;

  @override
  Map<String, dynamic> get jsonData => {};
}

/// Message sent by the server when the client should reconnect
class ResetMessage extends ControlMessage {
  /// The host to reconnect to
  final String host;

  ResetMessage(this.host);

  factory ResetMessage.fromJson(Map<String, dynamic> json) {
    var data = json[_JsonObjectMessage.messageData];
    return ResetMessage(data[_JsonObjectMessage.messageData]);
  }

  @override
  String get type => ControlMessage.typeControlReset;

  @override
  String get jsonData => host;
}

/// Message sent by the server when the client should shut down
class ShutdownMessage extends ControlMessage {
  /// The reason of this request
  final String reason;

  ShutdownMessage(this.reason);

  @override
  String get jsonData => reason;

  @override
  String get type => ControlMessage.typeControlShutdown;
}

/// The initial message sent by the server
class HandshakeMessage extends ControlMessage {
  /// The handshake information
  final HandshakeInfo info;

  HandshakeMessage(this.info);

  factory HandshakeMessage.fromJson(Map<String, dynamic> json) {
    var handshake =
        json[_JsonObjectMessage.messageData][_JsonObjectMessage.messageData];
    return HandshakeMessage(
        HandshakeInfo.fromJson(handshake as Map<String, dynamic>));
  }

  @override
  String get type => ControlMessage.typeHandshake;

  @override
  HandshakeInfo get jsonData => info;
}

/// Information received on handshake
class HandshakeInfo {
  /// The current time of the server
  final DateTime timestamp;

  /// Version
  final String version;

  /// Host
  final String host;

  /// The session id
  final String sessionId;

  HandshakeInfo(this.timestamp, this.version, this.host, this.sessionId);

  factory HandshakeInfo.fromJson(Map<String, dynamic> json) => HandshakeInfo(
      DateTime.fromMillisecondsSinceEpoch(json['ts']),
      json['v'],
      json['h'],
      json['s']);

  Map<String, dynamic> toJson() => {
        'ts': timestamp.millisecondsSinceEpoch,
        'v': version,
        'h': host,
        's': sessionId
      };
}

/// Transforms a channel of json like dart objects to [Message] objects
final messageChannelTransformer = const _MessageChannelTransformer();

class _MessageChannelTransformer
    implements StreamChannelTransformer<Message, Object> {
  const _MessageChannelTransformer();

  @override
  StreamChannel<Message> bind(StreamChannel<Object> channel) {
    var stream = channel.stream.map<Message>((v) => Message.fromJson(v));
    var sink = StreamSinkTransformer<Message, Object>.fromHandlers(
        handleData: (data, sink) {
      sink.add(data.toJson());
    }).bind(channel.sink);
    return StreamChannel.withCloseGuarantee(stream, sink);
  }
}
