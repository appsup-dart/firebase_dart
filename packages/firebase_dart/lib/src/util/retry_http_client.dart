import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Returns an HTTP client that retries transient network failures.
http.Client createRetryHttpClient({
  required bool Function(Object error, StackTrace stackTrace) whenError,
  http.Client? inner,
  int retries = 3,
}) {
  return RetryClient(
    inner ?? http.Client(),
    retries: retries,
    whenError: whenError,
    delay: (retryCount) =>
        Duration(milliseconds: 500 * math.pow(2, retryCount).round()),
  );
}
