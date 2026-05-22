import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';

/// Debug App Check provider (Firebase console debug token).
class DebugAppCheckProvider implements AppCheckProvider {
  DebugAppCheckProvider(this.debugToken);

  final String debugToken;

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (debugToken.isEmpty) {
      throw StateError('App Check: empty debug token');
    }
    return AppCheckAttestation.debug(debugToken);
  }
}
