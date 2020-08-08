part of fireauth.credentials;

/// The SAML Auth credential class.
class SAMLAuthCredential extends AuthCredential {
  @override
  final String providerId;

  final String pendingToken;

  String get signInMethod => providerId;

  SAMLAuthCredential(this.providerId, this.pendingToken)
      : assert(pendingToken != null);

  @override
  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'signInMethod': signInMethod,
        'pendingToken': pendingToken
      };
}
