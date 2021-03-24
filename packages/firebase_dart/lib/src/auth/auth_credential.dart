import 'package:collection/collection.dart';

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
class AuthCredential {
  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId;

  /// The authentication sign in method for the credential. For example,
  /// 'password', or 'emailLink'. This corresponds to the sign-in method
  /// identifier returned in [fetchSignInMethodsForEmail].
  final String signInMethod;

  const AuthCredential({required this.providerId, required this.signInMethod});

  /// Returns the current instance as a serialized [Map].
  Map<String, dynamic> asMap() => {
        'providerId': providerId,
        'signInMethod': signInMethod,
      };

  @override
  int get hashCode => MapEquality().hash(asMap());

  @override
  bool operator ==(other) =>
      other is AuthCredential && MapEquality().equals(asMap(), other.asMap());

  @override
  String toString() => '$runtimeType${asMap()}';
}
