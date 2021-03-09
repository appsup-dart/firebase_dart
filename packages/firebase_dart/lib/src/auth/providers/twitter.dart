import '../auth_credential.dart';
import '../auth_provider.dart';
import 'oauth.dart';

/// This class should be used to either create a new Twitter credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// TwitterAuthProvider twitterProvider = TwitterAuthProvider();
/// twitterProvider.setCustomParameters({
///   'lang': 'es'
/// });
///
/// FirebaseAuth.instance.signInWithPopup(twitterProvider)
///   .then(...);
/// ```
///
/// If authenticating with Twitter via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential,
/// for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// String secret = '...'; // From 3rd party provider
/// TwitterAuthCredential twitterAuthCredential = TwitterAuthCredential.credential(accessToken: accessToken, secret: secret);
///
/// FirebaseAuth.instance.signInWithCredential(twitterAuthCredential)
///   .then(...);
/// ```
class TwitterAuthProvider extends AuthProvider {
  /// Creates a new instance.
  TwitterAuthProvider() : super(PROVIDER_ID);

  static const String PROVIDER_ID = 'twitter.com';

  /// This corresponds to the sign-in method identifier.
  static String get TWITTER_SIGN_IN_METHOD => PROVIDER_ID;

  Map<dynamic, dynamic> _parameters = {};

  /// Returns the parameters for this provider instance.
  Map<dynamic, dynamic> get parameters {
    return _parameters;
  }

  /// Sets the OAuth custom parameters to pass in a Twitter OAuth request for
  /// popup and redirect sign-in operations.
  TwitterAuthProvider setCustomParameters(
      Map<dynamic, dynamic> customOAuthParameters) {
    _parameters = customOAuthParameters;
    return this;
  }

  /// Create a new [TwitterAuthCredential] from a provided [accessToken] and
  /// [secret];
  static OAuthCredential credential(
      {required String accessToken, required String secret}) {
    return TwitterAuthCredential._credential(
      accessToken: accessToken,
      secret: secret,
    );
  }
}

/// An [AuthCredential] for authenticating via twitter.com
class TwitterAuthCredential extends OAuthCredential {
  TwitterAuthCredential._credential({
    String? accessToken,
    String? secret,
  }) : super(
            providerId: TwitterAuthProvider.PROVIDER_ID,
            signInMethod: TwitterAuthProvider.TWITTER_SIGN_IN_METHOD,
            accessToken: accessToken,
            secret: secret);
}
