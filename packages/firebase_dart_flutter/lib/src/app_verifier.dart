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

class FlutterApplicationVerifier extends BaseApplicationVerifier {
  final bool usePlayIntegrity;

  final bool useApns;

  final bool useRecaptchaEnterpriseNative;

  final BuildContext? Function()? getBuildContext;

  static final Logger _logger = Logger('FlutterApplicationVerifier');

  FlutterApplicationVerifier(
      {this.usePlayIntegrity = true,
      this.useApns = true,
      this.useRecaptchaEnterpriseNative = true,
      this.getBuildContext});

  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {bool forceRecaptcha = false,
      required String action,
      required String nonce}) async {
    if (kIsWeb) {
      return const RecaptchaApplicationVerifier().verify(auth,
          nonce: nonce, action: action, forceRecaptcha: forceRecaptcha);
    }

    if (await isRecaptchaEnterpriseEnabledForAction(auth, action)) {
      return ApplicationVerificationResult.recaptchaEnterprise(
          await _verifyWithRecaptchaEnterprise(auth, action));
    }

    if (!forceRecaptcha) {
      var p = Platform.current;
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
      } else if (p is AndroidPlatform) {
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
    var v = await _verifyWithRecaptcha(auth);
    return ApplicationVerificationResult.recaptcha(v);
  }

  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  Future<String?> _verifyWithApns(FirebaseAuth auth) async {
    if (!useApns) return null;
    return await ApnsVerifier(
            iosClientVerifier: (appToken, isSandbox) =>
                verifyIosClient(auth, appToken: appToken, isSandbox: isSandbox))
        .verify();
  }

  Future<String?> _verifyWithPlayIntegrity(
      FirebaseAuth auth, String nonce) async {
    if (!usePlayIntegrity) return null;
    var available = await _isGooglePlayServicesAvailable;
    if (!available) return null;

    return await PlayIntegrityVerifier(
            projectNumber: await getProducerProjectNumber(auth), nonce: nonce)
        .verify();
  }

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
