// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

abstract class Message {

  static const typeData = "d";
  static const typeControl = "c";
  static const messageType = "t";
  static const messageData = "d";

  Message();

  factory Message.fromJson(Map<String,dynamic> json) {
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

  toJson() => {
    messageType: this is ControlMessage ? typeControl : typeData,
    messageData: _payloadJson
  };

  get _payloadJson;

}


class DataMessage extends Message {
  static const action_listen = "q";
  static const action_unlisten = "n";
  static const action_on_disconnect_put = "o";
  static const action_on_disconnect_merge = "om";
  static const action_on_disconnect_cancel = "oc";
  static const action_put = "p";
  static const action_merge = "m";
  static const action_stats = "s";
  static const action_auth = "auth";
  static const action_unauth = "unauth";

  static const action_set = "d";
  static const action_listen_revoked = "c";
  static const action_auth_revoked = "ac";
  static const action_security_debug = "sd";

  final String action;
  final int reqNum;
  final MessageBody body;
  final String error;

  DataMessage(this.action, this.body, {this.error, this.reqNum});

  factory DataMessage.fromJson(Map<String,dynamic> json) {
    var data = json[Message.messageData];
    return new DataMessage(
        data["a"],
        new MessageBody.fromJson(data["b"] as Map<String, dynamic>),
        reqNum: data["r"],
        error: data["error"]
    );
  }

  get _payloadJson {
    var json = {};
    if (action!=null) json["a"] = action;
    if (body!=null) json["b"] = body;
    if (reqNum!=null) json["r"] = reqNum;
    if (error!=null) json["error"] = error;
    return json;
  }
}

class Query {
  static const INDEX_START_VALUE = "sp";
  static const INDEX_START_NAME = "sn";
  static const INDEX_END_VALUE = "ep";
  static const INDEX_END_NAME = "en";
  static const LIMIT = "l";
  static const VIEW_FROM = "vf";
  static const VIEW_FROM_LEFT = "l";
  static const VIEW_FROM_RIGHT = "r";
  static const INDEX = "i";

  final int limit;
  final bool isViewFromRight;
  final String index;
  final dynamic endValue;
  final String endName;
  final dynamic startValue;
  final String startName;

  Query({this.limit, this.isViewFromRight: false, this.index, this.endName,
  this.endValue, this.startName, this.startValue});

  factory Query.fromJson(Map<String,dynamic> json) {
    return new Query(
        limit: json[LIMIT],
        isViewFromRight: json[VIEW_FROM]==VIEW_FROM_RIGHT,
        index: json[INDEX],
        endName: json[INDEX_END_NAME],
        endValue: json[INDEX_END_VALUE],
        startName: json[INDEX_START_NAME],
        startValue: json[INDEX_START_VALUE]
    );
  }

  int get hashCode => quiver.hash4(limit, isViewFromRight, index,
      quiver.hash4(endName,endValue,startName,startValue));
  bool operator==(other) => other is Query&&other.limit==limit&&
      other.isViewFromRight==isViewFromRight&&other.index==index&&
      other.endName==endName&&other.endValue==endValue&&
      other.startName==startName&&other.startValue==startValue;

  toJson() {
    var json = {};
    if (limit!=null) {
      json[LIMIT] = limit;
      json[VIEW_FROM] = isViewFromRight ? VIEW_FROM_RIGHT : VIEW_FROM_LEFT;
    }
    if (index!=null) {
      json[INDEX] = index;
    }
    if (endName!=null) json[INDEX_END_NAME] = endName;
    if (endValue!=null) json[INDEX_END_VALUE] = endValue;
    if (startName!=null) json[INDEX_START_NAME] = startName;
    if (startValue!=null) json[INDEX_START_VALUE] = startValue;
    return json;
  }
}

class MessageBody {
  static const status_ok = "ok";


  final int tag;
  final Query query;
  final String path;
  final String hash;
  final data;
  final stats;
  final String cred;
  final String message;
  final String status;

  MessageBody({this.tag,this.query,this.path,this.hash,this.data,this.stats,this.cred, this.message, this.status});

  factory MessageBody.fromJson(Map<String,dynamic> json) {
    return new MessageBody(
        tag: json["t"],
        query: json["q"] is Map ? new Query.fromJson(json["q"] as Map<String,dynamic>) :
          json["q"] is List&&json["q"].isNotEmpty ? new Query.fromJson(json["q"].first as Map<String,dynamic>) : null,
        path: json["p"], hash: json["h"],
        data: json["d"], stats: json["c"], cred: json["cred"], message: json["msg"],
        status: json["s"]
    );
  }

  Iterable<String> get warnings => data is Map ? data["w"] as Iterable<String> : const[];

  toJson() {
    var json = {};
    if (cred!=null) json["cred"] = cred;
    if (path!=null) json["p"] = path;
    if (hash!=null) json["h"] = hash;
    if (tag!=null) json["t"] = tag;
    if (query!=null) json["q"] = query;
    if (data!=null) json["d"] = data;
    if (stats!=null) json["c"] = stats;
    if (message!=null) json["msg"] = message;
    if (status!=null) json["s"] = status;
    return json;
  }

}

abstract class ControlMessage extends Message {
  static const typeHandshake = "h";
  static const typeEndTransmission = "n";
  static const typeControlShutdown = "s";
  static const typeControlReset = "r";
  static const typeControlError = "e";
  static const typeControlPong = "o";
  static const typeControlPing = "p";

  ControlMessage();

  factory ControlMessage.fromJson(Map<String,dynamic> json) {
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
  get jsonData;

  get _payloadJson => {
    Message.messageType: type,
    Message.messageData: jsonData
  };

}

class PingMessage extends ControlMessage {
  String get type => ControlMessage.typeControlPing;
  get jsonData => {};
}
class PongMessage extends ControlMessage {
  String get type => ControlMessage.typeControlPong;
  get jsonData => {};
}

class ResetMessage extends ControlMessage {

  final String host;

  ResetMessage(this.host);

  factory ResetMessage.fromJson(Map<String,dynamic> json) {
    var data = json[Message.messageData];
    return new ResetMessage(data[Message.messageData]);
  }

  String get type => ControlMessage.typeControlReset;
  get jsonData => host;
}

class ShutdownMessage extends ControlMessage {
  final String reason;

  ShutdownMessage(this.reason);

  get jsonData => reason;

  @override
  String get type => ControlMessage.typeControlShutdown;
}

class HandshakeMessage extends ControlMessage {

  final HandshakeInfo info;

  HandshakeMessage(this.info);

  factory HandshakeMessage.fromJson(Map<String,dynamic> json) {
    var handshake = json[Message.messageData][Message.messageData];
    return new HandshakeMessage(new HandshakeInfo.fromJson(handshake as Map<String,dynamic>));
  }

  String get type => ControlMessage.typeHandshake;
  get jsonData => info;
}

class HandshakeInfo {

  final DateTime timestamp;
  final String version;
  final String host;
  final String sessionId;

  HandshakeInfo(this.timestamp, this.version, this.host, this.sessionId);

  factory HandshakeInfo.fromJson(Map<String,dynamic> json) =>
      new HandshakeInfo(
          new DateTime.fromMillisecondsSinceEpoch(json["ts"]),
          json["v"], json["h"], json["s"]
      );

  toJson() => {
    "ts": timestamp.millisecondsSinceEpoch,
    "v": version,
    "h": host,
    "s": sessionId
  };
}