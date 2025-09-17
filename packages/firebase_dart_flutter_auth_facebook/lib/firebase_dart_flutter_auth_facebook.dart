library;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthHandler extends DirectAuthHandler {
  final String Function(FirebaseApp) facebookAppIdForFirebaseApp;

  FacebookAuthHandler({required this.facebookAppIdForFirebaseApp})
      : super(FacebookAuthProvider.id);

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    try {
      var facebookLogin = FacebookAuth.instance;
      await facebookLogin.logOut();
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, AuthProvider provider) async {
    if (Platform.current is WebPlatform) return null;
    var facebookLogin = FacebookAuth.instance;
    if (Platform.current is MacOsPlatform) {
      await facebookLogin.webAndDesktopInitialize(
          appId: facebookAppIdForFirebaseApp(app),
          cookie: true,
          xfbml: true,
          version: 'v18.0');
    }
    var r = await facebookLogin.login();
    if (r.status != LoginStatus.success) return null;
    var accessToken = r.accessToken!;

    return FacebookAuthProvider.credential(accessToken.tokenString);
  }
}
