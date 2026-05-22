import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

bool get _onIos => !kIsWeb && platform_info.Platform.instance.iOS;

/// Whether App Attest is available (iOS 14+ on a supported physical device).
Future<bool> isAppAttestSupported() async {
  if (!_onIos) return false;
  try {
    return await channel.invokeMethod<bool>('isAppAttestSupported') ?? false;
  } catch (_) {
    return false;
  }
}

/// App Attest attestation for App Check (initial key attestation or assertion).
///
/// When a cached artifact is present, the assertion path is tried first. On
/// failure, registration (attestation) is retried once without using the cache;
/// a successful exchange overwrites stored state.
Future<AppCheckAttestation> appAttestAttestation(
  FirebaseApp app, {
  required Future<AppAttestChallenge> Function() fetchChallenge,
  bool registrationOnly = false,
}) async {
  if (!_onIos) {
    throw UnsupportedError('App Attest App Check requires iOS 14+.');
  }

  final ctx = await fetchChallenge();
  final challengeBytes = _decodeAppCheckBase64(ctx.challenge);
  if (challengeBytes.isEmpty) {
    throw StateError('App Check: empty App Attest challenge');
  }

  if (ctx.hasArtifact && !registrationOnly) {
    try {
      final assertionBytes = await _generateAssertion(
        keyId: ctx.keyId!,
        artifact: ctx.artifact!,
        challenge: challengeBytes,
      );
      return AppCheckAttestation.appAttestAssertion(
        artifact: _encodeAppCheckBase64(ctx.artifact!),
        assertion: _encodeAppCheckBase64(assertionBytes),
        challenge: ctx.challenge,
      );
    } catch (_) {
      return appAttestAttestation(
        app,
        fetchChallenge: fetchChallenge,
        registrationOnly: true,
      );
    }
  }

  final keyId = await _generateKeyId();

  final attestationBytes = await _attestKey(
    keyId: keyId,
    challenge: challengeBytes,
  );

  return AppCheckAttestation.appAttest(
    attestationStatement: _encodeAppCheckBase64(attestationBytes),
    challenge: ctx.challenge,
    keyId: keyId,
  );
}

Future<String> _generateKeyId() async {
  final keyId = await channel.invokeMethod<String>('generateAppAttestKey');
  if (keyId == null || keyId.isEmpty) {
    throw StateError('App Check: empty App Attest key id');
  }
  return keyId;
}

Future<Uint8List> _attestKey({
  required String keyId,
  required Uint8List challenge,
}) async {
  final hash = Uint8List.fromList(sha256.convert(challenge).bytes);
  final result = await channel.invokeMethod<dynamic>('attestAppAttestKey', {
    'keyId': keyId,
    'clientDataHash': hash,
  });
  return _bytesFromPlatform(result);
}

Future<Uint8List> _generateAssertion({
  required String keyId,
  required Uint8List artifact,
  required Uint8List challenge,
}) async {
  final statement = Uint8List(artifact.length + challenge.length)
    ..setRange(0, artifact.length, artifact)
    ..setRange(artifact.length, artifact.length + challenge.length, challenge);
  final hash = Uint8List.fromList(sha256.convert(statement).bytes);
  final result = await channel.invokeMethod<dynamic>(
    'generateAppAttestAssertion',
    {
      'keyId': keyId,
      'clientDataHash': hash,
    },
  );
  return _bytesFromPlatform(result);
}

Uint8List _bytesFromPlatform(dynamic result) {
  if (result is Uint8List) return result;
  if (result is ByteData) return result.buffer.asUint8List();
  throw StateError(
    'App Check: unexpected App Attest binary type: ${result.runtimeType}',
  );
}

/// Base64url decode (Firebase App Check API format).
Uint8List _decodeAppCheckBase64(String value) {
  var normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  final padding = (4 - normalized.length % 4) % 4;
  normalized += '=' * padding;
  return base64Decode(normalized);
}

/// Base64url encode (Firebase App Check API format).
String _encodeAppCheckBase64(Uint8List bytes) =>
    base64Encode(bytes).replaceAll('+', '-').replaceAll('/', '_');
