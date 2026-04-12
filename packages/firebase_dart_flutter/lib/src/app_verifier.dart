import 'dart:async';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/verifiers/apns.dart';
import 'package:firebase_dart_flutter/src/verifiers/play_integrity.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_native.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_redirect.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:platform_info/platform_info.dart' as platform_info;

import 'channel.dart';

/// Firebase Application Verifier for Flutter platform.
///
/// This class implements automatic application verification for [FirebaseAuth]
/// on Flutter through various mechanisms, including:
///  - APNs (iOS/macOS)
///  - Google Play Integrity (Android)
///  - reCAPTCHA (WebView or browser fallback)
///  - reCAPTCHA Enterprise (native or WebView fallback)
///
/// Use this class as [applicationVerifier] for [FirebaseDartFlutter.setup].
///
/// Various strategies are picked depending on availability, platform, and
/// constructor preferences. The order of fallback is:
///   1. If reCAPTCHA Enterprise is enabled, use it (native or WebView fallback)
///   2. (iOS/macOS): use APNs if enabled; fallback to reCAPTCHA.
///   3. (Android): use Play Integrity if enabled and available; fallback to reCAPTCHA.
///   4. reCAPTCHA via WebView, or browser redirect as a last resort.
///   5. On web, always uses [RecaptchaApplicationVerifier].
///
/// Several constructor flags control this behavior:
///   - [usePlayIntegrity]: enable Play Integrity check on Android.
///   - [useApns]: enable APNs check on iOS/macOS.
///   - [useRecaptchaEnterpriseNative]: enable native reCAPTCHA Enterprise verification on native platforms (Android/iOS).
///   - [getBuildContext]: callback to provide [BuildContext] for inserting overlays (reCAPTCHA WebView verification).
class FlutterApplicationVerifier extends BaseApplicationVerifier {
  /// If true, use Play Integrity for Android verification (if available).
  final bool usePlayIntegrity;

  /// If true, use APNs for iOS/macOS device verification (if available).
  final bool useApns;

  /// If true, use the native Recaptcha Enterprise SDK on Android/iOS.
  final bool useRecaptchaEnterpriseNative;

  /// Callback to obtain the [BuildContext] for inserting overlay widgets.
  /// If null or returns null, WebView verification will be skipped and
  /// fallback to browser-based reCAPTCHA will be used.
  final BuildContext? Function()? getBuildContext;

  static final Logger _logger = Logger('FlutterApplicationVerifier');

  /// Constructs a [FlutterApplicationVerifier].
  ///
  /// [usePlayIntegrity] enables Play Integrity check for Android.
  /// [useApns] enables APNs check for iOS/macOS.
  /// [useRecaptchaEnterpriseNative] enables native reCAPTCHA Enterprise on mobile.
  /// [getBuildContext] provides the [BuildContext] for overlays.
  FlutterApplicationVerifier(
      {this.usePlayIntegrity = true,
      this.useApns = true,
      this.useRecaptchaEnterpriseNative = true,
      this.getBuildContext});

