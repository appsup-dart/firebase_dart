import 'package:firebase_dart/src/auth/auth.dart';

import 'app_verifier.dart';

class RecaptchaVerifier extends BaseRecaptchaVerifier {
  @override
  Future<String> verify(FirebaseAuth auth) {
    throw UnimplementedError();
  }
}
