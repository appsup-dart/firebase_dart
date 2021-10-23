part of firebase.protocol;

/// Handles a non persistent connection to the server
///
/// A [Connection] is responsible for handling [ControlMessage]s (i.e. shutdown,
/// reset, ping/pong and handshake) and regularly sending [KeepAliveMessage]s.
///
/// A request can be send with the [sendRequest] method. When a response is
/// received for this request, the [Request.response] will complete with this
/// response.
class Connection {
  /// The delegate to be notified of certain events
  final ConnectionDelegate delegate;

  /// The underlying transport channel to send and receive messages
  final Transport transport;

  Connection({required this.delegate, required Uri url})
      : transport = Transport(url);

  final Map<int?, Request> _pendingRequests = {};

  final StreamController<FutureOr<Message>> _outputSink = StreamController();

  late StreamSubscription _keepAlivePeriodicStreamSubscription;

  ConnectionState? _state;
  ConnectionState? get state => _state;

  /// Opens the actual connection and starts handling messages
  void open() {
    _logger.fine('Opening a connection');

    _state = ConnectionState.connecting;

    transport.open();
    transport.channel!.stream.listen(_onMessage, onDone: () {
      close();
    }, onError: (e, tr) {
      _logger.fine('Connection error', e, tr);
    });

    _outputSink.stream.asyncMap((v) => v).listen((v) {
      transport.channel!.sink.add(v);
    }, onDone: () {
      transport.close();
    });

    _keepAlivePeriodicStreamSubscription =
        Stream.periodic(Duration(seconds: 45))
            .takeWhile((element) => !_outputSink.isClosed)
            .listen((_) => _outputSink.add(KeepAliveMessage()));
  }

  /// Closes the connection
  ///
  /// When [reason] is [DisconnectReason.serverReset], the persistent connection
  /// should reconnect immediately
  void close([DisconnectReason reason = DisconnectReason.other]) async {
    if (state != ConnectionState.disconnected) {
      _logger.fine('closing realtime connection');
      _state = ConnectionState.disconnected;

      await _outputSink.close();

      delegate.onDisconnect(reason);

      await _keepAlivePeriodicStreamSubscription.cancel();
    }
  }

  /// Sends a request through the transport channel.
  ///
  /// A responses received from the transport channel will complete the request's
  /// response
  void sendRequest(Request request) {
    // This came from the persistent connection.
    // Send it through the transport
    if (state != ConnectionState.connected) {
      _logger.fine('Tried to send on an unconnected connection');
    } else {
      if (request.message is Future) {
        _logger.fine('Sending data (contents hidden)');
      } else {
        _logger.fine(() => 'Sending data: ${json.encode(request.message)}');
      }

      if (request.message.reqNum != null) {
        _pendingRequests[request.message.reqNum] = request;
      }
      _outputSink.add(request.message);
    }
  }

  void _onDataMessage(DataMessage v) {
    _logger.fine(() => 'received data message: ${json.encode(v)}');

    if (v.reqNum != null) {
      var request = _pendingRequests.remove(v.reqNum);
      var response = Response(v, request);
      if (request != null && !request._completer.isCompleted) {
        request._completer.complete(response);
      }
    } else {
      delegate.onDataMessage(v);
    }
  }

  void _onControlMessage(ControlMessage v) {
    if (v is HandshakeMessage) {
      _onHandshake(v.info);
    } else if (v is ResetMessage) {
      _onReset(v.host);
    } else if (v is ShutdownMessage) {
      _onConnectionShutdown(v.reason);
    }
  }

  void _onConnectionShutdown(String? reason) {
    _logger.fine('Connection shutdown command received. Shutting down...');
    delegate.onKill(reason);
    close();
  }

  void _onReset(String? host) {
    _logger.fine(
        'Got a reset; killing connection to ${transport.url.host}; Updating internalHost to $host');
    delegate.onCacheHost(host);

    // Explicitly close the connection with DisconnectReason.serverReset so
    // calling code knows to reconnect immediately.
    close(DisconnectReason.serverReset);
  }

  void _onHandshake(HandshakeInfo handshake) {
    delegate.onCacheHost(handshake.host);

    if (state == ConnectionState.connecting) {
      _onConnectionReady(handshake.timestamp, handshake.sessionId);
    }
  }

  void _onConnectionReady(DateTime timestamp, String? sessionId) {
    _logger.fine('realtime connection established');
    _state = ConnectionState.connected;
    delegate.onReady(timestamp, sessionId);
  }

  void _onMessage(Message v) {
    if (v is DataMessage) {
      _onDataMessage(v);
    } else {
      _onControlMessage(v as ControlMessage);
    }
  }
}

/// Interface for receiving events of a [Connection]
abstract class ConnectionDelegate {
  /// Indicates subsequent connections should use [host] to connect
  void onCacheHost(String? host);

  /// Indicates connection is ready to send requests
  ///
  /// [timestamp] is the current timestamp of the server, [sessionId] is the
  /// session id to be used in subsequent connections
  void onReady(DateTime timestamp, String? sessionId);

  /// Called when a new message is received not related to a request
  void onDataMessage(DataMessage message);

  /// Called when the connection is lost
  ///
  /// The [reason] indicates whether or not to reconnect immediately. When
  /// reason is [DisconnectReason.serverReset], the server has sent a reset
  /// message and a reconnect should be attempted immediately.
  void onDisconnect(DisconnectReason reason);

  /// Called when the connection was killed, i.e. the server has sent a shutdown
  /// message
  void onKill(String? reason);
}

enum DisconnectReason { serverReset, other }
