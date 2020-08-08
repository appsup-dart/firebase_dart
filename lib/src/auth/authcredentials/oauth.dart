part of fireauth.credentials;

/// The OAuth credential class
class OAuthCredential extends AuthCredential {
  final Map<String, dynamic> _oauthResponse;

  @override
  String get providerId => _oauthResponse['providerId'];

  /// The ID token when provided by the auth provider
  String get idToken => _oauthResponse.containsKey('idToken') ||
          _oauthResponse.containsKey(('accessToken'))
      ? _oauthResponse['idToken']
      : _oauthResponse['oauthToken'];

  /// The access token
  String get accessToken => _oauthResponse['accessToken'];

  OAuthCredential(this._oauthResponse);

  @override
  Map<String, dynamic> toJson() {
    var obj = {
      'providerId': providerId,
    };
    if (idToken != null) {
      obj['oauthIdToken'] = idToken;
    }
    if (accessToken != null) {
      obj['oauthAccessToken'] = accessToken;
    }
/*
    if (secret != null) {
      obj['oauthTokenSecret'] = secret;
    }
    if (nonce != null) {
      obj['nonce'] = nonce;
    }
    if (pendingToken != null) {
      obj['pendingToken'] = pendingToken;
    }
*/
    return obj;
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  bool operator ==(other) =>
      other is OAuthCredential &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
}
