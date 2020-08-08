import 'package:firebase_dart/src/auth/authcredential.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:meta/meta.dart';

class EmailAuthProvider {
  static const String providerId = 'password';

  static AuthCredential getCredential({
    @required String email,
    @required String password,
  }) {
    return EmailAuthCredential(email: email, password: password);
  }

  static AuthCredential getCredentialWithLink({
    @required String email,
    @required String link,
  }) {
    return EmailAuthCredential(email: email, link: link);
  }
}

class FacebookAuthProvider {
  static const String providerId = 'facebook.com';

  static AuthCredential getCredential({@required String accessToken}) {
    return FacebookAuthCredential(accessToken: accessToken);
  }
}

class GoogleAuthProvider {
  static const String providerId = 'google.com';

  static AuthCredential getCredential({
    @required String idToken,
    @required String accessToken,
  }) {
    return GoogleAuthCredential(idToken: idToken, accessToken: accessToken);
  }
}

class GithubAuthProvider {
  static const String providerId = 'github.com';

  static AuthCredential getCredential({@required String token}) {
    return GithubAuthCredential(accessToken: token);
  }
}

class TwitterAuthProvider {
  static const String providerId = 'twitter.com';

  static AuthCredential getCredential({
    @required String authToken,
    @required String authTokenSecret,
  }) {
    return TwitterAuthCredential(
      authToken: authToken,
      authTokenSecret: authTokenSecret,
    );
  }
}

class PhoneAuthProvider {
  static const String providerId = 'phone';

  static AuthCredential getCredential({
    @required String verificationId,
    @required String smsCode,
  }) {
    return PhoneAuthCredential.verification(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }
}

class OAuthProvider {
  const OAuthProvider({@required this.providerId}) : assert(providerId != null);

  /// The provider ID with which this provider is associated
  final String providerId;

  /// Creates an [OAuthCredential] for the OAuth 2 provider with the provided parameters.
  OAuthCredential getCredential({
    @required String idToken,
    String accessToken,
    String rawNonce,
    String pendingToken,
  }) {
    return OAuthCredential({
      'providerId': providerId,
      'idToken': idToken,
      'accessToken': accessToken,
      'rawNonce': rawNonce,
      'pendingToken': pendingToken
    });
  }
}

/// Generic SAML auth provider.
class SAMLAuthProvider {
  final String providerId;

  SAMLAuthProvider(this.providerId) {
    // SAML provider IDs must be prefixed with the SAML_PREFIX.
    if (!isSaml(providerId)) {
      throw AuthException.argumentError(
          'SAML provider IDs must be prefixed with "$samlPrefix"');
    }
  }

  static const String samlPrefix = 'saml.';
  static bool isSaml(String provider) => provider.startsWith(samlPrefix);
}
