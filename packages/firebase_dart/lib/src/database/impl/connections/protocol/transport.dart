// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

/// Represents the transport channel to send and receive messages
class Transport {
  /// The url to connect to
  final Uri url;

  StreamChannel<Message>? _channel;

  Transport(this.url);

  static final List<Transport> _openTransports = [];

  @visibleForTesting
  static Iterable<Transport> get openTransports sync* {
    yield* _openTransports;
  }

  /// The channel to send to and receive from
  StreamChannel<Message>? get channel => _channel;

  /// Connects to the [url] and initiates the [channel]
  ///
  /// Depending on the scheme of the [url], an appropriate channel will be built
  void open() {
    switch (url.scheme) {
      case 'https':
      case 'http':
        var connectionUrl = url.replace(
            path: '.ws', scheme: url.scheme == 'https' ? 'wss' : 'ws');
        var socket = websocket.connect(connectionUrl.toString());
        _channel = socket
            .cast<String>()
            .transform<String>(framesChannelTransformer)
            .transform<dynamic>(jsonDocument)
            .transform<Message>(messageChannelTransformer);
        break;
      case 'mem':
        _channel = MemoryBackend.connect(url);
        break;
      default:
        throw UnsupportedError('Unsupported scheme ${url.scheme}');
    }
    _openTransports.add(this);
  }

  void close() async {
    await channel!.sink.close();
    _openTransports.remove(this);
  }
}
