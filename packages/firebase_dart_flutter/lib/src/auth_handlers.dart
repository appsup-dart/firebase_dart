import 'dart:convert';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:logging/logging.dart';

class FacebookAuthHandler extends DirectAuthHandler {
  FacebookAuthHandler() : super(FacebookAuthProvider.PROVIDER_ID);

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
    try {
      var facebookLogin = FacebookAuth.instance;
      var accessToken = (await facebookLogin.login()).accessToken!;

      return FacebookAuthProvider.credential(accessToken.token);
    } catch (e) {
      return null;
    }
  }
}

class GoogleAuthHandler extends DirectAuthHandler {
  GoogleAuthHandler() : super(GoogleAuthProvider.PROVIDER_ID);

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    try {
      await GoogleSignIn().signOut();
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
    try {
      var account = await GoogleSignIn().signIn();
      var auth = await account!.authentication;
      return GoogleAuthProvider.credential(
          idToken: auth.idToken, accessToken: auth.accessToken);
    } on MissingPluginException {
      return null;
    } on AssertionError {
      return null;
    }
  }
}

class AppleAuthHandler extends DirectAuthHandler<OAuthProvider> {
  AppleAuthHandler() : super('apple.com');

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, OAuthProvider provider) async {
    if (!platform_info.Platform.instance.isIOS) {
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

class AndroidAuthHandler extends FirebaseAppAuthHandler {
  static const _channel = MethodChannel('firebase_dart_flutter');

  Future<AuthCredential?>? _lastAuthResult;
  Future<String>? _lastRecaptchaResult;

  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
      return _lastAuthResult ??= Future(() async {
        var v = await _getResult('getAuthResult');
        return createCredential(
            sessionId: v['sessionId'],
            providerId: v['providerId'],
            link: v['link']);
      });
    }
    return null;
  }

  Future<Map<String, dynamic>> _getResult(String type) async {
    var v = (await _channel.invokeMapMethod<String, dynamic>(type))!;
    _lastAuthResult = null;

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

  @override
  Future<String> getVerifyResult(FirebaseApp app) {
    if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await _getResult('getVerifyResult');
        _lastRecaptchaResult = null;

        return Uri.parse(v['link']!).queryParameters['recaptchaToken']!;
      });
    }
    throw UnimplementedError();
  }

  @override
  Future<ApplicationVerificationResult> verify(
      FirebaseAuth auth, String nonce) async {
    var available = await _isGooglePlayServicesAvailable;

    if (available) {
      try {
        return ApplicationVerificationResult(
            'safetynet', await verifyWithSafetyNet(auth, nonce));
      } catch (e, tr) {
        Logger('AndroidAuthHandler')
            .warning('Failed getting SafetyNet token', e, tr);
      }
    }

    return super.verify(auth, nonce);
  }

  Future<String> verifyWithSafetyNet(FirebaseAuth auth, String nonce) async {
    var token = await _channel.invokeMethod<String>('getSafetyNetToken', {
      'apiKey': auth.app.options.apiKey,
      'nonce': nonce,
    });
    return token!;
  }
}

class AndroidSmsRetriever extends SmsRetriever {
  static const _channel = MethodChannel('firebase_dart_flutter');

  late final Future<String?> _appSignatureHash = Future(() async {
    var v = (await _channel.invokeMethod<String>('getAppSignatureHash'))!;
    return v;
  });

  @override
  Future<String?> getAppSignatureHash() {
    if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
      return _appSignatureHash;
    }
    return Future.value();
  }

  @override
  Future<String?> retrieveSms() {
    if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
      return Future(() async {
        var v = (await _channel.invokeMethod<String>('retrieveSms'))!;
        return v;
      });
    }
    return Future.value();
  }
}
