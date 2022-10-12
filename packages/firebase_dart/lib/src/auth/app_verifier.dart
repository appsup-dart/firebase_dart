import 'auth.dart';

abstract class ApplicationVerifier {
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce);
}

class ApplicationVerificationResult {
  final String type;

  final String token;

  ApplicationVerificationResult(this.type, this.token);
  ApplicationVerificationResult.apns(String token) : this('apns', token);
  ApplicationVerificationResult.recaptcha(String token)
      : this('recaptcha', token);
  ApplicationVerificationResult.safetyNet(String token)
      : this('safetynet', token);

  @override
  String toString() {
    return 'ApplicationVerificationResult($type, $token)';
  }
}

class RecaptchaApplicationVerifier implements ApplicationVerifier {
  const RecaptchaApplicationVerifier();

  @override
  Future<ApplicationVerificationResult> verify(
      FirebaseAuth auth, String nonce) async {
    var verifier = RecaptchaVerifier(auth: auth);

    return ApplicationVerificationResult.recaptcha(await verifier.verify());
  }
}

class DummyApplicationVerifier implements ApplicationVerifier {
  @override
  Future<ApplicationVerificationResult> verify(
      FirebaseAuth auth, String nonce) async {
    return ApplicationVerificationResult.recaptcha(
        'this_will_only_work_on_testing');
  }
}
