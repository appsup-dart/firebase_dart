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
class TwitterAuthProvider extends OAuthProvider {
  /// Creates a new instance.
  TwitterAuthProvider() : super(id);

  static const String id = 'twitter.com';

  /// This corresponds to the sign-in method identifier.
  static const String twitterSignInMethod = id;

  @Deprecated('Replaced by lower camel case identifier `id`')
  // ignore: constant_identifier_names
  static const String PROVIDER_ID = id;

  @Deprecated('Replaced by lower camel case identifier `twitterSignInMethod`')
  // ignore: constant_identifier_names
  static const TWITTER_SIGN_IN_METHOD = twitterSignInMethod;

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
            providerId: TwitterAuthProvider.id,
            signInMethod: TwitterAuthProvider.twitterSignInMethod,
            accessToken: accessToken,
            secret: secret);
}
