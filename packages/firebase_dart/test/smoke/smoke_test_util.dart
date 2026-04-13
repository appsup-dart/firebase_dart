import 'package:_integration_testing/_integration_testing.dart';
import 'package:firebase_dart/core.dart';

/// Public App Check reCAPTCHA v3 site key from generated [FirebaseProjectConfig]
/// for [app].
String webAppCheckRecaptchaV3SiteKeyForApp(FirebaseApp app) {
  final projectId = app.options.projectId;
  for (final c in allConfigs) {
    if (c.projectId != projectId) continue;
    final key = c.webAppCheckRecaptchaV3SiteKey;
    if (key != null && key.isNotEmpty) return key;
    throw StateError(
      'FirebaseProjectConfig for projectId "$projectId" has no '
      'webAppCheckRecaptchaV3SiteKey. Regenerate from packages/_integration_testing '
      'with `dart run tool/generate_firebase_web_config.dart` and ensure '
      'App Check reCAPTCHA v3 is configured with siteSecretSet=true and a '
      'reCAPTCHA key named "Firebase AppCheck".',
    );
  }
  throw StateError(
    'No FirebaseProjectConfig in allConfigs for projectId "$projectId".',
  );
}

/// Public App Check reCAPTCHA Enterprise site key from generated
/// [FirebaseProjectConfig] for [app].
String webAppCheckRecaptchaEnterpriseSiteKeyForApp(FirebaseApp app) {
  final projectId = app.options.projectId;
  for (final c in allConfigs) {
    if (c.projectId != projectId) continue;
    final key = c.webAppCheckRecaptchaEnterpriseSiteKey;
    if (key != null && key.isNotEmpty) return key;
    throw StateError(
      'FirebaseProjectConfig for projectId "$projectId" has no '
      'webAppCheckRecaptchaEnterpriseSiteKey. Regenerate from '
      'packages/_integration_testing with:\n'
      '  dart run tool/generate_firebase_web_config.dart',
    );
  }
  throw StateError(
    'No FirebaseProjectConfig in allConfigs for projectId "$projectId".',
  );
}

/// Returns an existing [FirebaseApp] for the chosen project, or initializes one
/// with [Firebase.initializeApp] using [FirebaseProjectConfig.webConfig].
///
/// When [phoneAuthRecaptchaEnterpriseEnabled] is null, does not filter on
/// filtering on [FirebaseProjectConfig.phoneAuthRecaptchaEnforcement]).
///
/// When it is true, uses the first config with [PhoneAuthRecaptchaEnforcement.enforce]
/// or [PhoneAuthRecaptchaEnforcement.audit]. When false, uses the first config
/// that is neither enforce nor audit.
///
/// The app is always registered under [FirebaseProjectConfig.projectId].
Future<FirebaseApp> getApp({
  bool? phoneAuthRecaptchaEnterpriseEnabled,
  bool? appCheckRecaptchaV3Enabled,
  bool? appCheckRecaptchaEnterpriseEnabled,
}) async {
  if (allConfigs.isEmpty) {
    throw StateError(
      'No Firebase project configs in package:_integration_testing. '
      'From packages/_integration_testing run:\n'
      '  dart run tool/generate_firebase_web_config.dart',
    );
  }

  bool matchesPhoneAuth(FirebaseProjectConfig c) {
    if (phoneAuthRecaptchaEnterpriseEnabled == null) return true;
    final enabled = c.phoneAuthRecaptchaEnforcement ==
            PhoneAuthRecaptchaEnforcement.enforce ||
        c.phoneAuthRecaptchaEnforcement == PhoneAuthRecaptchaEnforcement.audit;
    return phoneAuthRecaptchaEnterpriseEnabled ? enabled : !enabled;
  }

  bool matchesAppCheckV3(FirebaseProjectConfig c) {
    if (appCheckRecaptchaV3Enabled == null) return true;
    final enabled = (c.webAppCheckRecaptchaV3SiteKey ?? '').isNotEmpty;
    return appCheckRecaptchaV3Enabled ? enabled : !enabled;
  }

  bool matchesAppCheckEnterprise(FirebaseProjectConfig c) {
    if (appCheckRecaptchaEnterpriseEnabled == null) return true;
    final enabled =
        (c.webAppCheckRecaptchaEnterpriseSiteKey ?? '').isNotEmpty;
    return appCheckRecaptchaEnterpriseEnabled ? enabled : !enabled;
  }

  final config = allConfigs.firstWhere(
    (c) =>
        matchesPhoneAuth(c) &&
        matchesAppCheckV3(c) &&
        matchesAppCheckEnterprise(c),
    orElse: () => throw StateError(
      'No FirebaseProjectConfig in allConfigs matching filters: '
      'phoneAuthRecaptchaEnterpriseEnabled=$phoneAuthRecaptchaEnterpriseEnabled, '
      'appCheckRecaptchaV3Enabled=$appCheckRecaptchaV3Enabled, '
      'appCheckRecaptchaEnterpriseEnabled=$appCheckRecaptchaEnterpriseEnabled.',
    ),
  );

  FirebaseApp? matchByName;
  for (final a in Firebase.apps) {
    if (a.name == config.projectId) {
      matchByName = a;
      break;
    }
  }
  if (matchByName != null) {
    return matchByName;
  }
  FirebaseApp? matchByProjectId;
  for (final a in Firebase.apps) {
    if (a.options.projectId == config.projectId) {
      matchByProjectId = a;
      break;
    }
  }
  return matchByProjectId ??
      await Firebase.initializeApp(
        name: config.projectId,
        options: config.webConfig,
      );
}
