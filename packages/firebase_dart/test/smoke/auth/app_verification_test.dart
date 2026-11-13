@Tags(['smoke'])
library;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/recaptcha_verifier.dart';
import 'package:test/test.dart';

import '../smoke_test_util.dart';

Future<FirebaseAuthImpl> getAuth(
    {bool? phoneAuthRecaptchaEnterpriseEnabled}) async {
  final app = await getApp(
      phoneAuthRecaptchaEnterpriseEnabled: phoneAuthRecaptchaEnterpriseEnabled);
  return FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
}

void main() {
  setUpAll(() async {
    FirebaseDart.setup();
  });

  group('RecaptchaVerifier', () {
    group('challenge-based site keys', () {
      test('should verify', () async {
        final auth = await getAuth(phoneAuthRecaptchaEnterpriseEnabled: false);
        var siteKey = await auth.rpcHandler.getRecaptchaSiteKey();
        var verifier = RecaptchaVerifier(siteKey: siteKey);
        var token = await verifier.verify();
        expect(token, isNotEmpty);
      });

      test('should error with invalid site key', () async {
        var verifier = RecaptchaVerifier(siteKey: 'siteKey');
        expect(() => verifier.verify(),
            throwsA(FirebaseAuthException('recaptcha-error')));
      });
    });

    group('score-based site keys', () {
      test('should verify', () async {
        final auth = await getAuth(phoneAuthRecaptchaEnterpriseEnabled: true);
        var config = await auth.rpcHandler.getRecaptchaConfig(
            clientType: 'CLIENT_TYPE_WEB', version: 'RECAPTCHA_ENTERPRISE');
        final phoneState = config.recaptchaEnforcementState!
            .firstWhere((e) => e.provider == 'PHONE_PROVIDER')
            .enforcementState;
        expect(phoneState, anyOf('ENFORCE', 'AUDIT'));

        var siteKey = config.recaptchaKey!.split('/').last;
        var verifier =
            RecaptchaVerifier(siteKey: siteKey, action: 'sendVerificationCode');
        var token = await verifier.verify();
        expect(token, isNotEmpty);
      });

      test('should error with invalid site key', () async {
        var verifier = RecaptchaVerifier(
            siteKey: 'siteKey', action: 'sendVerificationCode');
        expect(
            () => verifier.verify(),
            throwsA(FirebaseAuthException('recaptcha-error',
                'Invalid site key or not loaded in api.js: siteKey')));
      });
    });
  });

  group('RecaptchaApplicationVerifier', () {
    final verifier = RecaptchaApplicationVerifier();

    test(
        'verify should return recaptcha enterprise token when recaptcha enterprise is enabled',
        () async {
      final auth = await getAuth(phoneAuthRecaptchaEnterpriseEnabled: true);
      var token = await verifier.verify(auth,
          nonce: 'nonce', action: 'sendVerificationCode');
      expect(token.type, 'recaptcha-enterprise');
      expect(token.token, startsWith('CLIENT_TYPE_WEB:'));
    });

    test(
        'verify should return recaptcha token when recaptcha enterprise is disabled',
        () async {
      final auth = await getAuth(phoneAuthRecaptchaEnterpriseEnabled: false);
      var token = await verifier.verify(auth,
          nonce: 'nonce', action: 'sendVerificationCode');
      expect(token.type, 'recaptcha');
      expect(token.token, isNotEmpty);
    });
  });
}
