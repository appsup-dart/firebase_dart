import 'package:firebase_dart/src/auth/impl/auth.dart';

import 'auth.dart';

export 'app_verifier_io.dart' if (dart.library.html) 'app_verifier_web.dart';

abstract class ApplicationVerifier {
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce);
}

class ApplicationVerificationResult {
  final String type;

  final String token;

  ApplicationVerificationResult(this.type, this.token);

  @override
  String toString() {
    return 'ApplicationVerificationResult($type, $token)';
  }
}

abstract class BaseRecaptchaVerifier implements ApplicationVerifier {
  const BaseRecaptchaVerifier();

  Future<String?> getRecaptchaParameters(FirebaseAuthImpl auth) async {
    var rpcHandler = auth.rpcHandler;
    var response = await rpcHandler.relyingparty.getRecaptchaParam();
    return response.recaptchaSiteKey;
  }

  @override
  Future<ApplicationVerificationResult> verify(
      FirebaseAuth auth, String nonce) async {
    return ApplicationVerificationResult(
        'recaptcha', await verifyWithRecaptcha(auth));
  }

  Future<String> verifyWithRecaptcha(FirebaseAuth auth);
}

class DummyApplicationVerifier extends BaseRecaptchaVerifier {
  @override
  Future<String> verifyWithRecaptcha(FirebaseAuth auth) async {
    return 'this_will_only_work_on_testing';
  }
}
