import '../auth_credential.dart';
import '../auth_provider.dart';
import '../error.dart';

/// Security Assertion Markup Language based provider.
class SAMLAuthProvider extends AuthProvider {
  // ignore: public_member_api_docs
  SAMLAuthProvider(String providerId) : super(providerId) {
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
      : super(providerId: providerId, signInMethod: providerId) {
    // SAML provider IDs must be prefixed with the SAML_PREFIX.
    if (!isSaml(providerId)) {
      throw FirebaseAuthException.argumentError(
          'SAML provider IDs must be prefixed with "$samlPrefix"');
    }
  }

  @override
  Map<String, dynamic> asMap() =>
      {...super.asMap(), 'pendingToken': pendingToken};
}

const String samlPrefix = 'saml.';
bool isSaml(String provider) => provider.startsWith(samlPrefix);
