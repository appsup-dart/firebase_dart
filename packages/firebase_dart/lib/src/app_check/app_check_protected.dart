/// Internal App Check API surface for platform attestation helpers.
abstract interface class FirebaseAppCheckProtectedMethods {
  /// One-time challenge for Play Integrity attestation (App Check REST API).
  Future<String> generatePlayIntegrityChallenge();
}
