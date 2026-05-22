@Tags(['smoke'])
library;

import 'package:_integration_testing/_integration_testing.dart';
import 'package:collection/collection.dart';
import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:firebase_dart_flutter/src/app_check/device_check_attestation.dart'
    show isDeviceCheckSupported;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jose/jose.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseDartFlutter.setup(isolated: false);
  });

  group('FlutterAppCheckProvider', () {
    group('Play Integrity', () {
      test('activate then getToken returns a Play Integrity JWT', () async {
        if (Platform.current is! AndroidPlatform) {
          markTestSkipped('Play Integrity App Check requires Android');
          return;
        }

        final app = await getApp();
        final appCheck = FirebaseAppCheck.instanceFor(app: app);

        await appCheck.activate(
          provider: FlutterAppCheckProvider(),
        );

        final token = await appCheck.getToken();
        expect(token, isNotNull);
        expect(token, isNotEmpty);

        final jwt = await _decodeAppCheckJwt(token!);
        expect(jwt.claims.subject, app.options.appId);
        expect(
          jwt.claims.audience,
          contains('projects/${app.options.projectId}'),
        );
        expect(jwt.claims['provider'], 'play_integrity');
      });
    });

    group('Device Check', () {
      test('activate then getToken returns a Device Check JWT', () async {
        if (Platform.current is! IOsPlatform &&
            Platform.current is! MacOsPlatform) {
          markTestSkipped('Device Check App Check requires iOS or macOS');
          return;
        }
        if (!await isDeviceCheckSupported()) {
          markTestSkipped(
            'Device Check is not supported on this device '
            '(use a physical iPhone or Mac).',
          );
          return;
        }

        final app = await getApp();
        final appCheck = FirebaseAppCheck.instanceFor(app: app);

        await appCheck.activate(
          provider: FlutterAppCheckProvider(
            useDeviceCheck: true,
            useAppAttest: false,
          ),
        );

        final token = await appCheck.getToken();
        expect(token, isNotNull);
        expect(token, isNotEmpty);

        final jwt = await _decodeAppCheckJwt(token!);
        expect(jwt.claims.subject, app.options.appId);
        expect(
          jwt.claims.audience,
          contains('projects/${app.options.projectId}'),
        );
        expect(jwt.claims['provider'], 'device_check_device_identification');
      });
    });

    group('reCAPTCHA fallback', () {
      test('uses Play Integrity on Android when native attestation succeeds',
          () async {
        if (Platform.current is! AndroidPlatform) {
          markTestSkipped('Play Integrity App Check requires Android');
          return;
        }

        final app = await getApp(appCheckRecaptchaV3: true);
        final appCheck = FirebaseAppCheck.instanceFor(app: app);

        await appCheck.activate(
          provider: FlutterAppCheckProvider(
            recaptchaV3SiteKey: app.recaptchaV3SiteKey,
            recaptchaWebDomain: 'localhost',
            recaptchaWebAppId: app.webAppId,
          ),
        );

        final token = await appCheck.getToken();
        expect(token, isNotNull);
        expect(token, isNotEmpty);

        final jwt = await _decodeAppCheckJwt(token!);
        expect(jwt.claims['provider'], 'play_integrity');
      });

      testWidgets(
        'recaptcha v3 with all native flags disabled',
        (tester) async {
          final app = await _getAppOrSkip(appCheckRecaptchaV3: true);
          if (app == null) return;

          final ctx = await tester.pumpTestContext();
          final appCheck = FirebaseAppCheck.instanceFor(app: app);

          await appCheck.activate(
            provider: _recaptchaOnlyProvider(
              app: app,
              recaptchaV3SiteKey: app.recaptchaEnterpriseSiteKey,
              getBuildContext: () => ctx.mounted ? ctx : null,
            ),
          );

          final token = await tester.runWithPumps(() => appCheck.getToken());
          expect(token, isNotNull);
          expect(token, isNotEmpty);

          final jwt = await _decodeAppCheckJwt(token!);
          expect(jwt.claims.subject, app.webAppId);
          expect(
            jwt.claims.audience,
            contains('projects/${app.options.projectId}'),
          );
          expect(jwt.claims['provider'], 'recaptcha_v3');
        },
      );

      testWidgets(
        'recaptcha enterprise with all native flags disabled',
        (tester) async {
          final app = await _getAppOrSkip(appCheckRecaptchaEnterprise: true);
          if (app == null) return;

          final ctx = await tester.pumpTestContext();
          final appCheck = FirebaseAppCheck.instanceFor(app: app);

          await appCheck.activate(
            provider: _recaptchaOnlyProvider(
              app: app,
              recaptchaEnterpriseSiteKey: app.recaptchaEnterpriseSiteKey,
              getBuildContext: () => ctx.mounted ? ctx : null,
            ),
          );

          final token = await tester.runWithPumps(() => appCheck.getToken());
          expect(token, isNotNull);
          expect(token, isNotEmpty);

          final jwt = await _decodeAppCheckJwt(token!);
          expect(jwt.claims.subject, app.webAppId);
          expect(
            jwt.claims.audience,
            contains('projects/${app.options.projectId}'),
          );
          expect(jwt.claims['provider'], 'recaptcha_enterprise');
        },
      );
    });
  });
}

