import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';

/// Native Recaptcha Enterprise integration for Android and iOS.
///
/// This module uses the [recaptcha_enterprise_flutter](https://pub.dev/packages/recaptcha_enterprise_flutter)
/// plugin to enable invisible Recaptcha Enterprise verification using the Google-provided SDKs.
///
/// **Supported platforms:**
/// - Android (API 21 or higher)
/// - iOS (iOS 12 or higher)
///
/// Not supported on Web or desktop platforms.
class RecaptchaEnterpriseNativeVerifier {
  final String siteKey;

  final String action;

  RecaptchaEnterpriseNativeVerifier(
      {required this.siteKey, required this.action});

  Future<String> verify() async {
    if (Platform.current is! AndroidPlatform &&
        Platform.current is! IOsPlatform) {
      throw UnsupportedError(
          'Recaptcha Enterprise native verifier is only supported on Android and iOS');
    }
    var client = await Recaptcha.fetchClient(siteKey);
    var token = await client.execute(RecaptchaAction.custom(action));
    return token;
  }
}
