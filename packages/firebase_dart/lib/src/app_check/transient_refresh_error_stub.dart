import 'dart:async';

import 'package:http/http.dart' as http;

bool isTransientRefreshError(Object error) {
  return error is TimeoutException || error is http.ClientException;
}
