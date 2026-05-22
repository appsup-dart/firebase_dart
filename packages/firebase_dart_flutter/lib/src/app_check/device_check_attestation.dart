import 'dart:convert';

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

bool get _onApple =>
    !kIsWeb &&
    (platform_info.Platform.instance.iOS ||
        platform_info.Platform.instance.macOS);

/// Whether Apple Device Check is available on the current device.
///
/// Supported on iOS 11+ and macOS 10.15+ via the plugin [MethodChannel].
/// Returns false on simulator in most cases.
Future<bool> isDeviceCheckSupported() async {
  if (!_onApple) return false;
  try {
    return await channel.invokeMethod<bool>('isDeviceCheckSupported') ?? false;
  } catch (_) {
    return false;
  }
}

/// Device Check attestation for App Check ([DCDevice.generateToken]).
///
/// The token is base64-encoded for [exchangeDeviceCheckToken], matching the
/// Firebase App Check Apple SDKs.
Future<AppCheckAttestation> deviceCheckAttestation() async {
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
