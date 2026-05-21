import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/rpc/http_util.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebaseapis/firebaseappcheck/v1beta.dart';

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

  Future<void> activate(
      {WebProvider? webProvider,
      AndroidProvider androidProvider = AndroidProvider.playIntegrity,
      AppleProvider appleProvider = AppleProvider.deviceCheck});

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

// An enum representing the different types of Android App Attest providers.
enum AndroidProvider {
  // The debug provider
  debug,
  // The play integrity provider (Firebase recommended)
  playIntegrity
}

/// An enum representing the different types of Apple App Attest providers.
enum AppleProvider {
  /// The debug provider. No further configuration in your iOS code required. You simply need to copy/paste the debug token
  /// from the console when you run the app and add the token to your Firebase console. See documentation:
  /// https://firebase.google.com/docs/app-check/ios/debug-provider
  debug,

  /// the default deviceCheck provider. See documentation: https://firebase.google.com/docs/app-check/ios/devicecheck-provider
  deviceCheck,
  // The app attest provider (Firebase recommended). See documentation: https://firebase.google.com/docs/app-check/ios/app-attest-provider
  appAttest,

  /// appAttest provider is only available on iOS 14.0+, macOS 14.0+ so this will fall back to deviceCheck provider if appAtest provider
  /// is not available
  appAttestWithDeviceCheckFallback
}

/// An App Check provider.
abstract class AppCheckProvider {
  /// Returns an AppCheck token.
  Future<AppCheckToken> getToken(FirebaseApp app);
}

class AppCheckToken {
  /// The token string in JWT format.
  final String token;

  /// The local timestamp after which the token will expire.
  final DateTime expireTime;

  AppCheckToken(this.token, this.expireTime);
}

abstract class WebProvider extends AppCheckProvider {
  final String siteKey;

  WebProvider(this.siteKey);
}

class ReCaptchaV3Provider extends WebProvider {
  ReCaptchaV3Provider(super.siteKey);

  @override
  Future<AppCheckToken> getToken(FirebaseApp app) async {
    var attestedClaimsToken =
        await RecaptchaVerifier(siteKey: siteKey).verify();

    var response = await FirebaseappcheckApi(
            ApiKeyClient(http.Client(), apiKey: app.options.apiKey))
        .projects
        .apps
        .exchangeRecaptchaV3Token(
            GoogleFirebaseAppcheckV1betaExchangeRecaptchaV3TokenRequest()
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

class ReCaptchaEnterpriseProvider extends WebProvider {
  ReCaptchaEnterpriseProvider(super.siteKey);

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
            GoogleFirebaseAppcheckV1betaExchangeRecaptchaEnterpriseTokenRequest()
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
