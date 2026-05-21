/// Raw attestation from an [AppCheckProvider], before exchange for a JWT.
///
/// Most factories produce proof that [FirebaseAppCheck] exchanges via the App
/// Check API. [AppCheckAttestation.minted] is for tokens already issued by your
/// backend (e.g. Admin SDK `appCheck().createToken()`).
sealed class AppCheckAttestation {
  const AppCheckAttestation._();

  factory AppCheckAttestation.recaptchaV3(String token) =
      RecaptchaV3Attestation;

  factory AppCheckAttestation.recaptchaEnterprise(String token) =
      RecaptchaEnterpriseAttestation;

  factory AppCheckAttestation.playIntegrity(String token) =
      PlayIntegrityAttestation;

  factory AppCheckAttestation.deviceCheck(String token) =
      DeviceCheckAttestation;

  factory AppCheckAttestation.appAttest({
    required String attestationStatement,
    required String challenge,
    required String keyId,
  }) = AppAttestAttestation;

  factory AppCheckAttestation.appAttestAssertion({
    required String artifact,
    required String assertion,
    required String challenge,
  }) = AppAttestAssertionAttestation;

  factory AppCheckAttestation.debug(String debugToken) = DebugAttestation;

  /// Service-account-signed JWT for [exchangeCustomToken] (custom provider B).
  factory AppCheckAttestation.custom(String customToken) =
      CustomTokenAttestation;

  /// App Check JWT already minted on your backend (custom provider A).
  ///
  /// Use when your server returns the result of Admin SDK
  /// `appCheck().createToken(appId)` — no further exchange is performed.
  factory AppCheckAttestation.minted(String token, DateTime expireTime) =
      MintedAppCheckAttestation;
}

final class RecaptchaV3Attestation extends AppCheckAttestation {
  RecaptchaV3Attestation(this.token) : super._();

  final String token;
}

final class RecaptchaEnterpriseAttestation extends AppCheckAttestation {
  RecaptchaEnterpriseAttestation(this.token) : super._();

  final String token;
}

final class PlayIntegrityAttestation extends AppCheckAttestation {
  PlayIntegrityAttestation(this.token) : super._();

  final String token;
}

final class DeviceCheckAttestation extends AppCheckAttestation {
  DeviceCheckAttestation(this.token) : super._();

  final String token;
}

final class AppAttestAttestation extends AppCheckAttestation {
  AppAttestAttestation({
    required this.attestationStatement,
    required this.challenge,
    required this.keyId,
  }) : super._();

  final String attestationStatement;
  final String challenge;
  final String keyId;
}

final class AppAttestAssertionAttestation extends AppCheckAttestation {
  AppAttestAssertionAttestation({
    required this.artifact,
    required this.assertion,
    required this.challenge,
  }) : super._();

  final String artifact;
  final String assertion;
  final String challenge;
}

final class DebugAttestation extends AppCheckAttestation {
  DebugAttestation(this.debugToken) : super._();

  final String debugToken;
}

final class CustomTokenAttestation extends AppCheckAttestation {
  CustomTokenAttestation(this.customToken) : super._();

  final String customToken;
}

/// App Check JWT and expiry from Admin SDK [createToken] or equivalent.
final class MintedAppCheckAttestation extends AppCheckAttestation {
  MintedAppCheckAttestation(this.token, this.expireTime) : super._();

  final String token;
  final DateTime expireTime;
}
