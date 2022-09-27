import 'dart:async';

import 'auth.dart';

abstract class FirebaseAuthMixin implements FirebaseAuth {
  @override
  Future<ConfirmationResult> signInWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) async {
    var completer = Completer<ConfirmationResult>();
    await verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verifier: verifier,
        verificationCompleted: (credential) async {
          var r = await completer.future;
          await r.confirm(credential.smsCode!);
        },
        verificationFailed: (e) {
          completer.completeError(e);
        },
        codeSent: (verificationId, [forceResendingToken]) {
          completer.complete(ConfirmationResultImpl(this, verificationId));
        },
        codeAutoRetrievalTimeout: (verificationId) {});
    return completer.future;
  }
}

class ConfirmationResultImpl implements ConfirmationResult {
  final FirebaseAuth _auth;

  /// The phone number authentication operation's verification ID.
  ///
  /// This can be used along with the verification code to initialize a phone
  /// auth credential.
  @override
  final String verificationId;

  ConfirmationResultImpl(this._auth, this.verificationId);

  /// Finishes a phone number sign-in, link, or reauthentication, given the code
  /// that was sent to the user's mobile device.
  @override
  Future<UserCredential> confirm(String verificationCode) {
    return _auth.signInWithCredential(PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: verificationCode));
  }
}
