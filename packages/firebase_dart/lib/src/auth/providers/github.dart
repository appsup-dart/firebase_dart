// @dart=2.9

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
class GithubAuthProvider extends AuthProvider {
  /// Creates a new instance.
  GithubAuthProvider() : super(PROVIDER_ID);

  static const String PROVIDER_ID = 'github.com';

  /// This corresponds to the sign-in method identifier.
  static String get GITHUB_SIGN_IN_METHOD => PROVIDER_ID;

  final List<String> _scopes = [];
  Map<dynamic, dynamic> _parameters = {};

  /// Returns the currently assigned scopes to this provider instance.
  List<String> get scopes {
    return _scopes;
  }

  /// Returns the parameters for this provider instance.
  Map<dynamic, dynamic> get parameters {
    return _parameters;
  }

  /// Adds GitHub OAuth scope.
  GithubAuthProvider addScope(String scope) {
    assert(scope != null);
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a GitHub OAuth
  /// request for popup and redirect sign-in operations.
  GithubAuthProvider setCustomParameters(
      Map<dynamic, dynamic> customOAuthParameters) {
    assert(customOAuthParameters != null);
    _parameters = customOAuthParameters;
    return this;
  }

  /// Create a new [GithubAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    assert(accessToken != null);
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
