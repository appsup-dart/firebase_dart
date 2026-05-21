@Tags(['smoke'])
library;

import 'dart:io';

import 'package:_integration_testing/_integration_testing.dart';
import 'package:collection/collection.dart';
import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jose/jose.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseDartFlutter.setup(isolated: false);
  });

  group('AndroidPlayIntegrityProvider', () {
    test('activate then getToken returns a Play Integrity JWT', () async {
      if (Platform.current is! AndroidPlatform) {
        markTestSkipped('Play Integrity App Check requires Android');
        return;
      }
      await _requireAppCheckApiReachable();

      final app = await getApp();
      final appCheck = FirebaseAppCheck.instanceFor(app: app);

      await appCheck.activate(
        provider: AndroidAppCheckProvider.playIntegrity,
      );

      final token = await appCheck.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      final jwt = await JsonWebToken.decodeAndVerify(
        token!,
        JsonWebKeyStore()
          ..addKeySetUrl(
            Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks'),
          ),
      );

      expect(jwt.claims.subject, app.options.appId);
      expect(
        jwt.claims.audience,
        contains('projects/${app.options.projectId}'),
      );
      expect(jwt.claims['provider'], 'play_integrity');
    });
  });

  group('FlutterAppCheckProvider', () {
    test('uses Play Integrity on Android when provider is enabled', () async {
      if (Platform.current is! AndroidPlatform) {
        markTestSkipped('Play Integrity App Check requires Android');
        return;
      }
      await _requireAppCheckApiReachable();

      final app = await getApp(appCheckRecaptchaV3: true);
      final siteKey = webAppCheckRecaptchaV3SiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);

      await appCheck.activate(
        provider: FlutterAppCheckProvider(
          recaptcha: RecaptchaAppCheckProvider.v3(siteKey),
        ),
      );

      final token = await appCheck.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      final jwt = await JsonWebToken.decodeAndVerify(
        token!,
        JsonWebKeyStore()
          ..addKeySetUrl(
            Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks'),
          ),
      );

      expect(jwt.claims['provider'], 'play_integrity');
    });
  });
}

/// First generated project with an Android app in the integration configs.
Future<FirebaseApp> getApp({bool appCheckRecaptchaV3 = false}) async {
  const bundleId = 'be.appsup.firebase-dart-flutter-example';

  final project = allConfigs.firstWhere(
    (p) {
      if (p.androidConfigs.isEmpty) return false;
      if (!appCheckRecaptchaV3) return true;
      return (p.webAppCheckRecaptchaV3SiteKey ?? '').isNotEmpty;
    },
    orElse: () => throw StateError(
      'No FirebaseProjectConfig with Android'
      '${appCheckRecaptchaV3 ? ' and App Check reCAPTCHA v3' : ''}. '
      'Regenerate configs: dart run tool/generate_firebase_web_config.dart',
    ),
  );

  var app = Firebase.apps
      .firstWhereOrNull((v) => v.options.projectId == project.projectId);

  app ??= await Firebase.initializeApp(
    options: switch (Platform.current) {
      AndroidPlatform(:final packageId) => project.androidConfigs[packageId] ??
          project.androidConfigs[bundleId] ??
          project.androidConfigs.values.first,
      IOsPlatform() ||
      MacOsPlatform() =>
        project.iosConfigs[bundleId] ?? project.iosConfigs.values.first,
      WebPlatform() => project.webConfig,
      _ => project.webConfig,
    },
    name: project.projectId,
  );

  return app;
}

/// App Check Play Integrity needs HTTPS to [firebaseAppCheckApiHost] for the
/// challenge (unlike auth Play Integrity in [verifiers_test], which only uses
/// the on-device Play Integrity API).
const firebaseAppCheckApiHost = 'firebaseappcheck.googleapis.com';

Future<void> _requireAppCheckApiReachable() async {
  try {
    final addresses = await InternetAddress.lookup(firebaseAppCheckApiHost);
    if (addresses.isEmpty) {
      markTestSkipped(
        'DNS returned no addresses for $firebaseAppCheckApiHost. '
        'Check device internet, Private DNS, or VPN.',
      );
    }
  } on SocketException catch (e) {
    markTestSkipped(
      'Cannot resolve $firebaseAppCheckApiHost (${e.message}). '
      'The device needs working DNS/internet to call generatePlayIntegrityChallenge. '
      'Auth Play Integrity tests in verifiers_test.dart do not use this host.',
    );
  }
}

String webAppCheckRecaptchaV3SiteKeyForApp(FirebaseApp app) {
  final projectId = app.options.projectId;
  for (final c in allConfigs) {
    if (c.projectId != projectId) continue;
    final key = c.webAppCheckRecaptchaV3SiteKey;
    if (key != null && key.isNotEmpty) return key;
    throw StateError(
      'No webAppCheckRecaptchaV3SiteKey for projectId "$projectId".',
    );
  }
  throw StateError('No FirebaseProjectConfig for projectId "$projectId".');
}
