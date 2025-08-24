library firebase_dart_flutter_auth_google;

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthHandler extends DirectAuthHandler {
  GoogleAuthHandler() : super(GoogleAuthProvider.id);

  GoogleSignIn _clientForApp(FirebaseApp app) {
    if (Platform.current is IOsPlatform || Platform.current is MacOsPlatform) {
      if (app.options.iosClientId == null) {
        throw FirebaseAuthException('missing-ios-client-id',
            'Missing iOS client ID in FirebaseOptions');
      }
      return GoogleSignIn(
        clientId: app.options.iosClientId,
      );
    }
    return GoogleSignIn();
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    if (kIsWeb) return;
    try {
      await _clientForApp(app).signOut();
    } on AssertionError {
      // TODO
    } on MissingPluginException {
      // TODO
    } catch (e) {
      // TODO: on release build for web, this throws an exception, should be checked why, for now ignore
    }
  }

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, AuthProvider provider) async {
    if (kIsWeb) return null;
    try {
      var account = await _clientForApp(app).signIn();
      var auth = await account!.authentication;
      return GoogleAuthProvider.credential(
          idToken: auth.idToken, accessToken: auth.accessToken);
    } on MissingPluginException {
      return null;
    } on AssertionError catch (e) {
      return null;
    }
  }
}
