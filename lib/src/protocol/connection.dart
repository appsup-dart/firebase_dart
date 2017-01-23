// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

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

class Connection {
  final String host;
  Transport _transport;
  Future _establishConnectionTimer;
  String _lastSessionId;

  Connection(this.host) {
    quiver.checkArgument(host!=null&&host.isNotEmpty);
    _scheduleConnect(0);
  }

  final Map<String, Map<Query, Request>> _listens = {};

  DateTime get serverTime => new DateTime.now().add(_serverTimeDiff ?? const Duration());
  Duration _serverTimeDiff;

  Future listen(String path, {Query query, int tag, String hash}) {
    var r = new Request.listen(path, query: query, tag: tag, hash: hash);
    _addListen(r);
    return _request(r)..catchError((e) => _removeListen(path, query));
  }

  Future unlisten(String path, {Query query, int tag}) {
    var r = new Request.unlisten(path, query: query, tag: tag);
    _removeListen(path, query);
    return _request(r);
  }

  final List<Request> _outstandingRequests = [];

  Future put(String path, dynamic value, {String hash, int writeId}) =>
      _request(new Request.put(path, value, hash, writeId));

  Future merge(String path, dynamic value, {String hash, int writeId}) =>
      _request(new Request.merge(path, value, hash, writeId));

  void _addListen(Request request) {
    var path = request.message.body.path;
    var query = request.message.body.query;
    _listens.putIfAbsent(path, () => {})[query] = request;
  }

  void _removeListen(String path, Query query) {
    _listens.putIfAbsent(path, () => {}).remove(query);
  }

  void _scheduleConnect(num timeout) {
    assert(this._transport ==
        null); //, "Scheduling a connect when we're already connected/ing?");

    var future = this._establishConnectionTimer =
        new Future.delayed(new Duration(milliseconds: timeout.floor()));

    future.then((_) {
      if (future != _establishConnectionTimer) {
        return;
      }
      _establishConnectionTimer = null;
      _establishConnection();
    });
  }

  final StreamController<Response> _output = new StreamController();
  final StreamController<bool> _onConnect = new StreamController();

  Stream<Response> get output => _output.stream;
  Stream<bool> get onConnect => _onConnect.stream;

  void _establishConnection() {
    _transport =
        new WebSocketTransport(host, host.split(".").first, _lastSessionId);
    _transport.ready.then((_) {
      _onConnect.add(true);
      _lastSessionId = _transport.info.sessionId;
      _serverTimeDiff =
          _transport.info.timestamp.difference(new DateTime.now());
      _output.addStream(_transport.where((r) => r.message.reqNum == null||r.request.writeId!=null));
      _restoreState();
    });
    _transport.done.then((_) {
      _onConnect.add(false);
      _transport = null;
      if (!_output.isClosed) _scheduleConnect(1000);
    });
  }

  Future disconnect() => _transport._close(null);

  Future close() async {
    await _output.close();
    await _onConnect.close();
    await disconnect();
  }

  Future _restoreState() async {
    if (_transport.readyState!=Transport.connected) return;


    // auth
    if (_authToken != null) {
      await auth(_authToken);
    }

    // listens
    _listens.forEach((path, list) {
      list.forEach((query, request) {
        _transport.add(request);
      });
    });

    // requests
    _outstandingRequests.forEach((r) {
      _transport.add(r);
    });
  }

  var _authToken;

  Future auth(String token) => _request(new Request.auth(token)).then((b) {
        _authToken = token;
        return b.data;
      });

  Future unauth() {
    _authToken = null;
    return _request(new Request.unauth()).then((b) => b.data);
  }

  bool get _transportIsReady =>
      _transport != null && _transport.readyState == Transport.connected;

  Future<MessageBody> _request(Request request) {
    switch (request.message.action) {
      case DataMessage.actionListen:
      case DataMessage.actionUnlisten:
        break;
      default:
        _outstandingRequests.add(request);
    }
    if (_transportIsReady) {
      _transport.add(request);
    }
    return request.response.then/*<MessageBody>*/((r) {
      _outstandingRequests.remove(request);
      if (r.message.body.status == MessageBody.statusOk) {
        return r.message.body;
      } else {
        throw new ServerError(r.message.body.status, r.message.body.data);
      }
    });
  }

  Future<MessageBody> onDisconnectPut(String path, dynamic value) =>
      _request(new Request.onDisconnectPut(path, value));

  Future<MessageBody> onDisconnectMerge(
          String path, Map<String, dynamic> childrenToMerge) =>
      _request(new Request.onDisconnectMerge(path, childrenToMerge));

  Future<MessageBody> onDisconnectCancel(String path) =>
      _request(new Request.onDisconnectCancel(path));
}
