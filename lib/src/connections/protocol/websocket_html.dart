import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';

WebSocketChannel connect(String url) => new HtmlWebSocketChannel.connect(url);
