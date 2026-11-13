import 'package:_integration_testing/_integration_testing.dart';
import 'package:firebase_dart/app_check.dart';
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

/// Registered App Check debug secret from generated [FirebaseProjectConfig]
/// for [app].
String webAppCheckDebugTokenForApp(FirebaseApp app) {
  final projectId = app.options.projectId;
  for (final c in allConfigs) {
    if (c.projectId != projectId) continue;
    final token = c.webAppCheckDebugToken;
    if (token != null && token.isNotEmpty) return token;
    throw StateError(
      'FirebaseProjectConfig for projectId "$projectId" has no '
      'webAppCheckDebugToken. Regenerate from packages/_integration_testing '
      'with `dart run tool/generate_firebase_web_config.dart` (requires App '
      'Check Admin API access to register a debug token).',
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

/// Activates App Check for service smoke tests (prefers debug, else Enterprise).
Future<void> activateAppCheckForSmoke(FirebaseApp app) async {
  final appCheck = FirebaseAppCheck.instanceFor(app: app);
  final projectId = app.options.projectId;
  for (final c in allConfigs) {
    if (c.projectId != projectId) continue;
    final debug = c.webAppCheckDebugToken;
    if (debug != null && debug.isNotEmpty) {
      await appCheck.activate(
        provider: AppCheckProvider.debug(debugToken: debug),
      );
      return;
    }
    final enterprise = c.webAppCheckRecaptchaEnterpriseSiteKey;
    if (enterprise != null && enterprise.isNotEmpty) {
      await appCheck.activate(
        provider: AppCheckProvider.recaptchaEnterprise(enterprise),
      );
      return;
    }
    final v3 = c.webAppCheckRecaptchaV3SiteKey;
    if (v3 != null && v3.isNotEmpty) {
      await appCheck.activate(provider: AppCheckProvider.recaptchaV3(v3));
      return;
    }
    break;
  }
  throw StateError(
    'FirebaseProjectConfig for projectId "$projectId" has no App Check keys. '
    'Regenerate from packages/_integration_testing with:\n'
    '  dart run tool/generate_firebase_web_config.dart',
  );
}

/// True when [config] has any App Check provider config for smoke service tests.
bool hasAppCheckForServiceSmoke(FirebaseProjectConfig config) {
  if ((config.webAppCheckDebugToken ?? '').isNotEmpty) return true;
  if ((config.webAppCheckRecaptchaEnterpriseSiteKey ?? '').isNotEmpty) {
    return true;
  }
  return (config.webAppCheckRecaptchaV3SiteKey ?? '').isNotEmpty;
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
  bool? appCheckDebugEnabled,
  bool? appCheckForServiceSmoke,
  String? projectId,
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
    final enabled = (c.webAppCheckRecaptchaEnterpriseSiteKey ?? '').isNotEmpty;
    return appCheckRecaptchaEnterpriseEnabled ? enabled : !enabled;
  }

  bool matchesAppCheckDebug(FirebaseProjectConfig c) {
    if (appCheckDebugEnabled == null) return true;
    final enabled = (c.webAppCheckDebugToken ?? '').isNotEmpty;
    return appCheckDebugEnabled ? enabled : !enabled;
  }

  bool matchesAppCheckForServiceSmoke(FirebaseProjectConfig c) {
    if (appCheckForServiceSmoke == null) return true;
    final enabled = hasAppCheckForServiceSmoke(c);
    return appCheckForServiceSmoke ? enabled : !enabled;
  }

  bool matchesProjectId(FirebaseProjectConfig c) {
    if (projectId == null) return true;
    return c.projectId == projectId;
  }

  final config = allConfigs.firstWhere(
    (c) =>
        matchesPhoneAuth(c) &&
        matchesAppCheckV3(c) &&
        matchesAppCheckEnterprise(c) &&
        matchesAppCheckDebug(c) &&
        matchesAppCheckForServiceSmoke(c) &&
        matchesProjectId(c),
    orElse: () => throw StateError(
      'No FirebaseProjectConfig in allConfigs matching filters: '
      'phoneAuthRecaptchaEnterpriseEnabled=$phoneAuthRecaptchaEnterpriseEnabled, '
      'appCheckRecaptchaV3Enabled=$appCheckRecaptchaV3Enabled, '
      'appCheckRecaptchaEnterpriseEnabled=$appCheckRecaptchaEnterpriseEnabled, '
      'appCheckDebugEnabled=$appCheckDebugEnabled, '
      'appCheckForServiceSmoke=$appCheckForServiceSmoke, '
      'projectId=$projectId.',
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
