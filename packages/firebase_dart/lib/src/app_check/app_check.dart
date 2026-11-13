import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/app_check/app_attest_challenge.dart';
import 'package:firebase_dart/src/app_check/app_check_protected.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../auth/recaptcha_verifier.dart';
import 'attestation.dart';
import 'debug_app_check_provider.dart';
import 'exchange.dart';
import 'firebase_app_check_exception.dart';
import 'token.dart';
import 'transient_refresh_error.dart';

export 'attestation.dart' show AppCheckAttestation;
export 'token.dart' show AppCheckToken;

abstract class FirebaseAppCheck {
  factory FirebaseAppCheck.instanceFor({required FirebaseApp app}) {
    return FirebaseImplementation.installation.createAppCheck(app);
  }

  static final FirebaseAppCheck instance =
      FirebaseAppCheck.instanceFor(app: Firebase.app());

  FirebaseApp get app;

  Stream<String?> get onTokenChange;

  /// Activates App Check for this [app] using [provider].
  ///
  /// Use [AppCheckProvider.debug], [AppCheckProvider.recaptchaV3], or
  /// [AppCheckProvider.recaptchaEnterprise] for a single provider. Use
  /// [AppCheckProvider.fallback] to try several providers until attestation and
  /// token exchange both succeed. On Flutter, use [FlutterAppCheckProviders]
  /// from `firebase_dart_flutter` for native attestation with optional
  /// reCAPTCHA WebView fallback.
  ///
  /// When [provider] is omitted, App Check stays inactive and [getToken]
  /// returns null.
  Future<void> activate({AppCheckProvider? provider});

  /// Requests a limited-use Firebase App Check token.
  ///
  /// This method should be used only if you need to authorize requests to a
  /// non-Firebase backend with replay protection enabled.
  Future<String> getLimitedUseToken();

  /// Get the current App Check token.
  Future<String?> getToken([bool forceRefresh = false]);

  /// If true, the SDK automatically refreshes App Check tokens as needed.
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled);
}

/// Obtains an App Check token for one [FirebaseApp].
///
/// The direct subtypes are [AttestingAppCheckProvider] and
/// [FallbackAppCheckProvider]. Extend [AttestingAppCheckProvider] to attest
/// and exchange that attestation. [AppCheckProvider.fallback] tries each child
/// until one returns a token.
sealed class AppCheckProvider {
  /// Debug provider ([DebugAppCheckProvider]).
  ///
  /// Pass [debugToken] to fix the secret in code; omit it to generate or load
  /// a UUID from Hive.
  factory AppCheckProvider.debug({String? debugToken}) = DebugAppCheckProvider;

  /// reCAPTCHA v3 provider ([ReCaptchaV3Provider]).
  factory AppCheckProvider.recaptchaV3(String siteKey) = ReCaptchaV3Provider;

  /// reCAPTCHA Enterprise provider ([ReCaptchaEnterpriseProvider]).
  factory AppCheckProvider.recaptchaEnterprise(String siteKey) =
      ReCaptchaEnterpriseProvider;

  /// Tries [providers] in order until attestation and token exchange succeed.
  ///
  /// The child that succeeds is preferred on later non-limited refreshes.
  factory AppCheckProvider.fallback(List<AppCheckProvider> providers) =
      FallbackAppCheckProvider;

  /// Returns an App Check token for [app].
  Future<AppCheckToken> getToken(
    FirebaseApp app, {
    required bool limitedUse,
  });
}

/// Leaf provider: [getToken] exchanges [getAttestation].
abstract class AttestingAppCheckProvider implements AppCheckProvider {
  const AttestingAppCheckProvider();

  /// Platform attestation before it is exchanged for an App Check JWT.
  Future<AppCheckAttestation> getAttestation(FirebaseApp app);

  @override
  Future<AppCheckToken> getToken(
    FirebaseApp app, {
    required bool limitedUse,
  }) {
    return getAttestation(app).then((attestation) => exchangeAttestation(
          app,
          attestation,
          limitedUse: limitedUse,
        ));
  }
}

