import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:firebase_dart_flutter/src/deep_link_retriever.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

/// Verifies the app's authenticity using reCAPTCHA via redirect-based verification.
///
/// This is used for phone authentication on mobile and desktop platforms except for web.
///
/// ## Supported Platforms
/// - **iOS**
/// - **macOS**
/// - **Android**
///
/// ## Platform Configuration
/// On **iOS** and **macOS**, register a URL scheme derived from your Firebase
/// **app ID** (`FirebaseOptions.appId`, e.g. `1:123:ios:abc`): prefix `app-` and
/// replace every `:` with `-`, e.g. `app-1-123-ios-abc`.
///
/// 1. Open your project in Xcode.
/// 2. In the project navigator, select your app target.
/// 3. Go to the **Info** tab and expand **URL Types**.
/// 4. Click the + button and set:
///    - **Identifier**: (any unique string, e.g., your bundle id).
///    - **URL Schemes**: the `app-…` value above (not the reversed OAuth client id).
///
/// See: [Firebase docs: Set up reCAPTCHA verification](https://firebase.google.com/docs/auth/ios/phone-auth#set-up-recaptcha-verification)
///
/// On **Android**, no special configuration is typically required, as Firebase handles the intent redirect internally.
///
/// This verifier launches a browser or webview to handle the reCAPTCHA flow.
/// Upon successful completion, it waits for the redirect via deep link or intent.
///
/// Throws [UnimplementedError] on platforms other than iOS, macOS, or Android.
class RecaptchaRedirectVerifier {
  /// The [FirebaseApp] instance used for verifying reCAPTCHA.
  final FirebaseApp app;

  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<String>? _lastRecaptchaResult;

  /// Creates a [RecaptchaRedirectVerifier] for the given [app].
  RecaptchaRedirectVerifier({required this.app});

  /// Launches the reCAPTCHA verification flow and awaits the result.
  ///
  /// Returns the reCAPTCHA token string upon success.
  Future<String> verify() async {
    var url = FirebaseAppAuthHandler.createAuthHandlerUrl(
      app: app,
      authType: 'verifyApp',
    );

    FirebaseDart.instance.launchUrl(url);

    return getVerifyResult();
  }

  /// Waits for the redirect deep link and extracts the reCAPTCHA token.
  ///
  /// This is called internally by [verify], but may be called separately if needed.
  ///
  /// Throws [UnimplementedError] if called on unsupported platforms.
  Future<String> getVerifyResult() {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await getResult('getVerifyResult');
        _lastRecaptchaResult = null;

        return Uri.parse(v['link']!).queryParameters['recaptchaToken']!;
      });
    } else if (!kIsWeb) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await _deepLinkRetriever.getDeepLinkResult();
        _lastRecaptchaResult = null;

        return v['recaptchaToken']!;
      });
    }
    throw UnimplementedError();
  }
}
