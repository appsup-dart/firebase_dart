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
/// attestation per platform. Set them all to `false` for reCAPTCHA WebView only.
/// On web, reCAPTCHA v3 / Enterprise providers are used when site keys are set.
///
/// ```dart
/// await FirebaseAppCheck.instance.activate(
///   providers: FlutterAppCheckProviders(
///     recaptchaV3SiteKey: '...',
///     recaptchaWebDomain: 'my-project.firebaseapp.com',
///     recaptchaWebAppId: '1:123456789:web:abc...',
///     getBuildContext: () => navigatorKey.currentContext,
///   ),
/// );
/// ```
class FlutterAppCheckProviders extends AppCheckProviders {
  FlutterAppCheckProviders._(super.providers);

  factory FlutterAppCheckProviders({
    String? recaptchaV3SiteKey,
    String? recaptchaEnterpriseSiteKey,
    String? recaptchaWebDomain,
    String? recaptchaWebAppId,
    bool usePlayIntegrity = true,
    bool useDeviceCheck = true,
    bool useAppAttest = true,
    BuildContext? Function()? getBuildContext,
  }) {
    if (kIsWeb) {
      return FlutterAppCheckProviders._([
        if (recaptchaEnterpriseSiteKey != null)
          ReCaptchaEnterpriseProvider(recaptchaEnterpriseSiteKey),
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

    if (recaptchaWebDomain != null &&
        recaptchaWebDomain.isNotEmpty &&
        recaptchaWebAppId != null &&
        recaptchaWebAppId.isNotEmpty &&
        getBuildContext != null) {
      providers.addAll([
        if (recaptchaEnterpriseSiteKey != null)
          RecaptchaWebViewAppCheckProvider(
            siteKey: recaptchaEnterpriseSiteKey,
            recaptchaWebDomain: recaptchaWebDomain,
            recaptchaWebAppId: recaptchaWebAppId,
            getBuildContext: getBuildContext,
            useEnterprise: true,
          ),
        if (recaptchaV3SiteKey != null)
          RecaptchaWebViewAppCheckProvider(
            siteKey: recaptchaV3SiteKey,
            recaptchaWebDomain: recaptchaWebDomain,
            recaptchaWebAppId: recaptchaWebAppId,
            getBuildContext: getBuildContext,
          ),
      ]);
    }

    return FlutterAppCheckProviders._(providers);
  }
}
