import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../auth_credential.dart';
import '../auth_provider.dart';

/// A generic provider instance.
///
/// This class is extended by other OAuth based providers, or can be used
/// standalone for integration with other 3rd party providers.
class OAuthProvider extends AuthProvider {
  OAuthProvider(String providerId) : super(providerId);

  final List<String> _scopes = [];
  Map<dynamic, dynamic>? _parameters;

  /// Returns the currently assigned scopes to this provider instance.
  /// This is a Web only API.
  List<String> get scopes {
    return _scopes;
  }

  /// Returns the parameters for this provider instance.
  /// This is a Web only API.
  Map<dynamic, dynamic>? get parameters {
    return _parameters;
  }

  /// Adds OAuth scope.
  /// This is a Web only API.
  OAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a OAuth request for popup and
  /// redirect sign-in operations.
  /// This is a Web only API.
  OAuthProvider setCustomParameters(
      Map<dynamic, dynamic> customOAuthParameters) {
    _parameters = customOAuthParameters;
    return this;
  }

  /// Create a new [OAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(
      {required String providerId,
      String? accessToken,
      String? idToken,
      String? rawNonce}) {
    return OAuthCredential(
      providerId: providerId,
      signInMethod: 'oauth',
      accessToken: accessToken,
      idToken: idToken,
      rawNonce: rawNonce,
    );
  }
}

/// A generic OAuth credential.
///
/// This class is extended by other OAuth based credentials, or can be returned
/// when generating credentials from 3rd party OAuth providers.
class OAuthCredential extends AuthCredential {
  /// The OAuth access token associated with the credential if it belongs to an
  /// OAuth provider, such as `facebook.com`, `twitter.com`, etc.
  final String? accessToken;

  /// The OAuth ID token associated with the credential if it belongs to an
  /// OIDC provider, such as `google.com`.
  final String? idToken;

  /// The OAuth access token secret associated with the credential if it belongs
  /// to an OAuth 1.0 provider, such as `twitter.com`.
  final String? secret;

  /// The raw nonce associated with the ID token. It is required when an ID
  /// token with a nonce field is provided. The SHA-256 hash of the raw nonce
  /// must match the nonce field in the ID token.
  final String? rawNonce;

  @protected
  const OAuthCredential({
    required String providerId,
    required String signInMethod,
    this.accessToken,
    this.idToken,
    this.secret,
    this.rawNonce,
  }) : super(providerId: providerId, signInMethod: signInMethod);

  @override
  Map<String, String?> asMap() {
    return {
      ...super.asMap(),
      'idToken': idToken,
      'accessToken': accessToken,
      'secret': secret,
      'rawNonce': rawNonce,
    };
  }

  @override
  int get hashCode => const DeepCollectionEquality().hash(asMap());

  @override
  bool operator ==(other) =>
      other is OAuthCredential &&
      const DeepCollectionEquality().equals(asMap(), other.asMap());
}
