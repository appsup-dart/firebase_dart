import '../auth_provider.dart';
import 'oauth.dart';

/// This class should be used to either create a new Google credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// GoogleAuthProvider googleProvider = GoogleAuthProvider();
/// googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
/// googleProvider.setCustomParameters({
///   'login_hint': 'user@example.com'
/// });
///
/// FirebaseAuth.instance.signInWithPopup(googleProvider)
///   .then(...);
/// ```
///
/// If authenticating with Google via a 3rd party, use the returned `accessToken`
/// to sign-in or link the user with the created credential, for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// GoogleAuthCredential googleAuthCredential = GoogleAuthProvider.credential(accessToken: accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(googleAuthCredential)
///   .then(...);
/// ```
class GoogleAuthProvider extends OAuthProvider {
  /// Creates a new instance.
  GoogleAuthProvider() : super(id);

  /// This corresponds to the sign-in method identifier.
  static const String googleSignInMethod = id;

  static const String id = 'google.com';

  @Deprecated('Replaced by lower camel case identifier `id`')
  // ignore: constant_identifier_names
  static const String PROVIDER_ID = id;

  @Deprecated('Replaced by lower camel case identifier `googleSignInMethod`')
  // ignore: constant_identifier_names
  static const GOOGLE_SIGN_IN_METHOD = googleSignInMethod;

  /// Create a new [GoogleAuthCredential] from a provided [accessToken].
  static OAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null,
        'At least one of ID token and access token is required');
    return GoogleAuthCredential._(
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}

/// An [AuthCredential] for authenticating via google.com
class GoogleAuthCredential extends OAuthCredential {
  GoogleAuthCredential._(
      {required String? idToken, required String? accessToken})
      : super(
            providerId: GoogleAuthProvider.id,
            signInMethod: GoogleAuthProvider.googleSignInMethod,
            accessToken: accessToken,
            idToken: idToken);
}