/// Tries [providers] in order until one returns a token.
///
/// Attestation and exchange both belong to the child. An exchange failure tries
/// the next child. A transient error stops the list so the caller can retry.
/// The child that last produced a normal token is tried first on the next
/// non-limited request.
class FallbackAppCheckProvider implements AppCheckProvider {
  FallbackAppCheckProvider(List<AppCheckProvider> providers)
      : providers = List.unmodifiable(providers);

  static final _logger = Logger('FirebaseAppCheck');

  /// Providers in the order they are tried after the preferred child.
  final List<AppCheckProvider> providers;

  AppCheckProvider? _preferred;

  @override
  Future<AppCheckToken> getToken(
    FirebaseApp app, {
    required bool limitedUse,
  }) async {
    final ordered = <AppCheckProvider>{
      if (!limitedUse && _preferred != null) _preferred!,
      ...providers,
    };
    if (ordered.isEmpty) {
      throw FirebaseAppCheckException(
        code: 'no-providers',
        message: 'App Check: no providers configured',
      );
    }

    final failures = <Object>[];
    for (final provider in ordered) {
      try {
        final token = await provider.getToken(app, limitedUse: limitedUse);
        if (!limitedUse) _preferred = provider;
        return token;
      } catch (e, st) {
        if (isTransientRefreshError(e)) rethrow;
        failures.add(e);
        _logger.warning('App Check provider failed, trying next', e, st);
      }
    }

    throw FirebaseAppCheckException(
      code: 'attestation-failed',
      message: 'App Check: all providers failed',
      causes: failures,
    );
  }
}

/// Play Integrity provider that loads its challenge from the App Check API.
abstract class BasePlayIntegrityAppCheckProvider
    extends AttestingAppCheckProvider {
  const BasePlayIntegrityAppCheckProvider() : super();

  @protected
  @visibleForTesting
  Future<String> generatePlayIntegrityChallenge(FirebaseApp app) async {
    final appCheck = FirebaseAppCheck.instanceFor(app: app);
    if (appCheck is FirebaseAppCheckProtectedMethods) {
      return (appCheck as FirebaseAppCheckProtectedMethods)
          .generatePlayIntegrityChallenge();
    }
    throw UnimplementedError();
  }
}

/// App Attest provider that loads its challenge from the App Check API.
abstract class BaseAppAttestAppCheckProvider extends AttestingAppCheckProvider {
  const BaseAppAttestAppCheckProvider() : super();

  @protected
  @visibleForTesting
  Future<AppAttestChallenge> generateAppAttestChallenge(FirebaseApp app) async {
    final appCheck = FirebaseAppCheck.instanceFor(app: app);
    if (appCheck is FirebaseAppCheckProtectedMethods) {
      return (appCheck as FirebaseAppCheckProtectedMethods)
          .generateAppAttestChallenge();
    }
    throw UnimplementedError();
  }
}

/// reCAPTCHA-based App Check attestation (web and native fallback).
abstract class RecaptchaAppCheckProvider extends AttestingAppCheckProvider {
  RecaptchaAppCheckProvider() : super();

  String get siteKey;

  factory RecaptchaAppCheckProvider.v3(String siteKey) = ReCaptchaV3Provider;

  factory RecaptchaAppCheckProvider.enterprise(String siteKey) =
      ReCaptchaEnterpriseProvider;
}

class ReCaptchaV3Provider extends RecaptchaAppCheckProvider {
  ReCaptchaV3Provider(this.siteKey);

  @override
  final String siteKey;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    final token = await RecaptchaVerifier(siteKey: siteKey).verify();
    return AppCheckAttestation.recaptchaV3(token);
  }
}

class ReCaptchaEnterpriseProvider extends RecaptchaAppCheckProvider {
  ReCaptchaEnterpriseProvider(this.siteKey);

  @override
  final String siteKey;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    final token =
        await RecaptchaVerifier(siteKey: siteKey, action: 'fire_app_check')
            .verify();
    return AppCheckAttestation.recaptchaEnterprise(token);
  }
}
