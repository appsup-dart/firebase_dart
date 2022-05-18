export 'providers/email.dart';
export 'providers/facebook.dart';
export 'providers/github.dart';
export 'providers/google.dart';
export 'providers/oauth.dart';
export 'providers/phone.dart';
export 'providers/saml.dart' show SAMLAuthProvider;
export 'providers/twitter.dart';

/// A base class which all providers must extend.
abstract class AuthProvider {
  /// Constructs a new instance with a given provider identifier.
  const AuthProvider(this.providerId);

  /// The provider ID.
  final String providerId;

  @override
  String toString() {
    return 'AuthProvider(providerId: $providerId)';
  }
}
