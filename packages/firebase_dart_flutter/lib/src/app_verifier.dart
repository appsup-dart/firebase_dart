import 'dart:async';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/verifiers/apns.dart';
import 'package:firebase_dart_flutter/src/verifiers/play_integrity.dart';
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

  final BuildContext? Function()? getBuildContext;

  FlutterApplicationVerifier(
      {this.usePlayIntegrity = true,
      this.useApns = true,
      this.getBuildContext});

  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false}) async {
    if (kIsWeb) {
      return const RecaptchaApplicationVerifier()
          .verify(auth, nonce, forceRecaptcha: forceRecaptcha);
    }

    if (!forceRecaptcha) {
      var p = Platform.current;
      if (p is IOsPlatform || p is MacOsPlatform) {
        try {
          var v = await verifyWithApns(auth);
          if (v != null) return ApplicationVerificationResult.apns(v);
        } catch (e, tr) {
          Logger('FirebaseAuth').warning(
              'Failed to verify application with APNS, will try recaptcha instead.',
              e,
              tr);
        }
      } else if (p is AndroidPlatform) {
        try {
          var v = await verifyWithPlayIntegrity(auth, nonce);
          if (v != null) return ApplicationVerificationResult.playItegrity(v);
        } catch (e, tr) {
          Logger('FirebaseAuth').warning(
              'Failed to verify application with Play Integrity, will try recaptcha instead.',
              e,
              tr);
        }
      }
    }
    var v = await verifyWithRecaptcha(auth);
    return ApplicationVerificationResult.recaptcha(v);
  }

  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  Future<String?> verifyWithApns(FirebaseAuth auth) async {
    if (!useApns) return null;
    return await ApnsVerifier(
            iosClientVerifier: (appToken, isSandbox) =>
                verifyIosClient(auth, appToken: appToken, isSandbox: isSandbox))
        .verify();
  }

  Future<String?> verifyWithPlayIntegrity(
      FirebaseAuth auth, String nonce) async {
    if (!usePlayIntegrity) return null;
    var available = await _isGooglePlayServicesAvailable;
    if (!available) return null;

    return await PlayIntegrityVerifier(
            projectNumber: await getProducerProjectNumber(auth), nonce: nonce)
        .verify();
  }

  Future<String> verifyWithRecaptcha(FirebaseAuth auth) async {
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
}
