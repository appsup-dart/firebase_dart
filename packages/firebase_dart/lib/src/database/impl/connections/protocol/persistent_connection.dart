// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class PersistentConnectionImpl extends PersistentConnection
    implements ConnectionDelegate {
  /// Delay after which a established connection is considered successful
  static const _successfulConnectionEstablishedDelay = Duration(seconds: 30);

  static const _idleTimeout = Duration(minutes: 1);

  /// If auth fails repeatedly, we'll assume something is wrong and log a warning / back off.
  static const int invalidAuthTokenThreshold = 3;

  static const _serverKillInterruptReason = 'server_kill';
  static const _idleInterruptReason = 'connection_idle';

  final RetryHelper _retryHelper = RetryHelper();

  final List<Request> _listens = [];

  final quiver.BiMap<int, QuerySpec> _tagToQuery = quiver.BiMap();

  final List<Request> _outstandingRequests = [];

  final StreamController<bool> _onConnect = StreamController(sync: true);
  final StreamController<OperationEvent> _onDataOperation =
      StreamController(sync: true);
  final StreamController<Map<String, dynamic>?> _onAuth =
      StreamController.broadcast();

  Connection? _connection;

  Uri _url;

  int _nextTag = 0;

  Duration? _serverTimeDiff;

  FutureOr<Request>? _authRequest;

  DateTime? _lastConnectionEstablishedTime;

  final Set<String> _interruptReasons = {};

  ConnectionState _connectionState = ConnectionState.disconnected;

  DateTime _lastWriteTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _inactivityTimer;

  bool _hasOnDisconnects = false;

  Map<String, dynamic>? _authData;

  int _currentGetTokenAttempt = 0;

  final AuthTokenProvider? _authTokenProvider;

  PersistentConnectionImpl(Uri url,
      {required AuthTokenProvider? authTokenProvider})
      : _url = url.replace(queryParameters: {
          'ns': url.host.split('.').first,
          ...url.queryParameters,
          'v': '5',
        }),
        _authTokenProvider = authTokenProvider,
        super.base();

  // ConnectionDelegate methods
  @override
  void onReady(DateTime timestamp, String? sessionId) {
    _logger.fine('onReady');
    _lastConnectionEstablishedTime = DateTime.now();
    _serverTimeDiff = timestamp.difference(DateTime.now());

    _restoreAuth();
    _url = _url
        .replace(queryParameters: {..._url.queryParameters, 'ls': sessionId});

    _onConnect.add(true);
  }

  @override
  void onCacheHost(String? host) {
    final hostPort = host?.split(':');
    String? newHost;
    int? port;
    if (hostPort != null) {
      newHost = hostPort.isNotEmpty ? hostPort[0] : null;
      port = hostPort.length > 1 ? int.parse(hostPort[1]) : null;
    }
    _url = _url.replace(host: newHost, port: port);
  }

  @override
  void onDataMessage(DataMessage message) {
    var query = _tagToQuery[message.body.tag];
    if (query == null && message.body.tag != null) {
      // not listening any more.
      return;
    }
    var path =
        message.body.path == null ? null : Name.parsePath(message.body.path!);
    if (query == null && path != null && message.body.query != null) {
      query = QuerySpec(path, message.body.query!);
    }
    switch (message.action) {
      case DataMessage.actionSet:
      case DataMessage.actionMerge:
      case DataMessage.actionListenRevoked:
        var event = OperationEvent(
            const {
              DataMessage.actionSet: OperationEventType.overwrite,
              DataMessage.actionMerge: OperationEventType.merge,
              DataMessage.actionListenRevoked: OperationEventType.listenRevoked,
            }[message.action!],
            path,
            message.body.data,
            query);
        if (!_onDataOperation.isClosed) _onDataOperation.add(event);
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
    _hasOnDisconnects = false;
    //TODO cancelSentTransactions();
    if (_shouldReconnect()) {
      bool lastConnectionWasSuccessful;
      if (_lastConnectionEstablishedTime != null) {
        var timeSinceLastConnectSucceeded =
            DateTime.now().difference(_lastConnectionEstablishedTime!);
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

    if (!_onConnect.isClosed) {
      _onConnect.add(false);
    }
  }

  @override
  void onKill(String? reason) {
    _logger.fine(
        'Firebase Database connection was forcefully killed by the server. Will not attempt reconnect. Reason: $reason');
    interrupt(_serverKillInterruptReason);
  }

  @override
  DateTime get serverTime =>
      DateTime.now().add(_serverTimeDiff ?? const Duration());

  @override
  Future<Iterable<String>> listen(String path,
      {required QueryFilter query, required String hash}) async {
    var def = QuerySpec(Name.parsePath(path), query);
    var tag = _nextTag++;
    _tagToQuery[tag] = def;

    var r = Request.listen(path, query: query, tag: tag, hash: hash);
    _addListen(r);
    _doIdleCheck();
    try {
      var body = await _request(r);
      return body.warnings ?? [];
    } on FirebaseDatabaseException {
      _tagToQuery.remove(tag);
      _removeListen(path, query);

      var event =
          OperationEvent(OperationEventType.listenRevoked, def.path, null, def);
      if (!_onDataOperation.isClosed) _onDataOperation.add(event);

      rethrow;
    }
  }

  @override
  Future<void> unlisten(String path, {required QueryFilter query}) async {
    var def = QuerySpec(Name.parsePath(path), query);
    var tag = _tagToQuery.inverse.remove(def);
    if (tag == null) return;
    var r = Request.unlisten(path, query: query, tag: tag);
    _removeListen(path, query);
    await _request(r);
    _doIdleCheck();
  }

  @override
  Future<void> put(String path, dynamic value, {String? hash}) async {
    await _putInternal(Request.put(path, value, hash));
  }

  @override
  Future<void> merge(String path, Map<String, dynamic> value,
      {String? hash}) async {
    await _putInternal(Request.merge(path, value, hash));
  }

  @override
  void purgeOutstandingWrites() async {
    await _flushRequests();
    for (var request in _outstandingRequests) {
      request._completer
          .completeError(FirebaseDatabaseException.writeCanceled());
    }
    _outstandingRequests.clear();

    // Only if we are not connected can we reliably determine that we don't have onDisconnects
    // (outstanding) anymore. Otherwise we leave the flag untouched.
    if (!_connected()) {
      _hasOnDisconnects = false;
    }
    _doIdleCheck();
  }

  @override
  Stream<bool> get onConnect => _onConnect.stream;

  @override
  Stream<OperationEvent> get onDataOperation => _onDataOperation.stream;

  @override
  Stream<Map<String, dynamic>?> get onAuth => _onAuth.stream;

  @override
  Future<void> disconnect() async => _connection!.close();

  @override
  Future<void> close() async {
    interrupt('close');
    await _onDataOperation.close();
    await _onAuth.close();
    await _onConnect.close();
  }

  @override
  Future<void> refreshAuthToken(FutureOr<String>? token) async {
    _logger.fine('Auth token refreshed.');
    if (token == null) {
      _authRequest = null;
    } else if (token is String) {
      _authRequest = Request.auth(token);
    } else {
      _authRequest = token.then<Request>((v) => Request.auth(v));
    }
    if (_connected()) {
      if (token != null) {
        await _upgradeAuth();
      } else {
        await _sendUnauth();
      }
    }
  }

  Future<void> _upgradeAuth() =>
      _sendAuthHelper(restoreStateAfterComplete: false);

  int _invalidAuthTokenCount = 0;
  bool _forceAuthTokenRefresh = false;

  Future<void> _sendAuthHelper({bool? restoreStateAfterComplete}) async {
    assert(_connected(),
        'Must be connected to send auth, but was: $connectionState');
    assert(_authRequest != null, 'Auth token must be set to authenticate!');

    var response = await _request(await _authRequest!, forceQueue: true);

    _connectionState = ConnectionState.connected;

    if (response.status == 'ok') {
      _invalidAuthTokenCount = 0;

      _setAuthData(response.data['auth']);

      if (restoreStateAfterComplete!) {
        await _restoreState();
      }
    } else {
      _authRequest = null;
      _forceAuthTokenRefresh = true;

      _setAuthData(null);

      _logger
          .fine('Authentication failed: ${response.status} (${response.data})');
      _connection!.close();

      if (response.status == 'invalid_token') {
        // We'll wait a couple times before logging the warning / increasing the
        // retry period since oauth tokens will report as "invalid" if they're
        // just expired. Plus there may be transient issues that resolve themselves.
        _invalidAuthTokenCount++;
        if (_invalidAuthTokenCount >= _invalidAuthTokenCount) {
          // Set a long reconnect delay because recovery is unlikely.
          _retryHelper.setMaxDelay();
          _logger.warning(
              'Provided authentication credentials are invalid. This '
              'usually indicates your FirebaseApp instance was not initialized '
              'correctly. Make sure your google-services.json file has the '
              'correct firebase_url and api_key. You can re-download '
              'google-services.json from '
              'https://console.firebase.google.com/.');
        }
      }
    }
  }

  Future<void> _sendUnauth() async {
    assert(_connected(), 'Must be connected to send unauth.');
    assert(_authRequest == null, 'Auth token must not be set.');
    var r = await _request(Request.unauth());
    if (r.status == 'ok') {
      _setAuthData(null);
    }
  }

  @override
  Future<void> onDisconnectPut(String path, dynamic value) async {
    _hasOnDisconnects = true;
    await _request(Request.onDisconnectPut(path, value));
    _doIdleCheck();
  }

  @override
  Future<void> onDisconnectMerge(
      String path, Map<String, dynamic> childrenToMerge) async {
    _hasOnDisconnects = true;
    await _request(Request.onDisconnectMerge(path, childrenToMerge));
    _doIdleCheck();
  }

  @override
  Future<void> onDisconnectCancel(String path) async {
    // We do not mark hasOnDisconnects true here, because we only are removing disconnects.
    // However, we can also not reliably determine whether we had onDisconnects, so we can't
    // and do not reset the flag.
    await _request(Request.onDisconnectCancel(path));
    _doIdleCheck();
  }

  @override
  void initialize() {
    _tryScheduleReconnect();
  }

  @override
  void shutdown() {
    interrupt('shutdown');
  }

  @override
  void interrupt(String reason) {
    _logger.fine('Connection interrupted for: $reason');
    _interruptReasons.add(reason);

    if (_connection != null) {
      // Will call onDisconnect and set the connection state to Disconnected
      _connection!.close();
      _connection = null;
    } else {
      _retryHelper.cancel();
      _connectionState = ConnectionState.disconnected;
    }
    // Reset timeouts
    _retryHelper.signalSuccess();

    _inactivityTimer?.cancel();
  }

  @override
  bool isInterrupted(String reason) => _interruptReasons.contains(reason);

  @override
  void resume(String reason) {
    _logger.fine('Connection no longer interrupted for: $reason');

    _interruptReasons.remove(reason);

    if (_shouldReconnect() && connectionState == ConnectionState.disconnected) {
      _retryHelper.reset();
      _tryScheduleReconnect();
    }
  }

  Future<void> _putInternal(Request request) async {
    await _request(request);
    _lastWriteTimestamp = DateTime.now();
    _doIdleCheck();
  }

  void _addListen(Request request) {
    _listens.add(request);
  }

  void _removeListen(String path, QueryFilter? query) {
    _listens.removeWhere((element) =>
        element.message.body.path == path &&
        element.message.body.query == query);
  }

  void _restoreAuth() {
    _logger.fine('calling restore state');

    assert(
      connectionState == ConnectionState.connecting,
      'Wanted to restore auth, but was in wrong state: $connectionState',
    );

    if (_authRequest == null) {
      _logger.fine('Not restoring auth because token is null.');
      _connectionState = ConnectionState.connected;
      _restoreState();
    } else {
      _logger.fine('Restoring auth.');
      _connectionState = ConnectionState.authenticating;
      _sendAuthAndRestoreState();
    }
  }

  void _sendAuthAndRestoreState() {
    _sendAuthHelper(restoreStateAfterComplete: true);
  }

  Future _restoreState() async {
    assert(connectionState == ConnectionState.connected,
        "Should be connected if we're restoring state, but we are: $connectionState");

    // Restore listens
    _logger.fine('Restoring outstanding listens');
    for (var r in _listens) {
      _connection!.sendRequest(r);
    }

    _logger.fine('Restoring writes.');
    // Restore puts
    for (var r in _outstandingRequests) {
      _connection!.sendRequest(r);
    }

    if (_connection!.state != ConnectionState.connected) return;
  }

  bool get _transportIsReady =>
      _connection != null && _connection!.state == ConnectionState.connected;

  final List<FutureOr<Request>> _requestQueue = [];

  void _queueRequest(FutureOr<Request> request) {
    _requestQueue.add(request);
    _flushRequests();
  }

  Future<MessageBody> _request(Request request,
      {bool forceQueue = false}) async {
    var message = request.message;
    switch (message.action) {
      case DataMessage.actionListen:
      case DataMessage.actionUnlisten:
      case DataMessage.actionUnauth:
      case DataMessage.actionAuth:
      case DataMessage.actionGauth:
      case DataMessage.actionStats:
        break;
      default:
        _outstandingRequests.add(request);
    }

    if (forceQueue || connectionState == ConnectionState.connected) {
      _queueRequest(request);
    }
    _doIdleCheck();
    return request.response.then<MessageBody>((r) {
      _outstandingRequests.remove(request);
      if (r.message.body.status == MessageBody.statusOk) {
        return r.message.body;
      }
      throw FirebaseDatabaseException(
          code: r.message.body.status ?? 'unknown',
          details: r.message.body.data);
    });
  }

  Completer<void>? _requestFlush;

  Future<void> _flushRequests() {
    if (_requestFlush != null) return _requestFlush!.future;
    if (_requestQueue.isEmpty) return Future.value();

    _requestFlush = Completer();

    void handleNext() {
      if (_requestQueue.isEmpty) {
        _requestFlush?.complete();
        _requestFlush = null;
        return;
      }

      var request = _requestQueue.removeAt(0);
      Future.value(request).then((request) {
        _doRequest(request);
        handleNext();
      });
    }

    handleNext();

    return _requestFlush!.future;
  }

  void _doRequest(Request request) {
    if (_transportIsReady) {
      _connection!.sendRequest(request);
    }
  }

  // testing methods
  @override
  void mockConnectionLost() {
    _connection!.transport.close();
  }

  @override
  void mockResetMessage() {
    _connection!._onMessage(ResetMessage(_url.host));
  }

  @override
  ConnectionState get connectionState => _connectionState;

  bool _shouldReconnect() => _interruptReasons.isEmpty;

  void _tryScheduleReconnect() {
    if (_shouldReconnect()) {
      assert(connectionState == ConnectionState.disconnected,
          'Not in disconnected state: $connectionState');
      _logger.fine('Scheduling connection attempt');
      final forceRefresh = _forceAuthTokenRefresh;
      _forceAuthTokenRefresh = false;
      _retryHelper.retry(() async {
        _logger.fine('Trying to fetch auth token');
        assert(
          connectionState == ConnectionState.disconnected,
          'Not in disconnected state: $connectionState',
        );
        _connectionState = ConnectionState.gettingToken;
        _currentGetTokenAttempt++;
        final thisGetTokenAttempt = _currentGetTokenAttempt;
        String? token;
        try {
          token = await _authTokenProvider?.getToken(forceRefresh);
        } catch (error) {
          if (thisGetTokenAttempt == _currentGetTokenAttempt) {
            _connectionState = ConnectionState.disconnected;
            _logger.fine('Error fetching token: $error');
            _tryScheduleReconnect();
          } else {
            _logger.fine(
                'Ignoring getToken error, because this was not the latest attempt.');
          }
        }
        if (thisGetTokenAttempt == _currentGetTokenAttempt) {
          // Someone could have interrupted us while fetching the token,
          // marking the connection as Disconnected
          if (connectionState == ConnectionState.gettingToken) {
            _logger.fine('Successfully fetched token, opening connection');
            _openNetworkConnection(token);
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
      });
    }
  }

  void _openNetworkConnection(String? token) {
    assert(
      connectionState == ConnectionState.gettingToken,
      'Trying to open network connection while in the wrong state: $connectionState',
    );
    // User might have logged out. Positive auth status is handled after authenticating with
    // the server
    if (token == null) {
      _setAuthData(null);
    }
    if (_authTokenProvider != null) {
      _authRequest = token == null ? null : Request.auth(token);
    }
    _connectionState = ConnectionState.connecting;
    _connection = Connection(url: _url, delegate: this)..open();
  }

  void _setAuthData(Map<String, dynamic>? data) {
    _authData = data;
    if (_onAuth.isClosed) return;
    _onAuth.add(_authData);
  }

  bool _connected() {
    return connectionState == ConnectionState.authenticating ||
        connectionState == ConnectionState.connected;
  }

  void _doIdleCheck() {
    if (_isIdle()) {
      if (_inactivityTimer != null) {
        _inactivityTimer!.cancel();
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

  /// Returns true if the connection is currently not being used (for listen,
  /// outstanding operations).
  bool _isIdle() =>
      _listens.isEmpty && !_hasOnDisconnects && _outstandingRequests.isEmpty;

  bool _idleHasTimedOut() {
    return _isIdle() &&
        DateTime.now().isAfter(_lastWriteTimestamp.add(_idleTimeout));
  }

  @override
  Map<String, dynamic>? get authData => _authData;
}
