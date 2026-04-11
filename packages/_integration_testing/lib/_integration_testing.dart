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

  const FirebaseProjectConfig({
    required this.projectId,
    required this.webConfig,
    required this.iosConfigs,
    required this.androidConfigs,
    this.iosBundleIdsWithApnsConfigured = const [],
    this.phoneAuthRecaptchaEnforcement = PhoneAuthRecaptchaEnforcement.unknown,
  });
}
