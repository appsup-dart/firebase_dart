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
  FacebookAuthProvider() : super(PROVIDER_ID);

  static const String PROVIDER_ID = 'facebook.com';

  /// This corresponds to the sign-in method identifier.
  static String get FACEBOOK_SIGN_IN_METHOD => PROVIDER_ID;

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
            providerId: FacebookAuthProvider.PROVIDER_ID,
            signInMethod: FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD,
            accessToken: accessToken);
}
