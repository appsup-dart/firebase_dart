library;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:platform_info/platform_info.dart' as platform_info;

class AppleAuthHandler extends DirectAuthHandler<OAuthProvider> {
  AppleAuthHandler() : super('apple.com');

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, OAuthProvider provider) async {
    if (!platform_info.Platform.instance.iOS) {
      return null;
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return OAuthProvider.credential(
        providerId: providerId,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode);
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {}
}
