import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/recaptcha_verifier.dart';
import 'package:meta/meta.dart';

import 'auth.dart';

abstract class ApplicationVerifier {
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {bool forceRecaptcha = false,
      required String action,
      required String nonce});
}

class ApplicationVerificationResult {
  final String type;

  final String token;

  ApplicationVerificationResult(this.type, this.token);
  ApplicationVerificationResult.apns(String token) : this('apns', token);
  ApplicationVerificationResult.recaptcha(String token)
      : this('recaptcha', token);
  ApplicationVerificationResult.recaptchaEnterprise(String token)
      : this('recaptcha-enterprise', token);
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
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {bool forceRecaptcha = false,
      required String action,
      required String nonce}) async {
    if (await isRecaptchaEnterpriseEnabledForAction(auth, action)) {
      var siteKey = await getRecaptchaEnterpriseSiteKey(auth);
      var verifier = RecaptchaVerifier(siteKey: siteKey, action: action);
      return ApplicationVerificationResult.recaptchaEnterprise(
          'CLIENT_TYPE_WEB:${await verifier.verify()}');
    }

    var siteKey = await getRecaptchaSiteKey(auth);
    var verifier = RecaptchaVerifier(siteKey: siteKey);

    return ApplicationVerificationResult.recaptcha(await verifier.verify());
  }
}

class DummyApplicationVerifier implements ApplicationVerifier {
  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth,
      {bool forceRecaptcha = false,
      required String action,
      required String nonce}) async {
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

  @protected
  @visibleForTesting
  Future<bool> isRecaptchaEnterpriseEnabledForAction(
    FirebaseAuth auth,
    String action,
  ) async {
    if (auth is FirebaseAuthProtectedMethods) {
      return auth.isRecaptchaEnterpriseEnabledForAction(action);
    }
    throw UnimplementedError();
  }

  @protected
  @visibleForTesting
  Future<String> getRecaptchaEnterpriseSiteKey(FirebaseAuth auth,
      {bool useNativeVerifier = true}) async {
    if (auth is FirebaseAuthProtectedMethods) {
      return auth.getRecaptchaEnterpriseSiteKey(
          useNativeVerifier: useNativeVerifier);
    }
    throw UnimplementedError();
  }
}
