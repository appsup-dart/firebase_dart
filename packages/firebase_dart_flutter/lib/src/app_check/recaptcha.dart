import 'dart:async';

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_native.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_webview.dart';
import 'package:flutter/material.dart';

/// App Check reCAPTCHA action for Enterprise (matches Firebase SDK).
const appCheckRecaptchaEnterpriseAction = 'fire_app_check';

/// reCAPTCHA Enterprise App Check via the native Android or iOS SDK.
///
/// [siteKey] is the platform key from Firebase Console → App Check, not the
/// web key. The token is exchanged as [FirebaseApp.options.appId].
class RecaptchaEnterpriseNativeAppCheckProvider
    extends AttestingAppCheckProvider {
  RecaptchaEnterpriseNativeAppCheckProvider(this.siteKey);

  final String siteKey;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (siteKey.isEmpty) {
      throw StateError(
        'App Check: reCAPTCHA Enterprise site key is required',
      );
    }
    final token = await RecaptchaEnterpriseNativeVerifier(
      siteKey: siteKey,
      action: appCheckRecaptchaEnterpriseAction,
    ).verify();
    return AppCheckAttestation.recaptchaEnterprise(token);
  }
}

/// reCAPTCHA App Check via in-app WebView.
///
/// The page origin is [FirebaseApp.options.authDomain], same as phone-auth
/// reCAPTCHA. [webAppId] is the web app the token is exchanged as;
/// a mobile [FirebaseApp] does not know that id.
class RecaptchaWebViewAppCheckProvider extends AttestingAppCheckProvider {
  RecaptchaWebViewAppCheckProvider({
    required this.siteKey,
    required this.webAppId,
    required this.getBuildContext,
    this.useEnterprise = false,
  });

  final String siteKey;
  final String webAppId;
  final BuildContext? Function() getBuildContext;
  final bool useEnterprise;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (siteKey.isEmpty) {
      throw StateError('App Check: reCAPTCHA site key is required');
    }
    if (webAppId.isEmpty) {
      throw StateError(
        'App Check: web app id is required for reCAPTCHA WebView.',
      );
    }
    final context = getBuildContext();
    if (context == null || !context.mounted) {
      // The widget tree is not up yet. A timeout is retried by App Check
      // instead of failing the provider for good.
      throw TimeoutException(
        'App Check: reCAPTCHA WebView context is not ready',
      );
    }

    final String token;
    try {
      token = await RecaptchaWebViewVerifier(
        context: context,
        action: useEnterprise ? appCheckRecaptchaEnterpriseAction : null,
        baseUrl: 'http://${app.options.authDomain ?? '127.0.0.1:8080'}',
        siteKey: siteKey,
      ).verify();
    } on Exception catch (error) {
      if (error.toString().contains('No overlay found')) {
        throw TimeoutException(
          'App Check: reCAPTCHA WebView overlay is not ready',
        );
      }
      rethrow;
    }

    if (useEnterprise) {
      return AppCheckAttestation.recaptchaEnterprise(
        token,
        webAppId: webAppId,
      );
    }
    return AppCheckAttestation.recaptchaV3(
      token,
      webAppId: webAppId,
    );
  }
}
