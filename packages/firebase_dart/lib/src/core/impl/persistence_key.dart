import 'package:firebase_dart/core.dart';
import 'package:hive/hive.dart';

/// Local-storage scope for [app].
///
/// Official SDKs include both the Firebase app id and the app name. An app id
/// alone is shared by every named app created from the same options, and a
/// database host alone is shared by every app pointed at that URL.
String firebaseAppStorageKey(FirebaseApp app) =>
    '${app.options.appId}:${app.name}';

/// Auth user entry for [app].
String firebaseUserStorageKey(FirebaseApp app) =>
    'firebase:FirebaseUser:${firebaseAppStorageKey(app)}';

/// Auth user entry written before the app name was part of the key.
String legacyFirebaseUserStorageKey(FirebaseApp app) =>
    'firebase:FirebaseUser:${app.options.appId}';

/// Hive box for Realtime Database persistence.
///
/// [appStorageKey] is omitted for a stand-alone database, which keeps the
/// host-only name.
String databasePersistenceBoxName({
  required String host,
  String? appStorageKey,
}) {
  if (appStorageKey == null) {
    return legacyDatabasePersistenceBoxName(host);
  }
  return 'firebase-db-persistence-storage-${_hiveSegment(appStorageKey)}-$host';
}

/// Database persistence box written before the app id and name were included.
String legacyDatabasePersistenceBoxName(String host) =>
    'firebase-db-persistence-storage-$host';

/// Copies [legacyKey] to [key] when [key] is empty, then removes [legacyKey].
///
/// The first app to read a legacy value claims it. Leaving the old key in
/// place would copy that same user or token into every named app.
Future<void> migrateStorageValue(
  Box box, {
  required String key,
  required String legacyKey,
}) async {
  if (key == legacyKey || !box.containsKey(legacyKey)) return;
  if (!box.containsKey(key)) {
    await box.put(key, box.get(legacyKey));
  }
  await box.delete(legacyKey);
}

/// Copies entries from [legacy] into an empty [target], then clears [legacy].
Future<void> claimLegacyBox(Box target, Box legacy) async {
  if (target.isNotEmpty || legacy.isEmpty) return;
  await target.putAll(Map<dynamic, dynamic>.from(legacy.toMap()));
  await legacy.clear();
}

String _hiveSegment(String value) =>
    value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
