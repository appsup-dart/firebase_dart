import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/channel.dart';

String _projectNumber(FirebaseApp app) {
  final senderId = app.options.messagingSenderId;
  if (senderId != null && senderId.isNotEmpty) return senderId;
  throw StateError(
    'App Check Play Integrity requires messagingSenderId (GCP project number) '
    'in FirebaseOptions.',
  );
}

/// Play Integrity attestation for App Check (challenge + integrity token).
Future<AppCheckAttestation> playIntegrityAttestation(
  FirebaseApp app, {
  required String challenge,
}) async {
  if (Platform.current is! AndroidPlatform) {
    throw UnsupportedError('Play Integrity App Check requires Android');
  }
  final token = await channel.invokeMethod<String>('requestIntegrityToken', {
    'projectNumber': _projectNumber(app),
    'nonce': challenge,
  });
  if (token == null || token.isEmpty) {
    throw StateError('App Check: empty Play Integrity token');
  }
  return AppCheckAttestation.playIntegrity(token);
}
