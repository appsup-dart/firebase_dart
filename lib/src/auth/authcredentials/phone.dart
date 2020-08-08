part of fireauth.credentials;

/// An [AuthCredential] for authenticating via phone.
class PhoneAuthCredential extends AuthCredential {
  /// The verification code sent to the user's phone.
  final String smsCode;

  /// The verification ID returned from [FirebaseAuth.verifyPhoneNumber].
  final String verificationId;

  final String temporaryProof;

  final String phoneNumber;

  @override
  String get providerId => 'phone';

  /// Credential that proves ownership of a phone number via a ID [verificationId]
  /// of a request to send a code to the phone number, with the code [smsCode]
  /// that the user received on their phone.
  PhoneAuthCredential.verification({
    @required this.verificationId,
    @required this.smsCode,
  })  : temporaryProof = null,
        phoneNumber = null,
        assert(verificationId != null),
        assert(smsCode != null);

  /// Credential that proves ownership of a phone number by referencing a
  /// previously completed phone Auth flow.
  PhoneAuthCredential.temporaryProof({
    @required this.temporaryProof,
    @required this.phoneNumber,
  })  : verificationId = null,
        smsCode = null,
        assert(temporaryProof != null),
        assert(phoneNumber != null);

  @override
  Map<String, dynamic> toJson() {
    return {
      'providerId': providerId,
      'verificationId': verificationId,
      'smsCode': smsCode
    };
  }
}
