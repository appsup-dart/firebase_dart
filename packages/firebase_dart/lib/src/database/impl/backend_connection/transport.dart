part of firebase_dart.database.backend_connection;

class BackendTransport {
  final StreamChannelController<Message> _controller =
      StreamChannelController();

  /// The channel to send to and receive from
  StreamChannel<Message> get channel => _controller.local;

  StreamChannel<Message> get foreignChannel => _controller.foreign;

  void open() {}
}
