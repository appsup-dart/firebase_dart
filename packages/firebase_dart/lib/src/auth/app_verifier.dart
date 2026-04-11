import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/recaptcha_verifier.dart';
import 'package:meta/meta.dart';

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

class RecaptchaApplicationVerifier extends BaseApplicationVerifier {
  const RecaptchaApplicationVerifier();

  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false}) async {
    var siteKey = await getRecaptchaSiteKey(auth);
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

abstract class BaseApplicationVerifier implements ApplicationVerifier {
  const BaseApplicationVerifier();

  @protected
  @visibleForTesting
  Future<String> getRecaptchaSiteKey(FirebaseAuth auth) async {
    if (auth is FirebaseAuthProtectedMethods) {
      return auth.getRecaptchaSiteKey();
    }
    throw UnimplementedError();
  }

  @protected
  @visibleForTesting
  Future<Duration> verifyIosClient(FirebaseAuth auth,
      {required String appToken, required bool isSandbox}) async {
    if (auth is FirebaseAuthProtectedMethods) {
      return auth.verifyIosClient(appToken: appToken, isSandbox: isSandbox);
    }
    throw UnimplementedError();
  }

  @protected
  @visibleForTesting
  Future<String> getProducerProjectNumber(FirebaseAuth auth) async {
    if (auth is FirebaseAuthProtectedMethods) {
      return auth.getProducerProjectNumber();
    }
    throw UnimplementedError();
  }
}
