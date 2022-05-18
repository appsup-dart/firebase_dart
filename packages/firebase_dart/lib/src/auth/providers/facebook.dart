import '../auth_provider.dart';
import 'oauth.dart';

/// This class should be used to either create a new Facebook credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// FacebookAuthProvider facebookProvider = FacebookAuthProvider();
/// facebookProvider.addScope('user_birthday');
/// facebookProvider.setCustomParameters({
///   'display': 'popup',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(facebookProvider)
///   .then(...);
/// ```
///
/// If authenticating with Facebook via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential,
/// for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// FacebookAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(facebookAuthCredential)
///   .then(...);
/// ```
class FacebookAuthProvider extends OAuthProvider {
  /// Creates a new instance.
  FacebookAuthProvider() : super(id);

  static const String id = 'facebook.com';

  /// This corresponds to the sign-in method identifier.
  static const String facebookSignInMethod = id;

  @Deprecated('Replaced by lower camel case identifier `id`')
  // ignore: constant_identifier_names
  static const String PROVIDER_ID = id;

  @Deprecated('Replaced by lower camel case identifier `facebookSignInMethod`')
  // ignore: constant_identifier_names
  static const FACEBOOK_SIGN_IN_METHOD = facebookSignInMethod;

  /// Create a new [FacebookAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return FacebookAuthCredential._(
      accessToken,
    );
  }
}

/// The auth credential returned from calling
/// [FacebookAuthProvider.credential].
class FacebookAuthCredential extends OAuthCredential {
  FacebookAuthCredential._(String accessToken)
      : super(
            providerId: FacebookAuthProvider.id,
            signInMethod: FacebookAuthProvider.facebookSignInMethod,
            accessToken: accessToken);
}