  /// Attempts to verify the application for Firebase AppCheck.
  ///
  /// [auth]: Firebase authentication instance.
  /// [forceRecaptcha]: If true, skips native verifiers and uses reCAPTCHA.
  /// [action]: The AppCheck action/purpose, used for Recaptcha Enterprise.
  /// [nonce]: Random value to distinguish the request and prevent replay.
  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {bool forceRecaptcha = false,
      required String action,
      required String nonce}) async {
    // On web, always use RecaptchaApplicationVerifier.
    if (kIsWeb) {
      return const RecaptchaApplicationVerifier().verify(auth,
          nonce: nonce, action: action, forceRecaptcha: forceRecaptcha);
    }

    // Use Recaptcha Enterprise if enabled for this action.
    if (await isRecaptchaEnterpriseEnabledForAction(auth, action)) {
      return ApplicationVerificationResult.recaptchaEnterprise(
          await _verifyWithRecaptchaEnterprise(auth, action));
    }

    if (!forceRecaptcha) {
      var p = Platform.current;
      // iOS/macOS: try APNs, fallback to reCAPTCHA.
      if (p is IOsPlatform || p is MacOsPlatform) {
        try {
          var v = await _verifyWithApns(auth);
          if (v != null) return ApplicationVerificationResult.apns(v);
        } catch (e, tr) {
          _logger.warning(
              'Failed to verify application with APNS, will try recaptcha instead.',
              e,
              tr);
        }
      }
      // Android: try Play Integrity, fallback to reCAPTCHA.
      else if (p is AndroidPlatform) {
        try {
          var v = await _verifyWithPlayIntegrity(auth, nonce);
          if (v != null) return ApplicationVerificationResult.playItegrity(v);
        } catch (e, tr) {
          _logger.warning(
              'Failed to verify application with Play Integrity, will try recaptcha instead.',
              e,
              tr);
        }
      }
    }
    // Fallback: verify with reCAPTCHA (in-app WebView or redirect).
    var v = await _verifyWithRecaptcha(auth);
    return ApplicationVerificationResult.recaptcha(v);
  }

  /// Whether Google Play Services is available on current device (Android).
  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  /// Performs APNs verification for iOS/macOS using device token.
  Future<String?> _verifyWithApns(FirebaseAuth auth) async {
    if (!useApns) return null;
    return await ApnsVerifier(
            iosClientVerifier: (appToken, isSandbox) =>
                verifyIosClient(auth, appToken: appToken, isSandbox: isSandbox))
        .verify();
  }

  /// Performs Play Integrity verification for Android.
  Future<String?> _verifyWithPlayIntegrity(
      FirebaseAuth auth, String nonce) async {
    if (!usePlayIntegrity) return null;
    var available = await _isGooglePlayServicesAvailable;
    if (!available) return null;

    return await PlayIntegrityVerifier(
            projectNumber: await getProducerProjectNumber(auth), nonce: nonce)
        .verify();
  }

  /// Performs reCAPTCHA verification via WebView overlay or browser redirect.
  Future<String> _verifyWithRecaptcha(FirebaseAuth auth) async {
    if (getBuildContext != null) {
      var context = getBuildContext!();
      if (context != null) {
        var siteKey = await getRecaptchaSiteKey(auth);

        if (context.mounted) {
          return RecaptchaWebViewVerifier(
                  context: context,
                  baseUrl:
                      'http://${auth.app.options.authDomain ?? '127.0.0.1:8080'}',
                  siteKey: siteKey)
              .verify();
        }
      }
    }
    return RecaptchaRedirectVerifier(app: auth.app).verify();
  }

  /// Performs Recaptcha Enterprise verification, optionally using native SDK.
  ///
  /// Will fallback to in-app WebView or browser-based verification if native
  /// Recaptcha Enterprise is not supported/available or fails.
  Future<String> _verifyWithRecaptchaEnterprise(
      FirebaseAuth auth, String action) async {
    if (useRecaptchaEnterpriseNative &&
        (Platform.current is AndroidPlatform ||
            Platform.current is IOsPlatform)) {
      try {
        var token = await RecaptchaEnterpriseNativeVerifier(
                siteKey: await getRecaptchaEnterpriseSiteKey(auth),
                action: action)
            .verify();
        var clientType = switch (Platform.current) {
          AndroidPlatform() => 'CLIENT_TYPE_ANDROID',
          IOsPlatform() => 'CLIENT_TYPE_IOS',
          _ => 'CLIENT_TYPE_WEB',
        };
        return '$clientType:$token';
      } catch (e, tr) {
        _logger.warning(
            'Failed to verify application with Recaptcha Enterprise native verifier, will try recaptcha webview instead.',
            e,
            tr);
      }
    }
    if (getBuildContext != null) {
      var context = getBuildContext!();
      if (context != null) {
        var siteKey =
            await getRecaptchaEnterpriseSiteKey(auth, useNativeVerifier: false);

        if (context.mounted) {
          var token = await RecaptchaWebViewVerifier(
                  context: context,
                  action: action,
                  baseUrl:
                      'http://${auth.app.options.authDomain ?? '127.0.0.1:8080'}',
                  siteKey: siteKey)
              .verify();
          return 'CLIENT_TYPE_WEB:$token';
        }
      }
    }
    var token = await RecaptchaRedirectVerifier(app: auth.app).verify();
    return 'CLIENT_TYPE_WEB:$token';
  }
}
