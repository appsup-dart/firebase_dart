import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/app_check/transient_refresh_error.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../core/impl/app.dart';

class FirebaseAppCheckImpl extends FirebaseService implements FirebaseAppCheck {
  static final _logger = Logger('FirebaseAppCheck');
  FirebaseAppCheckImpl(super.app);

  AppCheckProvider? _provider;
  AppCheckToken? _cachedToken;
  bool _isTokenAutoRefreshEnabled = true;
  Timer? _refreshTimer;
  final _tokenChanges = BehaviorSubject<String?>(sync: true);

  @override
  Stream<String?> get onTokenChange => _tokenChanges.stream;

  @override
  Future<void> activate({AppCheckProvider? provider}) async {
    _provider = provider;
    if (_provider != null) {
      await _updateToken();
    }
  }

  @override
  Future<String> getLimitedUseToken() {
    // TODO: implement getLimitedUseToken
    throw UnimplementedError();
  }

  @override
  Future<String?> getToken([bool forceRefresh = false]) async {
    if (_provider == null) return null;
    if (forceRefresh || !_isTokenValid(_cachedToken)) {
      await _updateToken();
    }
    return _cachedToken?.token;
  }

  @override
  Future<void> setTokenAutoRefreshEnabled(
      bool isTokenAutoRefreshEnabled) async {
    _isTokenAutoRefreshEnabled = isTokenAutoRefreshEnabled;
    _cancelRefreshTimer();
    if (!isTokenAutoRefreshEnabled || _provider == null) return;
    final cached = _cachedToken;
    if (cached != null && _isTokenValid(cached)) {
      _scheduleTokenRefresh(cached);
    } else {
      await _updateToken();
    }
  }

  @override
  Future<void> delete() async {
    _cancelRefreshTimer();
    await _tokenChanges.close();
    await super.delete();
  }

  static bool _isTokenValid(AppCheckToken? token) =>
      token != null && token.expireTime.isAfter(clock.now());

  Future<void> _updateToken() async {
    final provider = _provider;
    if (provider == null) return;

    final token = await provider.getToken(app);
    _cachedToken = token;
    if (!_tokenChanges.isClosed) {
      _tokenChanges.add(token.token);
    }
    _scheduleTokenRefresh(token);
  }

  /// Matches Firebase JS: issuedAt + (50% × TTL) + 5 minutes, capped at
  /// expireTime − 5 minutes. [expireTime] is treated as issuedAt + TTL.
  static Duration _tokenRefreshDelay(AppCheckToken token) {
    final now = clock.now();
    final ttl = token.expireTime.difference(now);
    if (ttl <= Duration.zero) return Duration.zero;

    final halfTtl = Duration(microseconds: (ttl.inMicroseconds * 0.5).round());
    var nextRefreshAt = now.add(halfTtl + const Duration(minutes: 5));
    final latestAllowable =
        token.expireTime.subtract(const Duration(minutes: 5));
    if (nextRefreshAt.isAfter(latestAllowable)) {
      nextRefreshAt = latestAllowable;
    }
    final delay = nextRefreshAt.difference(now);
    return delay.isNegative ? Duration.zero : delay;
  }

  void _scheduleTokenRefresh(AppCheckToken token) {
    _cancelRefreshTimer();
    if (!_isTokenAutoRefreshEnabled) return;

    final delay = _tokenRefreshDelay(token);
    if (delay <= Duration.zero) {
      unawaited(_refreshToken());
      return;
    }
    _refreshTimer = Timer(delay, () => unawaited(_refreshToken()));
  }

  static const _refreshRetryDelay = Duration(seconds: 30);

  Future<void> _refreshToken() async {
    if (isDeleted || _provider == null) return;
    try {
      await _updateToken();
    } catch (e, st) {
      if (!isTransientRefreshError(e)) {
        Error.throwWithStackTrace(e, st);
      }
      _logger.warning('App Check token refresh failed, will retry', e, st);
      final cached = _cachedToken;
      if (cached == null || !_isTokenValid(cached)) return;
      _cancelRefreshTimer();
      if (!_isTokenAutoRefreshEnabled) return;
      _refreshTimer =
          Timer(_refreshRetryDelay, () => unawaited(_refreshToken()));
    }
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
