// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

abstract class Message {
  static const String typeData = "d";
  static const String typeControl = "c";
  static const String messageType = "t";
  static const String messageData = "d";

  Message();

  factory Message.fromJson(Map<String, dynamic> json) {
    var layer = json[messageType];
    switch (layer) {
      case typeData:
        return new DataMessage.fromJson(json);
      case typeControl:
        return new ControlMessage.fromJson(json);
      default:
        throw new ArgumentError("Invalid message $json");
    }
  }

  Map<String, dynamic> toJson() => {
        messageType: this is ControlMessage ? typeControl : typeData,
        messageData: _payloadJson
      };

  Map<String, dynamic> get _payloadJson;
}

class DataMessage extends Message {
  static const String actionListen = "q";
  static const String actionUnlisten = "n";
  static const String actionOnDisconnectPut = "o";
  static const String actionOnDisconnectMerge = "om";
  static const String actionOnDisconnectCancel = "oc";
  static const String actionPut = "p";
  static const String actionMerge = "m";
  static const String actionStats = "s";
  static const String actionAuth = "auth";
  static const String actionGauth = "gauth";
  static const String actionUnauth = "unauth";

  static const String actionSet = "d";
  static const String actionListenRevoked = "c";
  static const String actionAuthRevoked = "ac";
  static const String actionSecurityDebug = "sd";

  final String action;
  final int reqNum;
  final MessageBody body;
  final String error;

  DataMessage(this.action, this.body, {this.error, this.reqNum});

  factory DataMessage.fromJson(Map<String, dynamic> json) {
    var data = json[Message.messageData];
    return new DataMessage(
        data["a"], new MessageBody.fromJson(data["b"] as Map<String, dynamic>),
        reqNum: data["r"], error: data["error"]);
  }

  @override
  Map<String, dynamic> get _payloadJson {
    var json = <String, dynamic>{};
    if (action != null) json["a"] = action;
    if (body != null) json["b"] = body;
    if (reqNum != null) json["r"] = reqNum;
    if (error != null) json["error"] = error;
    return json;
  }
}

class Query {
  static const String indexStartValue = "sp";
  static const String indexStartName = "sn";
  static const String indexEndValue = "ep";
  static const String indexEndName = "en";
  static const String limitTo = "l";
  static const String viewFrom = "vf";
  static const String viewFromLeft = "l";
  static const String viewFromRight = "r";
  static const String indexOn = "i";

  final int limit;
  final bool isViewFromRight;
  final String index;
  final dynamic endValue;
  final String endName;
  final dynamic startValue;
  final String startName;

  Query(
      {this.limit,
      this.isViewFromRight: false,
      this.index,
      this.endName,
      this.endValue,
      this.startName,
      this.startValue});

  factory Query.fromJson(Map<String, dynamic> json) {
    return new Query(
        limit: json[limitTo],
        isViewFromRight: json[viewFrom] == viewFromRight,
        index: json[indexOn],
        endName: json[indexEndName],
        endValue: json[indexEndValue],
        startName: json[indexStartName],
        startValue: json[indexStartValue]);
  }

  factory Query.fromFilter(QueryFilter filter) {
    if (filter==null) return null;
    return new Query(
        limit: filter.limit,
        isViewFromRight: filter.reversed,
        index: filter.orderBy,
        endName: filter.orderBy==".key" ? null : filter.validTypedInterval.end?.key?.asString(),
        endValue: filter.orderBy!=".key" ? filter.validTypedInterval.end?.value?.value?.value : filter.validTypedInterval.end?.key?.asString(),
        startName: filter.orderBy==".key" ? null : filter.validTypedInterval.start?.key?.asString(),
        startValue: filter.orderBy!=".key" ? filter.validTypedInterval.start?.value?.value?.value : filter.validTypedInterval.start?.key?.asString()
    );
  }

