import 'package:firebase_dart/src/auth/impl/auth.dart';

import 'auth.dart';

abstract class ApplicationVerifier {
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false});
}

class ApplicationVerificationResult {
  final String type;

  final String token;

  ApplicationVerificationResult(this.type, this.token);
  ApplicationVerificationResult.apns(String token) : this('apns', token);
  ApplicationVerificationResult.recaptcha(String token)
      : this('recaptcha', token);
  ApplicationVerificationResult.playItegrity(String token)
      : this('playintegrity', token);

  @override
  String toString() {
    return 'ApplicationVerificationResult($type, $token)';
  }
}

class RecaptchaApplicationVerifier implements ApplicationVerifier {
  const RecaptchaApplicationVerifier();

  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false}) async {
    var siteKey = await (auth as FirebaseAuthImpl).getRecaptchaSiteKey();
    var verifier = RecaptchaVerifier(siteKey: siteKey);

    return ApplicationVerificationResult.recaptcha(await verifier.verify());
  }
}

class DummyApplicationVerifier implements ApplicationVerifier {
  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false}) async {
    return ApplicationVerificationResult.recaptcha(
        'this_will_only_work_on_testing');
  }
}
