import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/app_check/app_attest.dart';
import 'package:firebase_dart_flutter/src/app_check/recaptcha.dart';
import 'package:firebase_dart_flutter/src/app_check/device_check.dart';
import 'package:firebase_dart_flutter/src/app_check/play_integrity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Builds ordered [AppCheckProvider]s for Flutter.
///
/// Use [usePlayIntegrity], [useAppAttest], and [useDeviceCheck] to enable native
/// attestation per platform. Set them all to `false` for reCAPTCHA only.
/// [androidRecaptchaEnterpriseSiteKey] and [iosRecaptchaEnterpriseSiteKey] add
/// the native reCAPTCHA Enterprise SDK after device attestation.
/// [webRecaptchaEnterpriseSiteKey] is the web key, used by the web script provider
/// and the WebView fallback. The WebView loads at [FirebaseApp.options.authDomain].
/// [webAppId] is the web app that fallback exchanges as. macOS has no
/// native reCAPTCHA Enterprise SDK.
///
/// ```dart
/// await FirebaseAppCheck.instance.activate(
///   provider: FlutterAppCheckProviders(
///     androidRecaptchaEnterpriseSiteKey: '...',
///     iosRecaptchaEnterpriseSiteKey: '...',
///     webRecaptchaEnterpriseSiteKey: '...',
///     webAppId: '1:123456789:web:abc...',
///     getBuildContext: () => navigatorKey.currentContext,
///   ),
/// );
/// ```
class FlutterAppCheckProviders extends FallbackAppCheckProvider {
  FlutterAppCheckProviders._(super.providers);

  factory FlutterAppCheckProviders({
    String? recaptchaV3SiteKey,
    String? webRecaptchaEnterpriseSiteKey,
    String? androidRecaptchaEnterpriseSiteKey,
    String? iosRecaptchaEnterpriseSiteKey,
    String? webAppId,
    bool usePlayIntegrity = true,
    bool useDeviceCheck = true,
    bool useAppAttest = true,
    BuildContext? Function()? getBuildContext,
  }) {
    if (kIsWeb) {
      return FlutterAppCheckProviders._([
        if (webRecaptchaEnterpriseSiteKey != null)
          ReCaptchaEnterpriseProvider(webRecaptchaEnterpriseSiteKey),
        if (recaptchaV3SiteKey != null) ReCaptchaV3Provider(recaptchaV3SiteKey),
      ]);
    }

    final providers = <AppCheckProvider>[];

    final platform = Platform.current;

    if (platform is AndroidPlatform && usePlayIntegrity) {
      providers.add(const PlayIntegrityAppCheckProvider());
    }

    if (platform is IOsPlatform || platform is MacOsPlatform) {
      if (useAppAttest) {
        providers.add(const AppAttestAppCheckProvider());
      }
      if (useDeviceCheck) {
        providers.add(const DeviceCheckAppCheckProvider());
      }
    }

    final nativeRecaptchaSiteKey = switch (platform) {
      AndroidPlatform() => androidRecaptchaEnterpriseSiteKey,
      IOsPlatform() => iosRecaptchaEnterpriseSiteKey,
      _ => null,
    };
    if (nativeRecaptchaSiteKey != null && nativeRecaptchaSiteKey.isNotEmpty) {
      providers.add(
        RecaptchaEnterpriseNativeAppCheckProvider(nativeRecaptchaSiteKey),
      );
    }

    if (webAppId != null &&
        webAppId.isNotEmpty &&
        getBuildContext != null) {
      providers.addAll([
        if (webRecaptchaEnterpriseSiteKey != null)
          RecaptchaWebViewAppCheckProvider(
            siteKey: webRecaptchaEnterpriseSiteKey,
            webAppId: webAppId,
            getBuildContext: getBuildContext,
            useEnterprise: true,
          ),
        if (recaptchaV3SiteKey != null)
          RecaptchaWebViewAppCheckProvider(
            siteKey: recaptchaV3SiteKey,
            webAppId: webAppId,
            getBuildContext: getBuildContext,
          ),
      ]);
    }

    return FlutterAppCheckProviders._(providers);
  }
}
