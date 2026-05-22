import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_webview.dart';
import 'package:flutter/material.dart';

/// App Check reCAPTCHA action for Enterprise (matches Firebase SDK).
const appCheckRecaptchaEnterpriseAction = 'fire_app_check';

/// Base URL for the reCAPTCHA WebView from an authorized domain hostname.
String appCheckRecaptchaBaseUrl(String recaptchaWebDomain) {
  if (recaptchaWebDomain.contains('://')) return recaptchaWebDomain;
  return 'http://$recaptchaWebDomain';
}

/// reCAPTCHA v3 attestation via in-app WebView (mobile/desktop fallback).
Future<AppCheckAttestation> appCheckRecaptchaV3Attestation({
  required String siteKey,
  required String recaptchaWebDomain,
  required String recaptchaWebAppId,
  required BuildContext context,
}) async {
  final token = await RecaptchaWebViewVerifier(
    context: context,
    baseUrl: appCheckRecaptchaBaseUrl(recaptchaWebDomain),
    siteKey: siteKey,
  ).verify();
  return AppCheckAttestation.recaptchaV3(
    token,
    webAppId: recaptchaWebAppId,
  );
}

/// reCAPTCHA Enterprise attestation via in-app WebView (mobile/desktop fallback).
Future<AppCheckAttestation> appCheckRecaptchaEnterpriseAttestation({
  required String siteKey,
  required String recaptchaWebDomain,
  required String recaptchaWebAppId,
  required BuildContext context,
}) async {
  final token = await RecaptchaWebViewVerifier(
    context: context,
    action: appCheckRecaptchaEnterpriseAction,
    baseUrl: appCheckRecaptchaBaseUrl(recaptchaWebDomain),
    siteKey: siteKey,
  ).verify();
  return AppCheckAttestation.recaptchaEnterprise(
    token,
    webAppId: recaptchaWebAppId,
  );
}
