// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

abstract class Transport extends Stream<Response> with StreamSink<Request> {

  static const connecting = 0;
  static const connected = 1;
  static const disconnected = 2;
  static const killed = 2;

  final String host;
  final String namespace;
  final String sessionId;

  Transport(this.host, this.namespace, this.sessionId) {
    _readyState = connecting;
    _connect();
  }


  final Completer<HandshakeInfo> _ready = new Completer();
  final Completer _done = new Completer();

  Future<HandshakeInfo> get ready => _ready.future;

  @override
  Future get done => _done.future;

  int _readyState;
  int get readyState => _readyState;

  HandshakeInfo _info;
  HandshakeInfo get info => _info;
  DateTime _infoReceivedTime;
  DateTime get infoReceivedTime => _infoReceivedTime;

  final Map<int, Request> _pendingRequests = {};
  final List<Completer<PongMessage>> _pings = [];

  final StreamController _output = new StreamController();
  final StreamController<Response> _input = new StreamController();

  Future _connect([String host]);
  Future _reset();
  Future _start();


  Future<PongMessage> ping() {
    _pings.add(new Completer());
    _output.add(new PingMessage());
    return _pings.last.future;
  }

  void _onDataMessage(DataMessage v) {
    var request = _pendingRequests.remove(v.reqNum);
    var response = new Response(v, request);
    if (request!=null&&!request._completer.isCompleted) {
      request._completer.complete(response);
    }
    _input.add(response);
  }


  Future _onControlMessage(ControlMessage v) async {
    if (v is HandshakeMessage) {
      _info = v.info;
      _infoReceivedTime = new DateTime.now();
      _readyState = connected;
      _ready.complete(_info);
      _start();
    } else if (v is ResetMessage) {
      await _reset();
      await _connect(v.host);
    } else if (v is PongMessage) {
      _pings.removeAt(0).complete(v);
    } else if (v is PingMessage) {
      _output.add(new PongMessage());
    } else if (v is ShutdownMessage) {
      kill();
    }
  }
  void _onMessage(Message v) {
    if (v is DataMessage) _onDataMessage(v);
    else _onControlMessage(v);
  }

  Request _prepareRequest(Request request) {
    return _pendingRequests[request.message.reqNum] = request;
  }

  @override
  void add(Request event) => _output.add(_prepareRequest(event).message);

  @override
  void addError(errorEvent, [StackTrace stackTrace]) =>
      _output.addError(errorEvent, stackTrace);

  @override
  Future addStream(Stream<Request> stream) => _output.addStream(stream.map(_prepareRequest));

  @override
  StreamSubscription<Response> listen(void onData(Response event), {Function onError, void onDone(), bool cancelOnError}) {
    return _input.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Future close() async {
    _close(disconnected);
    return done;
  }

  Future kill() async {
    _close(killed);
    return done;
  }

  Future _close(int state) async {
    await _output.close();
    _input.close();
    await _reset();
    _readyState = disconnected;
    _done.complete();
  }
}

// TODO browser websocket
class WebSocketTransport extends Transport {
  static const protocolVersion = "5";
  static const versionParam = "v";
  static const lastSessionParam = "ls";
  static const transportSessionParam = "s";

  WebSocketTransport(String host, String namespace, [String sessionId]) : super(host, namespace, sessionId);

  @override
  Future _start() async {
    _socket.sink.addStream(_output.stream.map(JSON.encode)
        .map((v){
      _logger.fine("send $v");
      return v;
    }));
    new Stream.periodic(new Duration(seconds: 45))
    .forEach((_) {
      _output.add(0);
    });
  }

  WebSocketChannel _socket;


  @override
  Future _connect([String host]) async {
    var url = new Uri(
        scheme: "wss",
        host: host ?? this.host,
        queryParameters: {
          versionParam: protocolVersion,
          "ns": namespace,
          lastSessionParam: sessionId
        },
        path: ".ws"
    );
    _logger.fine("connecting to $url");
    WebSocketChannel socket = _socket = connect(url.toString());
    socket.stream
        .map((v) {
      _logger.fine("received $v");
      return v;
    })
        .map((v)=>new Message.fromJson(JSON.decode(v) as Map<String,dynamic>)).listen(_onMessage);
  }


  @override
  Future _reset() async {
    _socket.sink.close();
    _socket = null;
  }


}
