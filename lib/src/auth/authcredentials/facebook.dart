part of fireauth.credentials;

/// An [AuthCredential] for authenticating via facebook.com
class FacebookAuthCredential extends OAuthCredential {
  FacebookAuthCredential({@required String accessToken})
      : super({
          'providerId': FacebookAuthProvider.providerId,
          'accessToken': accessToken
        });
}
