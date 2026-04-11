import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import '../channel.dart';

class PlayIntegrityVerifier {
  final String projectNumber;
  final String nonce;

  PlayIntegrityVerifier({required this.projectNumber, required this.nonce});

  Future<String> verify() async {
    if (Platform.current is! AndroidPlatform) {
      throw UnsupportedError('Play Integrity is only supported on Android');
    }
    var n = base64Url.encode(sha256.convert(nonce.codeUnits).bytes);
    var token = await channel.invokeMethod<String>('requestIntegrityToken', {
      'projectNumber': projectNumber,
      'nonce': n,
    });
    return token!;
  }
}
