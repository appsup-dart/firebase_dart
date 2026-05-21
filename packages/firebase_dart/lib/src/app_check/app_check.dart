import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/rpc/http_util.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:googleapis/firebaseappcheck/v1.dart';

import 'package:http/http.dart' as http;

import '../auth/recaptcha_verifier.dart';

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
  /// web and server-side Dart. On Flutter, prefer [FlutterAppCheckProvider] from
  /// `firebase_dart_flutter`, which selects native attestation per platform and
  /// can fall back to [RecaptchaAppCheckProvider].
  Future<void> activate({AppCheckProvider? provider});

  /// Requests a limited-use Firebase App Check token.
  ///
  /// This method should be used only if you need to authorize requests to a
  /// non-Firebase backend.
  Future<String> getLimitedUseToken();

  /// Get the current App Check token.
  Future<String?> getToken([bool forceRefresh = false]);

  /// If true, the SDK automatically refreshes App Check tokens as needed.
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled);
}

/// Exchanges attestation for an App Check JWT.
abstract class AppCheckProvider {
  Future<AppCheckToken> getToken(FirebaseApp app);
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
  Future<AppCheckToken> getToken(FirebaseApp app) async {
    var attestedClaimsToken =
        await RecaptchaVerifier(siteKey: siteKey).verify();

    var response = await FirebaseappcheckApi(
            ApiKeyClient(http.Client(), apiKey: app.options.apiKey))
        .projects
        .apps
        .exchangeRecaptchaV3Token(
            GoogleFirebaseAppcheckV1ExchangeRecaptchaV3TokenRequest()
              ..recaptchaV3Token = attestedClaimsToken,
            'projects/${app.options.projectId}/apps/${app.options.appId}');

    /// ttl is a duration in seconds with up to nine fractional digits, ending with 's'. Example: "3.5s".
    var duration = Duration(
        microseconds: (num.parse(RegExp(r'^([\d\.]+)s$')
                    .firstMatch(response.ttl!)!
                    .group(1)!) *
                1000 *
                1000)
            .round());

    return AppCheckToken(response.token!, DateTime.now().add(duration));
  }
}

class ReCaptchaEnterpriseProvider implements RecaptchaAppCheckProvider {
  ReCaptchaEnterpriseProvider(this.siteKey);

  @override
  final String siteKey;

  @override
  Future<AppCheckToken> getToken(FirebaseApp app) async {
    final attestedClaimsToken =
        await RecaptchaVerifier(siteKey: siteKey, action: 'fire_app_check')
            .verify();

    final response = await FirebaseappcheckApi(
            ApiKeyClient(http.Client(), apiKey: app.options.apiKey))
        .projects
        .apps
        .exchangeRecaptchaEnterpriseToken(
            GoogleFirebaseAppcheckV1ExchangeRecaptchaEnterpriseTokenRequest()
              ..recaptchaEnterpriseToken = attestedClaimsToken,
            'projects/${app.options.projectId}/apps/${app.options.appId}');

    /// ttl is a duration in seconds with up to nine fractional digits, ending with 's'. Example: "3.5s".
    final duration = Duration(
        microseconds: (num.parse(RegExp(r'^([\d\.]+)s$')
                    .firstMatch(response.ttl!)!
                    .group(1)!) *
                1000 *
                1000)
            .round());

    return AppCheckToken(response.token!, DateTime.now().add(duration));
  }
}
