@Tags(['smoke'])
library;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:test/test.dart';

import '../_generated/firebase_config.g.dart';

void main() {
  late FirebaseAuthImpl auth;

  setUpAll(() async {
    FirebaseDart.setup();
    if (firebaseConfig.isEmpty) {
      throw StateError(
        'Missing smoke Firebase config. '
        'Run: dart run smoke/run.dart --config smoke/firebase-config.json',
      );
    }

    var app = await Firebase.initializeApp(
        options: FirebaseOptions.fromMap(firebaseConfig));

    auth = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
  });

  group('RecaptchaVerifier', () {
    test('should verify', () async {
      var siteKey = await auth.rpcHandler.getRecaptchaSiteKey();
      var verifier = RecaptchaVerifier(siteKey: siteKey);
      var token = await verifier.verify();
      expect(token, isNotEmpty);
      var v = await auth.rpcHandler.sendVerificationCode(
          recaptchaToken: token, phoneNumber: '+32123456789');
      expect(v, isNotEmpty);
    });

    test('should error with invalid site key', () async {
      var verifier = RecaptchaVerifier(siteKey: 'siteKey');
      expect(() => verifier.verify(),
          throwsA(FirebaseAuthException('recaptcha-error')));
    });
  });
}
