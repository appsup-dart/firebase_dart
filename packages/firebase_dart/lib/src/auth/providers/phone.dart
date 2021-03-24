import '../auth_credential.dart';
import '../auth_provider.dart';

/// This class should be used to either create a new Phone credential with an
/// verification ID and SMS code.
///
/// Typically this provider will be used when calling [verifyPhoneNumber] to
/// generate a new [PhoneAuthCredential] when a SMS code has been sent.
class PhoneAuthProvider extends AuthProvider {
  /// Creates a new instance.
  PhoneAuthProvider() : super(PROVIDER_ID);

  static const String PROVIDER_ID = 'phone';

  static String get PHONE_SIGN_IN_METHOD => PROVIDER_ID;

  /// Create a new [PhoneAuthCredential] from a provided [verificationId] and
  /// [smsCode].
  static AuthCredential credential(
      {required String verificationId, required String smsCode}) {
    return PhoneAuthCredential(
        verificationId: verificationId, smsCode: smsCode);
  }

  static AuthCredential credentialFromTemporaryProof({
    required String temporaryProof,
    required String phoneNumber,
  }) {
    return PhoneAuthCredential(
        temporaryProof: temporaryProof, phoneNumber: phoneNumber);
  }
}

/// The auth credential returned from calling
/// [PhoneAuthProvider.credential].
class PhoneAuthCredential extends AuthCredential {
  /// The SMS code sent to and entered by the user.
  final String? smsCode;

  /// The phone auth verification ID.
  final String? verificationId;

  final String? temporaryProof;

  final String? phoneNumber;

  PhoneAuthCredential(
      {this.verificationId,
      this.smsCode,
      this.temporaryProof,
      this.phoneNumber})
      : super(
          providerId: PhoneAuthProvider.PROVIDER_ID,
          signInMethod: PhoneAuthProvider.PHONE_SIGN_IN_METHOD,
        );

  @override
  Map<String, dynamic> asMap() {
    return {
      ...super.asMap(),
      'verificationId': verificationId,
      'smsCode': smsCode
    };
  }
}
