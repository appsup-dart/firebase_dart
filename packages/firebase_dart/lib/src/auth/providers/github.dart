import '../auth_provider.dart';
import 'oauth.dart';

/// This class should be used to either create a new GitHub credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// GithubAuthProvider githubProvider = GithubAuthProvider();
/// githubProvider.addScope('repo');
/// githubProvider.setCustomParameters({
///   'allow_signup': 'false',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(githubProvider)
///   .then(...);
/// ```
///
/// If authenticating with GitHub via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential, for
/// example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// GithubAuthCredential githubAuthCredential = GithubAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(githubAuthCredential)
///   .then(...);
/// ```
class GithubAuthProvider extends OAuthProvider {
  /// Creates a new instance.
  GithubAuthProvider() : super(PROVIDER_ID);

  static const String PROVIDER_ID = 'github.com';

  /// This corresponds to the sign-in method identifier.
  static String get GITHUB_SIGN_IN_METHOD => PROVIDER_ID;

  /// Create a new [GithubAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return GithubAuthCredential._(
      accessToken,
    );
  }
}

/// An [AuthCredential] for authenticating via github.com
class GithubAuthCredential extends OAuthCredential {
  GithubAuthCredential._(String accessToken)
      : super(
            providerId: GithubAuthProvider.PROVIDER_ID,
            signInMethod: GithubAuthProvider.GITHUB_SIGN_IN_METHOD,
            accessToken: accessToken);
}
