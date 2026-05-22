import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_webview.dart';
import 'package:flutter/material.dart';

/// App Check reCAPTCHA action for Enterprise (matches Firebase SDK).
const appCheckRecaptchaEnterpriseAction = 'fire_app_check';

/// reCAPTCHA App Check via in-app WebView (native fallback using web app id).
class RecaptchaWebViewAppCheckProvider implements AppCheckProvider {
  RecaptchaWebViewAppCheckProvider({
    required this.siteKey,
    required this.recaptchaWebDomain,
    required this.recaptchaWebAppId,
    required this.getBuildContext,
    this.useEnterprise = false,
  });

  final String siteKey;
  final String recaptchaWebDomain;
  final String recaptchaWebAppId;
  final BuildContext? Function() getBuildContext;
  final bool useEnterprise;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (siteKey.isEmpty) {
      throw StateError('App Check: reCAPTCHA site key is required');
    }
    if (recaptchaWebDomain.isEmpty) {
      throw StateError(
        'App Check: recaptchaWebDomain is required for reCAPTCHA WebView.',
      );
    }
    if (recaptchaWebAppId.isEmpty) {
      throw StateError(
        'App Check: recaptchaWebAppId (Firebase web app id) is required for '
        'reCAPTCHA WebView.',
      );
    }
    final context = getBuildContext();
    if (context == null || !context.mounted) {
      throw StateError(
        'App Check: getBuildContext must return a mounted BuildContext for '
        'reCAPTCHA WebView.',
      );
    }

    final token = await RecaptchaWebViewVerifier(
      context: context,
      action: useEnterprise ? appCheckRecaptchaEnterpriseAction : null,
      baseUrl: _recaptchaBaseUrl(recaptchaWebDomain),
      siteKey: siteKey,
    ).verify();

    if (useEnterprise) {
      return AppCheckAttestation.recaptchaEnterprise(
        token,
        webAppId: recaptchaWebAppId,
      );
    }
    return AppCheckAttestation.recaptchaV3(
      token,
      webAppId: recaptchaWebAppId,
    );
  }

  static String _recaptchaBaseUrl(String recaptchaWebDomain) {
    if (recaptchaWebDomain.contains('://')) return recaptchaWebDomain;
    return 'http://$recaptchaWebDomain';
  }
}
