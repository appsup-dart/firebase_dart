import 'dart:convert';

import 'package:crypto/crypto.dart';
import '../channel.dart';

class PlayIntegrityVerifier {
  final String projectNumber;
  final String nonce;

  PlayIntegrityVerifier({required this.projectNumber, required this.nonce});

  Future<String> verify() async {
    var n = base64Url.encode(sha256.convert(nonce.codeUnits).bytes);
    var token = await channel.invokeMethod<String>('requestIntegrityToken', {
      'projectNumber': projectNumber,
      'nonce': n,
    });
    return token!;
  }
}
