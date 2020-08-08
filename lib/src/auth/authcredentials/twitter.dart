part of fireauth.credentials;

/// An [AuthCredential] for authenticating via twitter.com
class TwitterAuthCredential extends OAuthCredential {
  TwitterAuthCredential(
      {@required String authToken, @required String authTokenSecret})
      : super({
          'providerId': TwitterAuthProvider.providerId, /*TODO*/
        });
}
