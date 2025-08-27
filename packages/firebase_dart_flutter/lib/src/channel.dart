import 'dart:convert';

import 'package:firebase_dart/auth.dart';
import 'package:flutter/services.dart';

const channel = MethodChannel('firebase_dart_flutter');

Future<Map<String, dynamic>> getResult(String type) async {
  var v = (await channel.invokeMapMethod<String, dynamic>(type))!;

  Map<String, dynamic>? error =
      v['firebaseError'] == null ? null : json.decode(v['firebaseError']);
  if (error != null) {
    var code = error['code'];
    if (code.startsWith('auth/')) {
      code = code.substring('auth/'.length);
    }
    throw FirebaseAuthException(code, error['message']);
  }
  return v;
}
