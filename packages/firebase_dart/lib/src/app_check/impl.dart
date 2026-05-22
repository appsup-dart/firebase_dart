import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/app_check/app_attest_challenge.dart';
import 'package:firebase_dart/src/app_check/app_attest_store.dart'
    as app_attest_store;
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/app_check/app_check_protected.dart';
import 'package:firebase_dart/src/app_check/exchange.dart';
import 'package:firebase_dart/src/app_check/transient_refresh_error.dart';
import 'package:googleapis/firebaseappcheck/v1.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../core/impl/app.dart';

class FirebaseAppCheckImpl extends FirebaseService
    implements FirebaseAppCheck, FirebaseAppCheckProtectedMethods {
  static final _logger = Logger('FirebaseAppCheck');
  FirebaseAppCheckImpl(super.app);

  AppCheckProviders? _providers;
  AppCheckProvider? _preferredProvider;
  AppCheckToken? _cachedToken;
  bool _isTokenAutoRefreshEnabled = true;
  Timer? _refreshTimer;
  final _tokenChanges = BehaviorSubject<String?>(sync: true);

  @override
  Stream<String?> get onTokenChange => _tokenChanges.stream;

  @override
  Future<void> activate({AppCheckProviders? providers}) async {
    _providers = providers;
    _preferredProvider = null;
    if (_providers != null) {
      _scheduleTokenRefresh(_cachedToken);
    }
  }

  @override
  Future<String> getLimitedUseToken() async {
    final token = await _obtainToken(limitedUse: true);
    return token.token;
  }

  @override
  Future<String?> getToken([bool forceRefresh = false]) async {
    if (_providers == null) return null;
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
    if (!isTokenAutoRefreshEnabled || _providers == null) return;
    final cached = _cachedToken;
    if (cached != null && _isTokenValid(cached)) {
      _scheduleTokenRefresh(cached);
    } else {
      await _updateToken();
    }
  }

  @override
  Future<String> generatePlayIntegrityChallenge() async {
    final response =
        await appCheckApi(app).projects.apps.generatePlayIntegrityChallenge(
              GoogleFirebaseAppcheckV1GeneratePlayIntegrityChallengeRequest(),
              appCheckAppResourceName(app),
            );
    final challenge = response.challenge;
    if (challenge == null || challenge.isEmpty) {
      throw StateError('App Check: empty Play Integrity challenge');
    }
    return challenge;
  }

  @override
  Future<AppAttestChallenge> generateAppAttestChallenge() async {
    final response =
        await appCheckApi(app).projects.apps.generateAppAttestChallenge(
              GoogleFirebaseAppcheckV1GenerateAppAttestChallengeRequest(),
              appCheckAppResourceName(app),
            );
    final challenge = response.challenge;
    if (challenge == null || challenge.isEmpty) {
      throw StateError('App Check: empty App Attest challenge');
    }
    final stored = await app_attest_store.loadAppAttestState(app.options.appId);
    if (stored == null) {
      return AppAttestChallenge(challenge: challenge);
    }
    return AppAttestChallenge(
      challenge: challenge,
      keyId: stored.keyId,
      artifact: stored.artifact,
    );
  }

  @override
  Future<void> delete() async {
    _cancelRefreshTimer();
    await _tokenChanges.close();
    await super.delete();
  }

  static bool _isTokenValid(AppCheckToken? token) =>
      token != null && token.expireTime.isAfter(clock.now());

  Future<void>? _updateTokenFuture;

  Future<void> _updateToken() async {
    if (_providers == null) return;

    return _updateTokenFuture ??= Future.microtask(() async {
      final token = await _obtainToken(limitedUse: false);
      _cachedToken = token;
      if (!_tokenChanges.isClosed) {
        _tokenChanges.add(token.token);
      }
      _scheduleTokenRefresh(token);
      _updateTokenFuture = null;
    });
  }

  Future<AppCheckToken> _obtainToken({required bool limitedUse}) async {
    final providers = _providers;
    if (providers == null) {
      throw StateError(
          'App Check not activated. Call activate() with providers first.');
    }
    final ordered = {
      if (_preferredProvider != null) _preferredProvider!,
      ...providers.providers,
    };
    if (ordered.isEmpty) {
      throw StateError('App Check: no providers configured');
    }

    for (final provider in ordered) {
      try {
        final attestation = await provider.getAttestation(app);
        final token = await exchangeAttestation(
          app,
          attestation,
          limitedUse: limitedUse,
        );
        _preferredProvider = provider;
        return token;
      } catch (e, st) {
        if (isTransientRefreshError(e)) {
          rethrow;
        }
        _logger.warning('App Check provider failed, trying next', e, st);
      }
    }

    throw StateError('App Check: all providers failed');
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

  void _scheduleTokenRefresh(AppCheckToken? token) {
    _cancelRefreshTimer();
    if (!_isTokenAutoRefreshEnabled) return;

    final delay = token == null ? Duration.zero : _tokenRefreshDelay(token);
    if (delay <= Duration.zero) {
      unawaited(_refreshToken());
      return;
    }
    _refreshTimer = Timer(delay, () => unawaited(_refreshToken()));
  }

  static const _refreshRetryDelay = Duration(seconds: 30);

  Future<void> _refreshToken() async {
    if (isDeleted || _providers == null) return;
    try {
      await _updateToken();
    } catch (e, st) {
      if (!isTransientRefreshError(e)) {
        rethrow;
      }
      _logger.fine('App Check token refresh failed, will retry', e, st);
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
