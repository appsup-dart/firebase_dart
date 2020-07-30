// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class PersistentConnectionImpl extends PersistentConnection
    implements ConnectionDelegate {
  Connection _connection;
  Uri _url;
  Future _establishConnectionTimer;

  int _nextTag = 0;
  final quiver.BiMap<int, Pair<String, QueryFilter>> _tagToQuery =
      quiver.BiMap();

  PersistentConnectionImpl(Uri url)
      : _url = url.replace(queryParameters: {
          'ns': url.host.split('.').first,
          ...url.queryParameters,
          'v': '5',
        }),
        super.base() {
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
  Future<Null> put(String path, dynamic value, {String hash}) async {
    await _request(Request.put(path, value, hash));
  }

  @override
  Future<Null> merge(String path, Map<String, dynamic> value,
      {String hash}) async {
    await _request(Request.merge(path, value, hash));
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
    assert(_connection ==
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
    _connection = Connection(url: _url, delegate: this)..open();
  }

  @override
  Future<void> disconnect() async => _connection.close();

  @override
  Future<Null> close() async {
    await _onDataOperation.close();
    await _onAuth.close();
    await _onConnect.close();
    await disconnect();
  }

  Future _restoreState() async {
    if (_connection.state != ConnectionState.connected) return;

    // auth
    if (_authRequest != null) {
      await _request(_authRequest);
    }

    // listens
    for (var r in _listens) {
      _connection.sendRequest(r);
    }

    // requests
    _outstandingRequests.forEach((r) {
      _connection.sendRequest(r);
    });
  }

  Request _authRequest;

  @override
  Future<Map<String, dynamic>> auth(FutureOr<String> token) async {
    _authRequest = Request.auth(token);
    var b = await _request(_authRequest);
    return b.data['auth'];
  }

  @override
  Future<Null> unauth() {
    _authRequest = null;
    return _request(Request.unauth()).then((b) => null);
  }

  bool get _transportIsReady =>
      _connection != null && _connection.state == ConnectionState.connected;

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
      _connection.sendRequest(request);
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

  // ConnectionDelegate interface

  @override
  void onCacheHost(String host) {
    _url = _url.replace(host: host);
  }

  @override
  void onDataMessage(DataMessage message) {
    var query = message.body.query ?? _tagToQuery[message.body.tag]?.value;
    if (query == null && message.body.tag != null) {
      // not listening any more.
      return;
    }
    var path =
        message.body.path == null ? null : Name.parsePath(message.body.path);
    switch (message.action) {
      case DataMessage.actionSet:
      case DataMessage.actionMerge:
      case DataMessage.actionListenRevoked:
        var event = OperationEvent(
            const {
              DataMessage.actionSet: OperationEventType.overwrite,
              DataMessage.actionMerge: OperationEventType.merge,
              DataMessage.actionListenRevoked: OperationEventType.listenRevoked,
            }[message.action],
            path,
            message.body.data,
            query);
        _onDataOperation.add(event);
        break;
      case DataMessage.actionAuthRevoked:
        _onAuth.add(null);
        break;
      case DataMessage.actionSecurityDebug:
        var msg = message.body.message;
        _logger.fine('security debug: $msg');
        break;
      default:
        throw UnimplementedError(
            'Cannot handle message with action ${message.action}: ${json.encode(message)}');
    }
  }

  @override
  void onDisconnect(DisconnectReason reason) {
    _onConnect.add(false);
    _connection = null;
//TODO    if (reason == DisconnectReason.serverReset) {
    _scheduleConnect(1000);
//    }
  }

  @override
  void onKill(String reason) {
    // TODO: implement onKill
  }

  @override
  void onReady(DateTime timestamp, String sessionId) {
    _onConnect.add(true);
    _url = _url
        .replace(queryParameters: {..._url.queryParameters, 'ls': sessionId});
    _serverTimeDiff = timestamp.difference(DateTime.now());
    _restoreState();
  }

  @override
  void mockConnectionLost() {
    _connection.transport.close();
  }

  @override
  void mockResetMessage() {
    _connection._onMessage(ResetMessage(_url.host));
  }
}
