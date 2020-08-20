import 'package:firebase_dart/auth.dart';

import '../auth_provider.dart';

/// Security Assertion Markup Language based provider.
class SAMLAuthProvider extends AuthProvider {
  // ignore: public_member_api_docs
  SAMLAuthProvider(String providerId)
      : assert(providerId != null),
        super(providerId) {
    // SAML provider IDs must be prefixed with the SAML_PREFIX.
    if (!isSaml(providerId)) {
      throw FirebaseAuthException.argumentError(
          'SAML provider IDs must be prefixed with "$samlPrefix"');
    }
  }
}

/// The SAML Auth credential class.
class SAMLAuthCredential extends AuthCredential {
  final String pendingToken;

  SAMLAuthCredential(String providerId, this.pendingToken)
      : assert(pendingToken != null),
        super(providerId: providerId, signInMethod: providerId) {
    // SAML provider IDs must be prefixed with the SAML_PREFIX.
    if (!isSaml(providerId)) {
      throw FirebaseAuthException.argumentError(
          'SAML provider IDs must be prefixed with "$samlPrefix"');
    }
  }

  @override
  Map<String, dynamic> toJson() =>
      {...super.toJson(), 'pendingToken': pendingToken};
}

const String samlPrefix = 'saml.';
bool isSaml(String provider) => provider.startsWith(samlPrefix);
