part of firebase_dart.database.backend_connection;

class BackendConnection {
  final Backend backend;
  final String host;
  final SparseSnapshotTree _onDisconnect = SparseSnapshotTree();

  BackendTransport? _transport;

  SparseSnapshotTree get onDisconnect => _onDisconnect;

  BackendConnection(this.backend, this.host);

  BackendTransport? get transport => _transport;

  final Map<String?, Map<QueryFilter?, Function>> _listeners = {};

  static int nextSessionId = 0;

  void open() {
    _logger.fine('Opening a backend connection');
    _transport = BackendTransport()..open();

    transport!.channel.stream
        .asyncMap(_onMessage)
        .listen((_) => null, onDone: close);

    sendMessage(HandshakeMessage(HandshakeInfo(
        DateTime.now().add(Duration(
            milliseconds:
                -2)), // add some artificial delay to mimic a realistic server
        '5',
        host,
        '${nextSessionId++}')));
  }

  void close() {
    _runOnDisconnectEvents();
  }

  void sendMessage(Message message) {
    transport!.channel.sink.add(message);
  }

  void _runOnDisconnectEvents() {
    _onDisconnect.forEachNode((path, TreeStructuredData? snap) {
      if (snap == null) return;
      backend.put(path.join('/'), snap.toJson(true));
    });
    _onDisconnect.children.clear();
    _onDisconnect.value = null;
  }

  Future<void> _onMessage(Message message) async {
    if (message is DataMessage) {
      var data;
      var status = 'ok';
      switch (message.action) {
        case DataMessage.actionAuth:
        case DataMessage.actionGauth:
          var t = JsonWebToken.unverified(message.body.cred!);
          data = {'auth': t.claims['d'] ?? t.claims.toJson()};
          await backend.auth(Auth(
              uid: t.claims.subject ?? t.claims['d']['uid'],
              provider: t.claims['provider_id'] ?? t.claims['d']['provider'],
              token: t.claims['d'] ?? t.claims.toJson()));
          break;
        case DataMessage.actionUnauth:
          await backend.auth(null);
          break;
        case DataMessage.actionListen:
          var listener =
              _listeners.putIfAbsent(message.body.path, () => {}).putIfAbsent(
                  message.body.query,
                  () => (Event event) {
                        sendMessage(DataMessage(
                            event is CancelEvent
                                ? DataMessage.actionListenRevoked
                                : DataMessage.actionSet,
                            MessageBody(
                                tag: message.body.query!.limits
                                    ? message.body.tag
                                    : null,
                                path: message.body.path,
                                data: event is CancelEvent
                                    ? 'permission denied'
                                    : (event as ValueEvent<TreeStructuredData>)
                                        .value
                                        .toJson(true))));
                      });

          try {
            await backend.listen(
              message.body.path,
              listener as void Function(Event),
              query: message.body.query,
            );
          } on FirebaseDatabaseException catch (e) {
            status = e.code;
            data = e.message;
          }
          break;
        case DataMessage.actionUnlisten:
          var listener =
              _listeners.putIfAbsent(message.body.path, () => {}).remove(
                    message.body.query,
                  );
          await backend.unlisten(
            message.body.path,
            listener as void Function(Event)?,
            query: message.body.query,
          );
          break;
        case DataMessage.actionPut:
          try {
            await backend.put(message.body.path, message.body.data,
                hash: message.body.hash);
          } on FirebaseDatabaseException catch (e) {
            status = e.code;
            data = e.message;
          }
          break;
        case DataMessage.actionMerge:
          await backend.merge(message.body.path, message.body.data);
          break;
        case DataMessage.actionOnDisconnectCancel:
          _onDisconnect.forget(Name.parsePath(message.body.path!));
          break;
        case DataMessage.actionOnDisconnectPut:
          _onDisconnect.remember(Name.parsePath(message.body.path!),
              TreeStructuredData.fromJson(message.body.data));
          break;
        case DataMessage.actionOnDisconnectMerge:
          (message.body.data as Map).forEach((childName, child) {
            _onDisconnect.remember(
                Name.parsePath(message.body.path!).child(Name(childName)),
                TreeStructuredData.fromJson(child));
          });
          break;

        default:
          throw UnimplementedError(
              'Message with action ${message.action} not implemented');
      }
      sendMessage(DataMessage(null, MessageBody(data: data, status: status),
          reqNum: message.reqNum));
    } else if (message is KeepAliveMessage) {
    } else {
      throw UnsupportedError(
          'Message of type ${message.runtimeType} not supported');
    }
  }
}
