import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/core/impl/persistence_key.dart';
import 'package:hive/hive.dart';

const _boxName = 'firebase_app_check_token';

Future<Box>? _boxFuture;

Future<Box> _box() {
  if (Hive.isBoxOpen(_boxName)) return Future.value(Hive.box(_boxName));
  return _boxFuture ??= PersistenceStorage.openBox(_boxName);
}

Future<AppCheckToken?> loadAppCheckToken(FirebaseApp app) async {
  final raw = await _box().then((box) => box.get(firebaseAppStorageKey(app)));
  if (raw is! Map) return null;
  final token = raw['token'];
  final expireTime = raw['expireTime'];
  if (token is! String || token.isEmpty || expireTime is! String) return null;
  final parsed = DateTime.tryParse(expireTime);
  if (parsed == null) return null;
  return AppCheckToken(token, parsed);
}

Future<void> saveAppCheckToken(FirebaseApp app, AppCheckToken token) async {
  final box = await _box();
  await box.put(firebaseAppStorageKey(app), {
    'token': token.token,
    'expireTime': token.expireTime.toUtc().toIso8601String(),
  });
}

Future<void> deleteAppCheckToken(FirebaseApp app) async {
  final box = await _box();
  await box.delete(firebaseAppStorageKey(app));
}
