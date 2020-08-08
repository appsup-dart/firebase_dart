part of fireauth.credentials;

/// An [AuthCredential] for authenticating via google.com
class GoogleAuthCredential extends OAuthCredential {
  GoogleAuthCredential({@required String idToken, @required String accessToken})
      : super({
          'providerId': GoogleAuthProvider.providerId,
          'accessToken': accessToken,
          'idToken': idToken
        });

  @override
  String get providerId => 'google.com';
}
