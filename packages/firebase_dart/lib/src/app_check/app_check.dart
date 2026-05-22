import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/app_check/app_check_protected.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:meta/meta.dart';

import '../auth/recaptcha_verifier.dart';
import 'attestation.dart';

export 'attestation.dart' show AppCheckAttestation;

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
  /// Pass a [RecaptchaAppCheckProvider] (e.g. [RecaptchaAppCheckProvider.v3]) on
  /// web and server-side Dart. On Flutter, use [FlutterAppCheckProvider] from
  /// `firebase_dart_flutter` with reCAPTCHA site keys and optional `use*` flags.
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

/// Obtains platform attestation to be exchanged for an App Check JWT by
/// [FirebaseAppCheck].
abstract class AppCheckProvider {
  Future<AppCheckAttestation> getAttestation(FirebaseApp app);
}

/// Base class for platform [AppCheckProvider]s that need App Check REST helpers.
abstract class BaseAppCheckProvider implements AppCheckProvider {
  const BaseAppCheckProvider();

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

class AppCheckToken {
  /// The token string in JWT format.
  final String token;

  /// The local timestamp after which the token will expire.
  final DateTime expireTime;

  AppCheckToken(this.token, this.expireTime);
}

/// reCAPTCHA-based App Check attestation (web and native fallback).
abstract class RecaptchaAppCheckProvider implements AppCheckProvider {
  String get siteKey;

  factory RecaptchaAppCheckProvider.v3(String siteKey) = ReCaptchaV3Provider;

  factory RecaptchaAppCheckProvider.enterprise(String siteKey) =
      ReCaptchaEnterpriseProvider;
}

class ReCaptchaV3Provider implements RecaptchaAppCheckProvider {
  ReCaptchaV3Provider(this.siteKey);

  @override
  final String siteKey;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    final token = await RecaptchaVerifier(siteKey: siteKey).verify();
    return AppCheckAttestation.recaptchaV3(token);
  }
}

class ReCaptchaEnterpriseProvider implements RecaptchaAppCheckProvider {
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
