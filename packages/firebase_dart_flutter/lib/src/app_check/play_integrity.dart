import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

/// Play Integrity App Check provider (Android).
class PlayIntegrityAppCheckProvider extends BasePlayIntegrityAppCheckProvider {
  const PlayIntegrityAppCheckProvider();

  /// Whether Google Play services are available (Play Integrity).
  static Future<bool> isSupported() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  }

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (Platform.current is! AndroidPlatform) {
      throw UnsupportedError('Play Integrity App Check requires Android');
    }
    if (!await isSupported()) {
      throw StateError('App Check: Google Play services unavailable');
    }

    final challenge = await generatePlayIntegrityChallenge(app);
    return _attest(app, challenge: challenge);
  }

  Future<AppCheckAttestation> _attest(
    FirebaseApp app, {
    required String challenge,
  }) async {
    final token = await channel.invokeMethod<String>('requestIntegrityToken', {
      'projectNumber': _projectNumber(app),
      'nonce': challenge,
    });
    if (token == null || token.isEmpty) {
      throw StateError('App Check: empty Play Integrity token');
    }
    return AppCheckAttestation.playIntegrity(token);
  }

  static String _projectNumber(FirebaseApp app) {
    final senderId = app.options.messagingSenderId;
    if (senderId != null && senderId.isNotEmpty) return senderId;
    throw StateError(
      'App Check Play Integrity requires messagingSenderId (GCP project number) '
      'in FirebaseOptions.',
    );
  }
}
