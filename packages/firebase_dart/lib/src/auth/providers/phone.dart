import '../auth_credential.dart';
import '../auth_provider.dart';

/// This class should be used to either create a new Phone credential with an
/// verification ID and SMS code.
///
/// Typically this provider will be used when calling [signInWithPhoneNumber] to
/// generate a new [PhoneAuthCredential] when a SMS code has been sent.
class PhoneAuthProvider extends AuthProvider {
  /// Creates a new instance.
  PhoneAuthProvider() : super(id);

  static const String id = 'phone';

  static const String phoneSignInMethod = id;

  @Deprecated('Replaced by lower camel case identifier `id`')
  // ignore: constant_identifier_names
  static const String PROVIDER_ID = id;

  @Deprecated('Replaced by lower camel case identifier `phoneSignInMethod`')
  // ignore: constant_identifier_names
  static const PHONE_SIGN_IN_METHOD = phoneSignInMethod;

  /// Create a new [PhoneAuthCredential] from a provided [verificationId] and
  /// [smsCode].
  static PhoneAuthCredential credential(
      {required String verificationId, required String smsCode}) {
    return PhoneAuthCredential(
        verificationId: verificationId, smsCode: smsCode);
  }

  static PhoneAuthCredential credentialFromTemporaryProof({
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
          providerId: PhoneAuthProvider.id,
          signInMethod: PhoneAuthProvider.phoneSignInMethod,
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
