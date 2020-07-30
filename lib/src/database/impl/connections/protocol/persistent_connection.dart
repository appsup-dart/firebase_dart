// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class PersistentConnectionImpl extends PersistentConnection
    implements ConnectionDelegate {
  /// Delay after which a established connection is considered successful
  static const _successfulConnectionEstablishedDelay = Duration(seconds: 30);

  static const _idleTimeout = Duration(minutes: 1);

  static const _serverKillInterruptReason = 'server_kill';
  static const _idleInterruptReason = 'connection_idle';

  final RetryHelper _retryHelper = RetryHelper();

  final List<Request> _listens = [];

  final quiver.BiMap<int, Pair<String, QueryFilter>> _tagToQuery =
      quiver.BiMap();

  final List<Request> _outstandingRequests = [];

  final StreamController<bool> _onConnect = StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation =
      StreamController(sync: true);
  final StreamController<Map> _onAuth = StreamController(sync: true);

  Connection _connection;

  Uri _url;

  int _nextTag = 0;

  Duration _serverTimeDiff;

  Request _authRequest;

  DateTime _lastConnectionEstablishedTime;

  final Set<String> _interruptReasons = {};

  ConnectionState _connectionState = ConnectionState.disconnected;

  DateTime _lastWriteTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  Timer _inactivityTimer;

  PersistentConnectionImpl(Uri url)
      : _url = url.replace(queryParameters: {
          'ns': url.host.split('.').first,
          ...url.queryParameters,
          'v': '5',
        }),
        super.base();

  // ConnectionDelegate methods
  @override
  void onReady(DateTime timestamp, String sessionId) {
    _onConnect.add(true);
    _url = _url
        .replace(queryParameters: {..._url.queryParameters, 'ls': sessionId});
    _serverTimeDiff = timestamp.difference(DateTime.now());
    _restoreState();
  }

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
    _logger.fine('Got on disconnect due to $reason');
    _connectionState = ConnectionState.disconnected;
    _connection = null;
    //TODO this.hasOnDisconnects = false;
    //TODO requestCBHash.clear();
    //TODO cancelSentTransactions();
    if (_shouldReconnect()) {
      bool lastConnectionWasSuccessful;
      if (_lastConnectionEstablishedTime != null) {
        var timeSinceLastConnectSucceeded =
            DateTime.now().difference(_lastConnectionEstablishedTime);
        lastConnectionWasSuccessful = timeSinceLastConnectSucceeded >
            _successfulConnectionEstablishedDelay;
      } else {
        lastConnectionWasSuccessful = false;
      }
      if (reason == DisconnectReason.serverReset ||
          lastConnectionWasSuccessful) {
        _retryHelper.signalSuccess();
      }
      _tryScheduleReconnect();
    }
    _lastConnectionEstablishedTime = null;

    _onConnect.add(false);
  }

  @override
  void onKill(String reason) {
    _logger.fine(
        'Firebase Database connection was forcefully killed by the server. Will not attempt reconnect. Reason: $reason');
    interrupt(_serverKillInterruptReason);
  }

  @override
  DateTime get serverTime =>
      DateTime.now().add(_serverTimeDiff ?? const Duration());

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

  @override
  Future<Null> put(String path, dynamic value, {String hash}) async {
    await _request(Request.put(path, value, hash));
    _lastWriteTimestamp = DateTime.now();
  }

  @override
  Future<Null> merge(String path, Map<String, dynamic> value,
      {String hash}) async {
    await _request(Request.merge(path, value, hash));
    _lastWriteTimestamp = DateTime.now();
  }

  @override
  Stream<bool> get onConnect => _onConnect.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;

  @override
  Stream<Map> get onAuth => _onAuth.stream;

  @override
  Future<void> disconnect() async => _connection.close();

  @override
  Future<Null> close() async {
    await _onDataOperation.close();
    await _onAuth.close();
    await _onConnect.close();
    await disconnect();
  }

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

  @override
  void initialize() {
    _tryScheduleReconnect();
  }

  @override
  void shutdown() {
    interrupt('shutdown');
  }

  void _addListen(Request request) {
    _listens.add(request);
  }

  void _removeListen(String path, QueryFilter query) {
    _listens.removeWhere((element) =>
        (element.message as DataMessage).body.path == path &&
        (element.message as DataMessage).body.query.toFilter() == query);
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

  // testing methods
  @override
  void mockConnectionLost() {
    _connection.transport.close();
  }

  @override
  void mockResetMessage() {
    _connection._onMessage(ResetMessage(_url.host));
  }

  @override
  void interrupt(String reason) {
    _logger.fine('Connection interrupted for: $reason');
    _interruptReasons.add(reason);

    if (_connection != null) {
      // Will call onDisconnect and set the connection state to Disconnected
      _connection.close();
      _connection = null;
    } else {
      _retryHelper.cancel();
      _connectionState = ConnectionState.disconnected;
    }
    // Reset timeouts
    _retryHelper.signalSuccess();
  }

  @override
  bool isInterrupted(String reason) => _interruptReasons.contains(reason);

  @override
  void resume(String reason) {
    _logger.fine('Connection no longer interrupted for: $reason');

    _interruptReasons.remove(reason);

    if (_shouldReconnect() && connectionState == ConnectionState.disconnected) {
      _tryScheduleReconnect();
    }
  }

  ConnectionState get connectionState => _connectionState;

  bool _shouldReconnect() => _interruptReasons.isEmpty;

  void _tryScheduleReconnect() {
    if (_shouldReconnect()) {
      assert(connectionState == ConnectionState.disconnected,
          'Not in disconnected state: $connectionState');
      _logger.fine('Scheduling connection attempt');
/*TODO
      final forceRefresh = this.forceAuthTokenRefresh;
      this.forceAuthTokenRefresh = false;
*/
      _retryHelper.retry(() async {
        _logger.fine('Trying to fetch auth token');
        assert(
          connectionState == ConnectionState.disconnected,
          'Not in disconnected state: $connectionState',
        );
/* TODO
        _connectionState = ConnectionState.gettingToken;
        currentGetTokenAttempt++;
        final thisGetTokenAttempt = currentGetTokenAttempt;
        var token;
        try {
          token = await authTokenProvider.getToken(forceRefresh);
        } catch (error) {
          if (thisGetTokenAttempt == currentGetTokenAttempt) {
            _connectionState = ConnectionState.disconnected;
            _logger.fine('Error fetching token: $error');
            _tryScheduleReconnect();
          } else {
            _logger.fine(
                'Ignoring getToken error, because this was not the latest attempt.');
          }
        }
        if (thisGetTokenAttempt == currentGetTokenAttempt) {
          // Someone could have interrupted us while fetching the token,
          // marking the connection as Disconnected
          if (connectionState == ConnectionState.gettingToken) {
            _logger.fine('Successfully fetched token, opening connection');
*/
        _openNetworkConnection(/*token*/);
/*TODO
          } else {
            assert(
              connectionState == ConnectionState.disconnected,
              'Expected connection state disconnected, but was $connectionState',
            );
            _logger.fine('Not opening connection after token refresh, '
                'because connection was set to disconnected');
          }
        } else {
          _logger.fine(
              'Ignoring getToken result, because this was not the latest attempt.');
        }
*/
      });
    }
  }

  void _openNetworkConnection(/*String token*/) {
/*
    assert(
        connectionState == ConnectionState.gettingToken,
        'Trying to open network connection while in the wrong state: $connectionState',
        );
    // User might have logged out. Positive auth status is handled after authenticating with
    // the server
    if (token == null) {
      delegate.onAuthStatus(false);
    }
    authToken = token;
*/
    _connectionState = ConnectionState.connecting;
    _connection = Connection(url: _url, delegate: this)..open();
  }

  @override
  void purgeOutstandingWrites() {
    for (var request in _outstandingRequests) {
      request._completer
          .completeError(FirebaseDatabaseException.writeCanceled());
    }
    _outstandingRequests.clear();

    // Only if we are not connected can we reliably determine that we don't have onDisconnects
    // (outstanding) anymore. Otherwise we leave the flag untouched.
    if (!_connected()) {
//TODO      this.hasOnDisconnects = false;
    }
    _doIdleCheck();
  }

  bool _connected() {
    return connectionState == ConnectionState.authenticating ||
        connectionState == ConnectionState.connected;
  }

  void _doIdleCheck() {
    if (_isIdle()) {
      if (_inactivityTimer != null) {
        _inactivityTimer.cancel();
      }

      _inactivityTimer = Timer(_idleTimeout, () {
        _inactivityTimer = null;
        if (_idleHasTimedOut()) {
          interrupt(_idleInterruptReason);
        } else {
          _doIdleCheck();
        }
      });
    } else if (isInterrupted(_idleInterruptReason)) {
      assert(!_isIdle());
      resume(_idleInterruptReason);
    }
  }

  bool _isIdle() =>
      _listens.isEmpty
      //TODO && this.requestCBHash.isEmpty()
      //TODO && !this.hasOnDisconnects
      &&
      _outstandingRequests.isEmpty;

  bool _idleHasTimedOut() {
    return _isIdle() &&
        DateTime.now().isAfter(_lastWriteTimestamp.add(_idleTimeout));
  }
}
