import 'dart:typed_data';

/// Result of [generateAppAttestChallenge].
///
/// On the first App Attest registration, only [challenge] is set. After a
/// successful [exchangeAppAttestAttestation], later calls also include [artifact]
/// (and [keyId]) from internal storage for the assertion path.
class AppAttestChallenge {
  const AppAttestChallenge({
    required this.challenge,
    this.keyId,
    this.artifact,
  });

  /// Base64url challenge from the App Check API.
  final String challenge;

  /// Apple key id from the prior attestation exchange (only with [artifact]).
  final String? keyId;

  /// Artifact from the prior attestation exchange, if registered.
  final Uint8List? artifact;

  bool get hasArtifact =>
      artifact != null && artifact!.isNotEmpty && keyId != null;
}
