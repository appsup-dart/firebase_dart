import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

final _logger = Logger('retry-helper');

class RetryHelper {
  /// The minimum delay for a retry
  final Duration minRetryDelayAfterFailure;

  /// The maximum retry delay
  final Duration maxRetryDelay;

  /// The range of the delay that will be used at random
  /// 0 => no randomness 0.5 => at least half the current delay
  /// 1 => any delay between [min, max)

  final double jitterFactor;

  /// The backoff exponent
  final double retryExponent;

  final Random _random = Random();

  Timer? _scheduledRetry;

  Duration _currentRetryDelay = Duration();
  bool _lastWasSuccess = true;

  RetryHelper(
      {this.minRetryDelayAfterFailure = const Duration(seconds: 1),
      this.maxRetryDelay = const Duration(seconds: 30),
      this.retryExponent = 1.3,
      this.jitterFactor = 0.5});

  void reset() {
    _lastWasSuccess = true;
    _currentRetryDelay = Duration();
  }

  void retry(final Function() runnable) {
    Duration delay;
    if (_scheduledRetry != null) {
      _logger.fine('Cancelling previous scheduled retry');
      _scheduledRetry!.cancel();
      _scheduledRetry = null;
    }
    if (_lastWasSuccess) {
      delay = const Duration();
    } else {
      if (_currentRetryDelay == Duration()) {
        _currentRetryDelay = minRetryDelayAfterFailure;
      } else {
        var newDelay = _currentRetryDelay * retryExponent;
        _currentRetryDelay =
            newDelay < maxRetryDelay ? newDelay : maxRetryDelay;
      }
      delay = ((_currentRetryDelay * (1 - jitterFactor)) +
          (_currentRetryDelay * (jitterFactor * _random.nextDouble())));
    }
    _lastWasSuccess = false;
    _logger.fine('Scheduling retry in $delay');
    if (delay == Duration()) {
      // run outside Timer to work with fakeAsync
      runnable();
    } else {
      _scheduledRetry = Timer(delay, () {
        _scheduledRetry = null;
        runnable();
      });
    }
  }

  void signalSuccess() {
    _lastWasSuccess = true;
    _currentRetryDelay = Duration();
  }

  void setMaxDelay() {
    _currentRetryDelay = maxRetryDelay;
  }

  void cancel() {
    if (_scheduledRetry != null) {
      _logger.fine('Cancelling existing retry attempt');
      _scheduledRetry!.cancel();
      _scheduledRetry = null;
    } else {
      _logger.fine('No existing retry attempt to cancel');
    }
    _currentRetryDelay = Duration();
  }
}
