import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/app_check/app_check.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

/// App Check debug provider for development.
///
/// Uses [debugToken] when set in code; otherwise loads or generates a UUID v4
/// stored in Hive per [FirebaseApp.appId] and logs it for Firebase Console
/// registration.
class DebugAppCheckProvider implements AppCheckProvider {
  DebugAppCheckProvider({this.debugToken});

  static final _logger = Logger('DebugAppCheckProvider');
  static const _uuid = Uuid();

  /// Explicit debug secret. When null, a persisted or new UUID is used.
  final String? debugToken;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    final token = await _resolveDebugToken(app);
    return AppCheckAttestation.debug(token);
  }

  Future<String> _resolveDebugToken(FirebaseApp app) async {
    final explicit = debugToken;
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final appId = app.options.appId;
    final stored = await _loadDebugToken(appId);
    if (stored != null) return stored;

    final generated = _uuid.v4();
    await _saveDebugToken(appId, generated);
    _logger.warning(
      "App Check debug token: '$generated'. Register it in the Firebase "
      'Console for this app (Security → App Check → Manage debug tokens).',
    );
    return generated;
  }
}

const _boxName = 'firebase_app_check_debug';

Future<Box>? _boxFuture;

Future<Box> _box() => _boxFuture ??= PersistenceStorage.openBox(_boxName);

Future<String?> _loadDebugToken(String firebaseAppId) async {
  final token = await _box().then((b) => b.get(firebaseAppId));
  if (token is! String || token.isEmpty) return null;
  return token;
}

Future<void> _saveDebugToken(String firebaseAppId, String token) async {
  final box = await _box();
  await box.put(firebaseAppId, token);
}
