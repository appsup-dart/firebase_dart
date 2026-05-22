import 'app_attest_challenge.dart';

/// Internal App Check API surface for platform attestation helpers.
abstract interface class FirebaseAppCheckProtectedMethods {
  /// One-time challenge for Play Integrity attestation (App Check REST API).
  Future<String> generatePlayIntegrityChallenge();

  /// App Attest challenge from the API plus cached [AppAttestChallenge.keyId] /
  /// [AppAttestChallenge.artifact] when a prior attestation succeeded.
  Future<AppAttestChallenge> generateAppAttestChallenge();
}
