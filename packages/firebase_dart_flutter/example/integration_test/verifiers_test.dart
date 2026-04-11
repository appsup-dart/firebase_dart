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
import 'package:firebase_dart_flutter/src/verifiers/recaptcha_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:collection/collection.dart';

import 'package:_integration_testing/_integration_testing.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final applicationVerifier = FlutterApplicationVerifier();

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

  group('RecaptchaEnterpriseNativeVerifier', () {
    test('verify completes', () async {
      if (Platform.current is! AndroidPlatform &&
          Platform.current is! IOsPlatform) {
        markTestSkipped(
            'Recaptcha Enterprise native verifier is only supported on Android and iOS');
        return;
      }
      var auth = await getAuth(recaptchaEnterpriseEnabled: true);
      var siteKey =
          await applicationVerifier.getRecaptchaEnterpriseSiteKey(auth);
      var verifier = RecaptchaEnterpriseNativeVerifier(
          siteKey: siteKey, action: 'sendVerificationCode');
      var token = await verifier.verify();
      expect(token, isNotNull);
    });
  });

  group('FlutterApplicationVerifier', () {
    group('with recaptcha enterprise enabled', () {
      testWidgets(
          'verify should return recaptcha enterprise token using native verifier',
          (tester) async {
        var auth = await getAuth(recaptchaEnterpriseEnabled: true);
        var result = await tester.verify(auth,
            nonce: 'nonce', action: 'sendVerificationCode');
        expect(result.type, 'recaptcha-enterprise');
        expect(
            result.token,
            startsWith('${switch (Platform.current) {
              AndroidPlatform() => 'CLIENT_TYPE_ANDROID',
              IOsPlatform() => 'CLIENT_TYPE_IOS',
              _ => 'CLIENT_TYPE_WEB',
            }}:'));
      });
      testWidgets('verify should fallback to recaptcha webview',
          (tester) async {
        var auth = await getAuth(recaptchaEnterpriseEnabled: true);
        var result = await tester.verify(auth,
            nonce: 'nonce',
            action: 'sendVerificationCode',
            useRecaptchaEnterpriseNative: false);
        expect(result.type, 'recaptcha-enterprise');
        expect(result.token, startsWith('CLIENT_TYPE_WEB:'));
      });
    });

    group('with recaptcha enterprise disabled', () {
      testWidgets('verify should return recaptcha token on macos',
          (tester) async {
        if (Platform.current is! MacOsPlatform) {
          markTestSkipped('Recaptcha is default on macOS only');
          return;
        }
        var auth = await getAuth(recaptchaEnterpriseEnabled: false);
        var result = await tester.verify(auth,
            nonce: 'nonce', action: 'sendVerificationCode');
        expect(result.type, 'recaptcha');
        expect(result.token, isNotEmpty);
      });

      testWidgets('verify should return play integrity token on android',
          (tester) async {
        if (Platform.current is! AndroidPlatform) {
          markTestSkipped('Play Integrity is only supported on Android');
          return;
        }
        var auth = await getAuth(recaptchaEnterpriseEnabled: false);
        var result = await tester.verify(auth,
            nonce: 'nonce', action: 'sendVerificationCode');
        expect(result.type, 'playintegrity');
        expect(result.token, isNotEmpty);
      });
    });
  });
}

extension on WidgetTester {
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {required String nonce,
      required String action,
      bool useRecaptchaEnterpriseNative = true,
      bool useApns = true,
      bool usePlayIntegrity = true}) async {
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

    if (!ctx.mounted) throw Exception('Context not mounted');

    final verifier = FlutterApplicationVerifier(
      getBuildContext: () => ctx,
      useRecaptchaEnterpriseNative: useRecaptchaEnterpriseNative,
      useApns: useApns,
      usePlayIntegrity: usePlayIntegrity,
    );

    ApplicationVerificationResult? result;
    verifier
        .verify(auth, nonce: nonce, action: action)
        .then((value) => result = value)
        .ignore();
    while (result == null) {
      await pump();
      await pump(const Duration(milliseconds: 50));
    }

    return result!;
  }
}

Future<FirebaseAuth> getAuth(
    {bool withApns = false, bool? recaptchaEnterpriseEnabled}) async {
  const bundleId = 'be.appsup.firebase-dart-flutter-example';

  var project = allConfigs.firstWhere((project) =>
      (!withApns ||
          project.iosBundleIdsWithApnsConfigured.contains(bundleId)) &&
      (recaptchaEnterpriseEnabled == null ||
          (project.phoneAuthRecaptchaEnforcement ==
                      PhoneAuthRecaptchaEnforcement.enforce ||
                  project.phoneAuthRecaptchaEnforcement ==
                      PhoneAuthRecaptchaEnforcement.audit) ==
              recaptchaEnterpriseEnabled));

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
