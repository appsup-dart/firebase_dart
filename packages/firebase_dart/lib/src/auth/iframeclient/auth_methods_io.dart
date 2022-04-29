import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/core.dart';

Future<Map<String, dynamic>> webGetAuthResult() async {
  throw UnimplementedError();
}

void webLaunchUrl(Uri uri, {bool popup = false}) {
  throw UnimplementedError();
}

class DefaultAuthHandler implements AuthHandler {
  const DefaultAuthHandler();

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    return null;
  }

  @override
  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false}) async {
    return false;
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {}
}
