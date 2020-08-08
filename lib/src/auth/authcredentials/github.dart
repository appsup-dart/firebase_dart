part of fireauth.credentials;

/// An [AuthCredential] for authenticating via github.com
class GithubAuthCredential extends OAuthCredential {
  GithubAuthCredential({@required String accessToken})
      : super({
          'providerId': GithubAuthProvider.providerId,
          'accessToken': accessToken
        });
}