/// App Check via reCAPTCHA WebView only (all native `use*` flags disabled).
FlutterAppCheckProvider _recaptchaOnlyProvider({
  required FirebaseApp app,
  String? recaptchaV3SiteKey,
  String? recaptchaEnterpriseSiteKey,
  required BuildContext? Function() getBuildContext,
}) {
  return FlutterAppCheckProvider(
    recaptchaV3SiteKey: recaptchaV3SiteKey,
    recaptchaEnterpriseSiteKey: recaptchaEnterpriseSiteKey,
    recaptchaWebDomain: 'localhost',
    recaptchaWebAppId: app.webAppId,
    usePlayIntegrity: false,
    useDeviceCheck: false,
    useAppAttest: false,
    getBuildContext: getBuildContext,
  );
}

extension on WidgetTester {
  Future<T> runWithPumps<T>(Future<T> Function() callback) async {
    var done = false;
    var f = callback().whenComplete(() => done = true);
    while (!done) {
      await pump();
      await pump(const Duration(milliseconds: 50));
    }
    return f;
  }

  Future<BuildContext> pumpTestContext() async {
    late BuildContext ctx;
    await pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return ctx;
  }
}

Future<JsonWebToken> _decodeAppCheckJwt(String token) {
  return JsonWebToken.decodeAndVerify(
    token,
    JsonWebKeyStore()
      ..addKeySetUrl(
        Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks'),
      ),
  );
}

/// Returns null after [markTestSkipped] when no matching integration config exists.
Future<FirebaseApp?> _getAppOrSkip({
  bool appCheckRecaptchaV3 = false,
  bool appCheckRecaptchaEnterprise = false,
}) async {
  try {
    return await getApp(
      appCheckRecaptchaV3: appCheckRecaptchaV3,
      appCheckRecaptchaEnterprise: appCheckRecaptchaEnterprise,
    );
  } on StateError catch (e) {
    markTestSkipped(e.message);
    return null;
  }
}

/// First generated project with platform configs and optional App Check keys.
Future<FirebaseApp> getApp({
  bool appCheckRecaptchaV3 = false,
  bool appCheckRecaptchaEnterprise = false,
}) async {
  const bundleId = 'be.appsup.firebase-dart-flutter-example';

  final project = allConfigs.firstWhere(
    (p) {
      if (appCheckRecaptchaV3 &&
          (p.webAppCheckRecaptchaV3SiteKey ?? '').isEmpty) {
        return false;
      }
      if (appCheckRecaptchaEnterprise &&
          (p.webAppCheckRecaptchaEnterpriseSiteKey ?? '').isEmpty) {
        return false;
      }
      return true;
    },
    orElse: () => throw StateError(
      'No FirebaseProjectConfig with platform options'
      '${appCheckRecaptchaV3 ? ' and App Check reCAPTCHA v3' : ''}'
      '${appCheckRecaptchaEnterprise ? ' and App Check reCAPTCHA Enterprise' : ''}. '
      'Regenerate configs: dart run tool/generate_firebase_web_config.dart',
    ),
  );

  var app = Firebase.apps
      .firstWhereOrNull((v) => v.options.projectId == project.projectId);
  addTearDown(() async {
    await app?.delete();
  });

  app ??= await Firebase.initializeApp(
    options: switch (Platform.current) {
      AndroidPlatform(:final packageId)
          when project.androidConfigs.isNotEmpty =>
        project.androidConfigs[packageId] ??
            project.androidConfigs[bundleId] ??
            project.androidConfigs.values.first,
      IOsPlatform() ||
      MacOsPlatform() when project.iosConfigs.isNotEmpty =>
        project.iosConfigs[bundleId] ?? project.iosConfigs.values.first,
      _ => project.webConfig,
    },
    name: project.projectId,
  );

  return app;
}

extension on FirebaseApp {
  FirebaseProjectConfig get _projectConfig {
    final projectId = options.projectId;
    for (final c in allConfigs) {
      if (c.projectId == projectId) return c;
    }
    throw StateError('No FirebaseProjectConfig for projectId "$projectId".');
  }

  String get webAppId => _projectConfig.webConfig.appId;

  String get recaptchaV3SiteKey {
    final projectId = options.projectId;
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

  String get recaptchaEnterpriseSiteKey {
    final projectId = options.projectId;
    for (final c in allConfigs) {
      if (c.projectId != projectId) continue;
      final key = c.webAppCheckRecaptchaEnterpriseSiteKey;
      if (key != null && key.isNotEmpty) return key;
      throw StateError(
        'No webAppCheckRecaptchaEnterpriseSiteKey for projectId "$projectId".',
      );
    }
    throw StateError('No FirebaseProjectConfig for projectId "$projectId".');
  }
}
