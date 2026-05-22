import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/app_check/app_check_recaptcha.dart';
import 'package:firebase_dart_flutter/src/app_check/play_integrity_attestation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Firebase App Check provider for Flutter.
///
/// Native attestation is tried per platform; reCAPTCHA fallback uses an in-app
/// WebView with the **web** App Check site keys, [recaptchaWebDomain], and
/// [recaptchaWebAppId].
///
/// ```dart
/// await FirebaseAppCheck.instance.activate(
///   provider: FlutterAppCheckProvider(
///     recaptchaV3SiteKey: '...',
///     recaptchaWebDomain: 'my-project.firebaseapp.com',
///     recaptchaWebAppId: '1:123456789:web:abc...',
///     getBuildContext: () => navigatorKey.currentContext,
///   ),
/// );
/// ```
class FlutterAppCheckProvider extends BaseAppCheckProvider {
  static final _logger = Logger('FlutterAppCheckProvider');

  final String? recaptchaV3SiteKey;
  final String? recaptchaEnterpriseSiteKey;

  /// Authorized domain for the reCAPTCHA WebView `baseUrl` (e.g. auth domain).
  final String? recaptchaWebDomain;

  /// Firebase web app id (`1:…:web:…`) for App Check reCAPTCHA token exchange.
  final String? recaptchaWebAppId;

  final bool usePlayIntegrity;
  final bool useDeviceCheck;
  final bool useAppAttest;

  /// Required for reCAPTCHA WebView fallback on mobile and desktop.
  final BuildContext? Function()? getBuildContext;

  final String? debugToken;

  FlutterAppCheckProvider({
    this.recaptchaV3SiteKey,
    this.recaptchaEnterpriseSiteKey,
    this.recaptchaWebDomain,
    this.recaptchaWebAppId,
    this.usePlayIntegrity = true,
    this.useDeviceCheck = true,
    this.useAppAttest = false,
    this.getBuildContext,
    this.debugToken,
  });

  bool get _hasRecaptchaV3 =>
      recaptchaV3SiteKey != null && recaptchaV3SiteKey!.isNotEmpty;

  bool get _hasRecaptchaEnterprise =>
      recaptchaEnterpriseSiteKey != null &&
      recaptchaEnterpriseSiteKey!.isNotEmpty;

  bool get _needsRecaptchaWebViewConfig =>
      !kIsWeb && (_hasRecaptchaV3 || _hasRecaptchaEnterprise);

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    final debug = debugToken;
    if (debug != null && debug.isNotEmpty) {
      return AppCheckAttestation.debug(debug);
    }

    if (kIsWeb) {
      return _recaptchaAttestationOnWeb(app);
    }

    final platform = Platform.current;
    if (platform is AndroidPlatform) {
      return _getWithRecaptchaFallback(app, _androidAttestation);
    }
    if (platform is IOsPlatform || platform is MacOsPlatform) {
      return _getWithRecaptchaFallback(app, _appleAttestation);
    }

    return _recaptchaAttestationWithWebView(app);
  }

  Future<AppCheckAttestation> _getWithRecaptchaFallback(
    FirebaseApp app,
    Future<AppCheckAttestation?> Function(FirebaseApp) attest,
  ) async {
    try {
      final result = await attest(app);
      if (result != null) return result;
    } catch (e, st) {
      _logger.warning(
        'App Check native attestation failed, trying reCAPTCHA WebView.',
        e,
        st,
      );
    }
    return _recaptchaAttestationWithWebView(app);
  }

  Future<AppCheckAttestation?> _androidAttestation(FirebaseApp app) async {
    if (!usePlayIntegrity) return null;
    if (!await isGooglePlayServicesAvailable()) return null;

    final challenge = await generatePlayIntegrityChallenge(app);
    return playIntegrityAttestation(app, challenge: challenge);
  }

  Future<AppCheckAttestation?> _appleAttestation(FirebaseApp app) async {
    if (!useAppAttest && !useDeviceCheck) return null;
    return null;
  }

  Future<AppCheckAttestation> _recaptchaAttestationOnWeb(
      FirebaseApp app) async {
    if (_hasRecaptchaEnterprise) {
      return ReCaptchaEnterpriseProvider(recaptchaEnterpriseSiteKey!)
          .getAttestation(app);
    }
    if (_hasRecaptchaV3) {
      return ReCaptchaV3Provider(recaptchaV3SiteKey!).getAttestation(app);
    }
    throw _missingRecaptchaSiteKeyError();
  }

  Future<AppCheckAttestation> _recaptchaAttestationWithWebView(
      FirebaseApp app) async {
    if (!_hasRecaptchaV3 && !_hasRecaptchaEnterprise) {
      throw _missingRecaptchaSiteKeyError();
    }

    final domain = recaptchaWebDomain;
    final webAppId = recaptchaWebAppId;
    if (_needsRecaptchaWebViewConfig) {
      if (domain == null || domain.isEmpty) {
        throw StateError(
          'App Check: recaptchaWebDomain is required for reCAPTCHA WebView '
          'fallback on native platforms.',
        );
      }
      if (webAppId == null || webAppId.isEmpty) {
        throw StateError(
          'App Check: recaptchaWebAppId (Firebase web app id) is required for '
          'reCAPTCHA WebView fallback on native platforms.',
        );
      }
      final context = getBuildContext?.call();
      if (context == null || !context.mounted) {
        throw StateError(
          'App Check: getBuildContext must return a mounted BuildContext for '
          'reCAPTCHA WebView fallback.',
        );
      }

      if (_hasRecaptchaEnterprise) {
        return appCheckRecaptchaEnterpriseAttestation(
          siteKey: recaptchaEnterpriseSiteKey!,
          recaptchaWebDomain: domain,
          recaptchaWebAppId: webAppId,
          context: context,
        );
      }
      return appCheckRecaptchaV3Attestation(
        siteKey: recaptchaV3SiteKey!,
        recaptchaWebDomain: domain,
        recaptchaWebAppId: webAppId,
        context: context,
      );
    }

    throw StateError('App Check: reCAPTCHA WebView fallback is not available.');
  }

  StateError _missingRecaptchaSiteKeyError() => StateError(
        'App Check: set recaptchaV3SiteKey and/or recaptchaEnterpriseSiteKey on '
        'FlutterAppCheckProvider.',
      );
}
