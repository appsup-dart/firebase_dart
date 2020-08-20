import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
abstract class AuthCredential {
  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  final String providerId;

  /// The authentication sign in method for the credential. For example,
  /// 'password', or 'emailLink'. This corresponds to the sign-in method
  /// identifier returned in [fetchSignInMethodsForEmail].
  final String signInMethod;

  const AuthCredential({@required this.providerId, @required this.signInMethod})
      : assert(providerId != null),
        assert(signInMethod != null);

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'signInMethod': signInMethod,
      };

  @override
  int get hashCode => MapEquality().hash(toJson());

  @override
  bool operator ==(other) =>
      other is AuthCredential && MapEquality().equals(toJson(), other.toJson());

  @override
  String toString() => '$runtimeType${toJson()}';
}