  QueryFilter toFilter() {
    var f = new QueryFilter(
        limit: limit,
        reversed: isViewFromRight,
        ordering: new TreeStructuredDataOrdering(index));
    if (index==".key") {
      return f.copyWith(startAtKey: startValue, endAtKey: endValue);
    }
    return f.copyWith(startAtKey: startName, startAtValue: startValue, endAtKey: endName, endAtValue: endValue);
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

class MessageBody {
  static const String statusOk = "ok";

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
    return new MessageBody(
        tag: json["t"],
        query: json["q"] is Map
            ? new Query.fromJson(json["q"] as Map<String, dynamic>)
            : json["q"] is List && json["q"].isNotEmpty
                ? new Query.fromJson(json["q"].first as Map<String, dynamic>)
                : null,
        path: json["p"],
        hash: json["h"],
        data: json["d"],
        stats: json["c"],
        cred: json["cred"],
        message: json["msg"],
        status: json["s"]);
  }

  Iterable<String> get warnings =>
      data is Map ? data["w"] as Iterable<String> : const [];

  Map<String, dynamic> toJson() {
    var json = <String, dynamic>{};
    if (cred != null) json["cred"] = cred;
    if (path != null) json["p"] = path;
    if (hash != null) json["h"] = hash;
    if (tag != null) json["t"] = tag;
    if (query != null) json["q"] = query;
    if (data != null) json["d"] = data;
    if (stats != null) json["c"] = stats;
    if (message != null) json["msg"] = message;
    if (status != null) json["s"] = status;
    return json;
  }
}

abstract class ControlMessage extends Message {
  static const String typeHandshake = "h";
  static const String typeEndTransmission = "n";
  static const String typeControlShutdown = "s";
  static const String typeControlReset = "r";
  static const String typeControlError = "e";
  static const String typeControlPong = "o";
  static const String typeControlPing = "p";

  ControlMessage();

  factory ControlMessage.fromJson(Map<String, dynamic> json) {
    var data = json[Message.messageData];
    var cmd = data[Message.messageType];
    switch (cmd) {
      case typeHandshake:
        return new HandshakeMessage.fromJson(json);
      case typeEndTransmission:
        throw new UnimplementedError("Received control message: $json");
      case typeControlShutdown:
        return new ShutdownMessage(data[Message.messageData]);
      case typeControlReset:
        return new ResetMessage.fromJson(json);
      case typeControlError:
        print(json);
        throw new UnimplementedError("Received control message: $json");
      case typeControlPing:
        return new PingMessage();
      case typeControlPong:
        return new PongMessage();
      default:
        throw new ArgumentError("Unknown control message $json");
    }
  }

  String get type;
  dynamic get jsonData;

  @override
  Map<String, dynamic> get _payloadJson =>
      {Message.messageType: type, Message.messageData: jsonData};
}

class PingMessage extends ControlMessage {
  @override
  String get type => ControlMessage.typeControlPing;

  @override
  Map<String, dynamic> get jsonData => {};
}

class PongMessage extends ControlMessage {
  @override
  String get type => ControlMessage.typeControlPong;

  @override
  Map<String, dynamic> get jsonData => {};
}

class ResetMessage extends ControlMessage {
  final String host;

  ResetMessage(this.host);

  factory ResetMessage.fromJson(Map<String, dynamic> json) {
    var data = json[Message.messageData];
    return new ResetMessage(data[Message.messageData]);
  }

  @override
  String get type => ControlMessage.typeControlReset;

  @override
  String get jsonData => host;
}

class ShutdownMessage extends ControlMessage {
  final String reason;

  ShutdownMessage(this.reason);

  @override
  String get jsonData => reason;

  @override
  String get type => ControlMessage.typeControlShutdown;
}

class HandshakeMessage extends ControlMessage {
  final HandshakeInfo info;

  HandshakeMessage(this.info);

  factory HandshakeMessage.fromJson(Map<String, dynamic> json) {
    var handshake = json[Message.messageData][Message.messageData];
    return new HandshakeMessage(
        new HandshakeInfo.fromJson(handshake as Map<String, dynamic>));
  }

  @override
  String get type => ControlMessage.typeHandshake;

  @override
  HandshakeInfo get jsonData => info;
}

class HandshakeInfo {
  final DateTime timestamp;
  final String version;
  final String host;
  final String sessionId;

  HandshakeInfo(this.timestamp, this.version, this.host, this.sessionId);

  factory HandshakeInfo.fromJson(Map<String, dynamic> json) =>
      new HandshakeInfo(new DateTime.fromMillisecondsSinceEpoch(json["ts"]),
          json["v"], json["h"], json["s"]);

  Map<String, dynamic> toJson() => {
        "ts": timestamp.millisecondsSinceEpoch,
        "v": version,
        "h": host,
        "s": sessionId
      };
}
