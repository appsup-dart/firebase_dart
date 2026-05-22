import 'dart:typed_data';

import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:hive/hive.dart';

const _boxName = 'firebase_app_attest';

Future<Box>? _boxFuture;

Future<Box> _box() => _boxFuture ??= PersistenceStorage.openBox(_boxName);

class AppAttestStoredState {
  AppAttestStoredState({required this.keyId, required this.artifact});

  final String keyId;
  final Uint8List artifact;
}

Future<AppAttestStoredState?> loadAppAttestState(String firebaseAppId) async {
  final raw = await _box().then((b) => b.get(firebaseAppId));
  if (raw is! Map) return null;
  final keyId = raw['keyId'];
  final artifact = raw['artifact'];
  if (keyId is! String ||
      keyId.isEmpty ||
      artifact is! List ||
      artifact.isEmpty) {
    return null;
  }
  return AppAttestStoredState(
    keyId: keyId,
    artifact: Uint8List.fromList(artifact.cast<int>()),
  );
}

Future<void> saveAppAttestState(
  String firebaseAppId,
  String keyId,
  Uint8List artifact,
) async {
  final box = await _box();
  await box.put(firebaseAppId, {
    'keyId': keyId,
    'artifact': artifact,
  });
}
