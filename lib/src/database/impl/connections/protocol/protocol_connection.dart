// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class ProtocolConnection extends PersistentConnection {
  Transport _transport;
  Future _establishConnectionTimer;
  String _lastSessionId;

  int _nextTag = 0;
  final quiver.BiMap<int, Pair<String, QueryFilter>> _tagToQuery =
      quiver.BiMap();

  final String namespace;
  final bool ssl;

  ProtocolConnection(String host, {this.namespace, this.ssl})
      : super.base(host) {
    quiver.checkArgument(host != null && host.isNotEmpty);
    _scheduleConnect(0);
  }

  final List<Request> _listens = [];

  @override
  DateTime get serverTime =>
      DateTime.now().add(_serverTimeDiff ?? const Duration());

  Duration _serverTimeDiff;

  @override
  Future<Iterable<String>> listen(String path,
      {QueryFilter query, String hash}) async {
    var def = Pair(path, query);
    var tag = _nextTag++;
    _tagToQuery[tag] = def;

    var r = Request.listen(path,
        query: Query.fromFilter(query), tag: tag, hash: hash);
    _addListen(r);
    try {
      var body = await _request(r);
      return body.warnings ?? [];
    } catch (e) {
      _tagToQuery.remove(tag);
      _removeListen(path, query);
      rethrow;
    }
  }

  @override
  Future<Null> unlisten(String path, {QueryFilter query}) async {
    var def = Pair(path, query);
    var tag = _tagToQuery.inverse.remove(def);
    var r = Request.unlisten(path, query: Query.fromFilter(query), tag: tag);
    _removeListen(path, query);
    await _request(r);
  }

  final List<Request> _outstandingRequests = [];

  @override
  Future<Null> put(String path, dynamic value,
      {String hash, int writeId}) async {
    await _request(Request.put(path, value, hash, writeId));
  }

  @override
  Future<Null> merge(String path, Map<String, dynamic> value,
      {String hash, int writeId}) async {
    await _request(Request.merge(path, value, hash, writeId));
  }

  void _addListen(Request request) {
    _listens.add(request);
  }

  void _removeListen(String path, QueryFilter query) {
    _listens.removeWhere((element) =>
        (element.message as DataMessage).body.path == path &&
        (element.message as DataMessage).body.query.toFilter() == query);
  }

  void _scheduleConnect(num timeout) {
    assert(_transport ==
        null); //, "Scheduling a connect when we're already connected/ing?");

    var future = _establishConnectionTimer =
        Future.delayed(Duration(milliseconds: timeout.floor()));

    future.then((_) {
      if (future != _establishConnectionTimer) {
        return;
      }
      _establishConnectionTimer = null;
      _establishConnection();
    });
  }

  final StreamController<bool> _onConnect = StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation =
      StreamController(sync: true);
  final StreamController<Map> _onAuth = StreamController(sync: true);

  @override
  Stream<bool> get onConnect => _onConnect.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  void _establishConnection() {
    _transport = WebSocketTransport(
        host, namespace ?? host.split('.').first, ssl, _lastSessionId);
    _transport.ready.then((_) {
      _onConnect.add(true);
      _lastSessionId = _transport.info.sessionId;
      _serverTimeDiff = _transport.info.timestamp.difference(DateTime.now());
      _transport.where((r) => r.message.reqNum == null).forEach((r) {
        var query =
            r.message.body.query ?? _tagToQuery[r.message.body.tag]?.value;
        if (query == null && r.message.body.tag != null) {
          // not listening any more.
          return;
        }
        var path = r.message.body.path == null
            ? null
            : Name.parsePath(r.message.body.path);
        switch (r.message.action) {
          case DataMessage.actionSet:
          case DataMessage.actionMerge:
          case DataMessage.actionListenRevoked:
            var event = OperationEvent(
                const {
                  DataMessage.actionSet: OperationEventType.overwrite,
                  DataMessage.actionMerge: OperationEventType.merge,
                  DataMessage.actionListenRevoked:
                      OperationEventType.listenRevoked,
                }[r.message.action],
                path,
                r.message.body.data,
                query);
            _onDataOperation.add(event);
            break;
          case DataMessage.actionAuthRevoked:
            _onAuth.add(null);
            break;
          case DataMessage.actionSecurityDebug:
            var msg = r.message.body.message;
            _logger.fine('security debug: $msg');
            break;
          default:
            throw UnimplementedError(
                'Cannot handle message with action ${r.message.action}: ${json.encode(r.message)} ${r.message.reqNum} ${r.request.writeId}');
        }
      });
      _restoreState();
    });
    _transport.done.then((_) {
      _onConnect.add(false);
      _transport = null;
      if (!_onDataOperation.isClosed) _scheduleConnect(1000);
    });
  }

  @override
  Future<Null> disconnect() => _transport.close();

  @override
  Future<Null> close() async {
    await _onDataOperation.close();
    await _onAuth.close();
    await _onConnect.close();
    await disconnect();
  }

  Future _restoreState() async {
    if (_transport.readyState != Transport.connected) return;

    // auth
    if (_authToken != null) {
      await auth(_authToken);
    }

    // listens
    for (var r in _listens) {
      _transport.add(r);
    }

    // requests
    _outstandingRequests.forEach((r) {
      _transport.add(r);
    });
  }

  FutureOr<String> _authToken;

  @override
  Future<Map<String, dynamic>> auth(FutureOr<String> token) {
    _authToken = token;
    return _request(Request.auth(token)).then((b) {
      return b.data['auth'];
    });
  }

  @override
  Future<Null> unauth() {
    _authToken = null;
    return _request(Request.unauth()).then((b) => null);
  }

  bool get _transportIsReady =>
      _transport != null && _transport.readyState == Transport.connected;

  Future<MessageBody> _request(Request request) async {
    var message = request.message;
    if (message is DataMessage) {
      switch (message.action) {
        case DataMessage.actionListen:
        case DataMessage.actionUnlisten:
          break;
        default:
          _outstandingRequests.add(request);
      }
    }
    if (_transportIsReady) {
      _transport.add(request);
    }
    return (await request).response.then<MessageBody>((r) {
      _outstandingRequests.remove(request);
      if (r.message.body.status == MessageBody.statusOk) {
        return r.message.body;
      } else {
        throwServerError(r.message.body.status, r.message.body.data);
      }
    });
  }

  @override
  Future<Null> onDisconnectPut(String path, dynamic value) async {
    await _request(Request.onDisconnectPut(path, value));
  }

  @override
  Future<Null> onDisconnectMerge(
      String path, Map<String, dynamic> childrenToMerge) async {
    await _request(Request.onDisconnectMerge(path, childrenToMerge));
  }

  @override
  Future<Null> onDisconnectCancel(String path) async {
    await _request(Request.onDisconnectCancel(path));
  }
}
