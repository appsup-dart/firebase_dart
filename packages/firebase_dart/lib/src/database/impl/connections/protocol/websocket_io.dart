import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

WebSocketChannel connect(String url, {Map<String, String>? headers}) =>
    IOWebSocketChannel.connect(url, headers: headers);
