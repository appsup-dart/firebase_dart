import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Android App Check attestation providers.
///
/// Subclass for custom attestation. Built-in providers are available via
/// [playIntegrity] and [debug].
abstract class AndroidAppCheckProvider implements AppCheckProvider {
  const AndroidAppCheckProvider();

  static const playIntegrity = AndroidPlayIntegrityProvider();

  static const debug = AndroidDebugAppCheckProvider();
}

/// Google Play Integrity attestation for App Check.
class AndroidPlayIntegrityProvider extends AndroidAppCheckProvider {
  const AndroidPlayIntegrityProvider();

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError(
        'AndroidPlayIntegrityProvider is not implemented yet');
  }
}

/// Debug provider for Android App Check.
class AndroidDebugAppCheckProvider extends AndroidAppCheckProvider {
  const AndroidDebugAppCheckProvider({this.debugToken});

  /// Debug token registered in the Firebase console. When null, the native SDK
  /// may read `FIREBASE_APPCHECK_DEBUG_TOKEN` from the environment.
  final String? debugToken;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError(
        'AndroidDebugAppCheckProvider is not implemented yet');
  }
}

/// Apple platform App Check attestation providers.
abstract class AppleAppCheckProvider implements AppCheckProvider {
  const AppleAppCheckProvider();

  static const deviceCheck = AppleDeviceCheckProvider();

  static const appAttest = AppleAppAttestProvider();

  static const appAttestWithDeviceCheckFallback =
      AppleAppAttestWithDeviceCheckFallbackProvider();

  static const debug = AppleDebugAppCheckProvider();
}

class AppleDeviceCheckProvider extends AppleAppCheckProvider {
  const AppleDeviceCheckProvider();

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError('AppleDeviceCheckProvider is not implemented yet');
  }
}

class AppleAppAttestProvider extends AppleAppCheckProvider {
  const AppleAppAttestProvider();

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError('AppleAppAttestProvider is not implemented yet');
  }
}

class AppleAppAttestWithDeviceCheckFallbackProvider
    extends AppleAppCheckProvider {
  const AppleAppAttestWithDeviceCheckFallbackProvider();

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError(
        'AppleAppAttestWithDeviceCheckFallbackProvider is not implemented yet');
  }
}

class AppleDebugAppCheckProvider extends AppleAppCheckProvider {
  const AppleDebugAppCheckProvider({this.debugToken});

  final String? debugToken;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    throw UnimplementedError(
        'AppleDebugAppCheckProvider is not implemented yet');
  }
}

/// Selects the App Check provider for the current platform.
///
/// On web and desktop, only [recaptcha] is used. On Android and Apple platforms,
/// [android] defaults to [AndroidAppCheckProvider.playIntegrity] and [apple] to
/// [AppleAppCheckProvider.deviceCheck]. The native provider is tried first; on
/// failure, [recaptcha] is used when set (same fallback model as
/// [FlutterApplicationVerifier] for auth).
class FlutterAppCheckProvider implements AppCheckProvider {
  static final _logger = Logger('FlutterAppCheckProvider');

  FlutterAppCheckProvider({
    this.android = AndroidAppCheckProvider.playIntegrity,
    this.apple = AppleAppCheckProvider.deviceCheck,
    this.recaptcha,
  });

  final AndroidAppCheckProvider android;
  final AppleAppCheckProvider apple;
  final RecaptchaAppCheckProvider? recaptcha;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (kIsWeb) {
      return _requireRecaptcha().getAttestation(app);
    }

    final platform = Platform.current;
    if (platform is AndroidPlatform) {
      return _getWithFallback(android, app, 'Android');
    }
    if (platform is IOsPlatform || platform is MacOsPlatform) {
      return _getWithFallback(apple, app, 'Apple');
    }

    return _requireRecaptcha().getAttestation(app);
  }

  RecaptchaAppCheckProvider _requireRecaptcha() {
    final provider = recaptcha;
    if (provider == null) {
      throw StateError(
          'App Check: a RecaptchaAppCheckProvider is required for this '
          'platform (e.g. recaptcha: RecaptchaAppCheckProvider.v3(siteKey)).');
    }
    return provider;
  }

  Future<AppCheckAttestation> _getWithFallback(
    AppCheckProvider primary,
    FirebaseApp app,
    String platformLabel,
  ) async {
    try {
      return await primary.getAttestation(app);
    } catch (e, st) {
      _logger.warning(
        'App Check $platformLabel attestation failed, trying reCAPTCHA.',
        e,
        st,
      );
      final fallback = recaptcha;
      if (fallback != null) {
        return fallback.getAttestation(app);
      }
      Error.throwWithStackTrace(e, st);
    }
  }
}
