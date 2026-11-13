/// An App Check JWT and the local time at which it expires.
class AppCheckToken {
  /// The token string in JWT format.
  final String token;

  /// The local timestamp after which the token will expire.
  final DateTime expireTime;

  AppCheckToken(this.token, this.expireTime);
}
