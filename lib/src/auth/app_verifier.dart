import 'package:firebase_dart/src/auth/impl/auth.dart';

import 'auth.dart';

import 'app_verifier_io.dart' if (dart.html) 'app_verifier_web.dart';

abstract class ApplicationVerifier {
  String get type;

  Future<String> verify(FirebaseAuth auth);

  static ApplicationVerifier instance = RecaptchaVerifier();
}

abstract class BaseRecaptchaVerifier extends ApplicationVerifier {
  @override
  String get type => 'recaptcha';

  Future<String> getRecaptchaParameters(FirebaseAuthImpl auth) async {
    var rpcHandler = auth.rpcHandler;
    var response = await rpcHandler.relyingparty.getRecaptchaParam();
    return response.recaptchaSiteKey;
  }
}

class DummyApplicationVerifier extends BaseRecaptchaVerifier {
  @override
  Future<String> verify(FirebaseAuth auth) async {
    return 'this_will_only_work_on_testing';
  }
}
