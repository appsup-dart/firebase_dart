import 'dart:convert';

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

/// Device Check App Check provider (iOS / macOS).
class DeviceCheckAppCheckProvider extends AttestingAppCheckProvider {
  const DeviceCheckAppCheckProvider();

  static bool get _onApple =>
      !kIsWeb &&
      (platform_info.Platform.instance.iOS ||
          platform_info.Platform.instance.macOS);

  /// Whether Apple Device Check is available on the current device.
  static Future<bool> isSupported() async {
    if (!_onApple) return false;
    try {
      return await channel.invokeMethod<bool>('isDeviceCheckSupported') ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) async {
    if (!await isSupported()) {
      throw UnsupportedError(
        'Device Check is not supported on this device '
        '(requires iOS or macOS on a supported physical device).',
      );
    }
    return _attest();
  }

  Future<AppCheckAttestation> _attest() async {
    if (!_onApple) {
      throw UnsupportedError(
        'Device Check App Check requires iOS or macOS.',
      );
    }
    final tokenBytes = await _generateDeviceCheckTokenBytes();
    if (tokenBytes.isEmpty) {
      throw StateError('App Check: empty Device Check token');
    }
    return AppCheckAttestation.deviceCheck(base64Encode(tokenBytes));
  }

  Future<Uint8List> _generateDeviceCheckTokenBytes() async {
    final result =
        await channel.invokeMethod<dynamic>('generateDeviceCheckToken');
    if (result is Uint8List) return result;
    if (result is ByteData) return result.buffer.asUint8List();
    throw StateError(
      'App Check: unexpected Device Check token type: ${result.runtimeType}',
    );
  }
}
