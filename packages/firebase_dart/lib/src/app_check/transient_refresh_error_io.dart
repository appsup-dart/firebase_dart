import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

bool isTransientRefreshError(Object error) {
  return error is TimeoutException ||
      error is http.ClientException ||
      error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TlsException;
}
