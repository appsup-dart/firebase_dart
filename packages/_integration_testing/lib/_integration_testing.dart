/// Helpers for integration/smoke testing in this workspace.
library;

import 'package:firebase_dart/core.dart';

export '_generated/all.dart';

/// reCAPTCHA Enterprise phone enforcement from Identity Toolkit admin config
/// (`projects/{id}/config` → `recaptchaConfig.phoneEnforcementState`).
enum PhoneAuthRecaptchaEnforcement {
  unspecified,
  off,
  audit,
  enforce,

  /// No `PHONE_PROVIDER` entry, empty response, or the generator could not
  /// call the admin API.
  unknown,
}

class FirebaseProjectConfig {
  final String projectId;

  final FirebaseOptions webConfig;

  final Map<String, FirebaseOptions> iosConfigs;

  final Map<String, FirebaseOptions> androidConfigs;

  /// iOS bundle IDs for which Firebase has an APNs auth key
  final List<String> iosBundleIdsWithApnsConfigured;

  /// reCAPTCHA Enterprise enforcement for phone/SMS flows (`phoneEnforcementState`
  /// in Identity Toolkit project config).
  final PhoneAuthRecaptchaEnforcement phoneAuthRecaptchaEnforcement;

  /// reCAPTCHA v3 key for App Check web flows.
  ///
  /// Filled only when both are true:
  /// - App Check `recaptchaV3Config.siteSecretSet` is true, and
  /// - a reCAPTCHA web key named `Firebase AppCheck` exists.
  final String? webAppCheckRecaptchaV3SiteKey;

  /// reCAPTCHA Enterprise key for App Check web flows
  /// (`recaptchaEnterpriseConfig.siteKey`).
  final String? webAppCheckRecaptchaEnterpriseSiteKey;

  /// Backward compatibility for previously generated files.
  ///
  /// Prefer [webAppCheckRecaptchaV3SiteKey] and
  /// [webAppCheckRecaptchaEnterpriseSiteKey].
  @Deprecated('Use webAppCheckRecaptchaV3SiteKey / Enterprise counterpart')
  final String? webAppCheckRecaptchaSiteKey;

  const FirebaseProjectConfig({
    required this.projectId,
    required this.webConfig,
    required this.iosConfigs,
    required this.androidConfigs,
    this.iosBundleIdsWithApnsConfigured = const [],
    this.phoneAuthRecaptchaEnforcement = PhoneAuthRecaptchaEnforcement.unknown,
    this.webAppCheckRecaptchaV3SiteKey,
    this.webAppCheckRecaptchaEnterpriseSiteKey,
    this.webAppCheckRecaptchaSiteKey,
  });
}
