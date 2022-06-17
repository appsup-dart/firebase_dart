import 'package:firebase_dart/src/auth/impl/auth.dart';

import 'auth.dart';

export 'app_verifier_io.dart' if (dart.library.html) 'app_verifier_web.dart';

abstract class ApplicationVerifier {
  Future<String> verify(FirebaseAuth auth);
}

abstract class BaseRecaptchaVerifier extends ApplicationVerifier {
  Future<String?> getRecaptchaParameters(FirebaseAuthImpl auth) async {
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
