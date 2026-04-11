@Tags(['smoke'])
library;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_webview.dart';
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_redirect.dart';
import 'package:firebase_dart_flutter/src/verifiers/play_integrity.dart';
import 'package:firebase_dart_flutter/src/verifiers/apns.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:collection/collection.dart';

import 'package:_integration_testing/_integration_testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final FlutterApplicationVerifier applicationVerifier =
      FlutterApplicationVerifier();

  setUpAll(() async {
    await FirebaseDartFlutter.setup(
      applicationVerifier: applicationVerifier,
      isolated: false,
    );
  });

  group('RecaptchaWebViewVerifier', () {
    testWidgets('verify completes', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      var auth = await getAuth();
      var siteKey = await applicationVerifier.getRecaptchaSiteKey(auth);

      if (!ctx.mounted) throw Exception('Context not mounted');

      final verifier = RecaptchaWebViewVerifier(
        context: ctx,
        siteKey: siteKey,
        baseUrl: 'http://${auth.app.options.authDomain ?? '127.0.0.1:8080'}',
      );

      // verify() awaits the overlay WebView; pump frames so [RecaptchaWidget]
      // runs initState / _prepareController while that future is pending.
      String? token;
      verifier.verify().then((value) => token = value).ignore();
      while (token == null) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(token, isNotEmpty);
    });
  });
  group('PlayIntegrityVerifier', () {
    test('verify completes on Android', () async {
      if (Platform.current is! AndroidPlatform) {
        markTestSkipped('Play Integrity is only supported on Android');
        return;
      }
      var auth = await getAuth();
      var projectNumber =
          await applicationVerifier.getProducerProjectNumber(auth);

      const nonce = '+32123456789';
      final verifier = PlayIntegrityVerifier(
        projectNumber: projectNumber,
        nonce: nonce,
      );
      final token = await verifier.verify();
      expect(token, isNotEmpty);
    });

    test('verify throws on non-Android platforms', () async {
      if (Platform.current is AndroidPlatform) {
        markTestSkipped('Play Integrity is supported on Android');
        return;
      }
      var auth = await getAuth();
      var projectNumber =
          await applicationVerifier.getProducerProjectNumber(auth);

      const nonce = '+32123456789';
      final verifier = PlayIntegrityVerifier(
        projectNumber: projectNumber,
        nonce: nonce,
      );
      expect(() => verifier.verify(), throwsUnsupportedError);
    });
  });

  group('RecaptchaRedirectVerifier', () {
    test('verify completes', () async {
      var auth = await getAuth();
      final verifier = RecaptchaRedirectVerifier(app: auth.app);

      var token = await verifier.verify();
      expect(token, isNotNull);
    });
  });

  group('ApnsVerifier', () {
    test('verify completes on iOS', () async {
      if (Platform.current is! IOsPlatform) {
        markTestSkipped('APNs is only supported on iOS');
        return;
      }
      var auth = await getAuth(withApns: true);

      final verifier = ApnsVerifier(
          iosClientVerifier: (appToken, isSandbox) => applicationVerifier
              .verifyIosClient(auth, appToken: appToken, isSandbox: true));
      var token = await verifier.verify();
      expect(token, isNotNull);
    });
  });
}

Future<FirebaseAuth> getAuth({bool withApns = false}) async {
  const bundleId = 'be.appsup.firebase-dart-flutter-example';

  var project = allConfigs.firstWhere((project) =>
      !withApns || project.iosBundleIdsWithApnsConfigured.contains(bundleId));

  var app = Firebase.apps
      .firstWhereOrNull((v) => v.options.projectId == project.projectId);

  app ??= await Firebase.initializeApp(
      options: switch (Platform.current) {
    AndroidPlatform() => project.androidConfigs.values.first,
    IOsPlatform() ||
    MacOsPlatform() =>
      project.iosConfigs[bundleId] ?? project.iosConfigs.values.first,
    WebPlatform() => project.webConfig,
    _ => project.webConfig,
  });

  return FirebaseAuth.instanceFor(app: app);
}
