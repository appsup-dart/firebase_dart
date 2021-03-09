import 'dart:async';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:package_info/package_info.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

class FirebaseDartFlutter {
  static const _channel = const MethodChannel('firebase_dart_flutter');

  static Future<void> setup({
    bool isolated = !kIsWeb,
  }) async {
    isolated = isolated && !kIsWeb;
    WidgetsFlutterBinding.ensureInitialized();

    var path;
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      path = appDir.path;

      Hive.init(path);
    }

    FirebaseDart.setup(
        storagePath: path,
        isolated: isolated,
        launchUrl: (url) async {
          await launch(url.toString());
        },
        getAuthResult: () async {
          if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
            return await _channel.invokeMapMethod('getAuthResult');
          }

          throw UnimplementedError();
        },
        oauthSignIn: (provider) async {
          switch (provider.providerId) {
            case 'facebook.com':
              var facebookLogin = FacebookAuth.instance;
              var accessToken = await facebookLogin.login();

              return FacebookAuthProvider.credential(accessToken.token);
            case 'google.com':
              var account = await GoogleSignIn().signIn();
              var auth = await account.authentication;
              return GoogleAuthProvider.credential(
                  idToken: auth.idToken, accessToken: auth.accessToken);
            case 'apple.com':
              if (!platform_info.Platform.instance.isIOS) {
                return null;
              }
              final credential = await SignInWithApple.getAppleIDCredential(
                scopes: [
                  AppleIDAuthorizationScopes.email,
                  AppleIDAuthorizationScopes.fullName,
                ],
              );
              return provider.credential(
                  idToken: credential.identityToken,
                  accessToken: credential.authorizationCode);
          }

          return null;
        },
        oauthSignOut: (providerId) async {
          switch (providerId) {
            case 'facebook.com':
              var facebookLogin = FacebookAuth.instance;
              await facebookLogin.logOut();
              return;
            case 'google.com':
              await GoogleSignIn().signOut();
              return;
          }
          return null;
        },
        platform: await _getPlatform());
  }

  static Future<Platform> _getPlatform() async {
    var p = platform_info.Platform.instance;

    if (kIsWeb) {
      return Platform.web(
        currentUrl: Uri.base.toString(),
        isMobile: p.isMobile,
        isOnline: true,
      );
    }

    switch (p.operatingSystem) {
      case platform_info.OperatingSystem.android:
        var i = await PackageInfo.fromPlatform();
        return Platform.android(
          isOnline: true,
          packageId: i.packageName,
          sha1Cert: await _channel.invokeMethod('getSha1Cert'),
        );
      case platform_info.OperatingSystem.iOS:
        var i = await PackageInfo.fromPlatform();
        return Platform.ios(
          isOnline: true,
          appId: i.packageName,
        );
      case platform_info.OperatingSystem.macOS:
        var i = await PackageInfo.fromPlatform();
        return Platform.macos(
          isOnline: true,
          appId: i.packageName,
        );
      case platform_info.OperatingSystem.linux:
        return Platform.linux(
          isOnline: true,
        );
      case platform_info.OperatingSystem.windows:
        return Platform.windows(
          isOnline: true,
        );
      default:
        throw UnsupportedError('Unsupported platform ${p.operatingSystem}');
    }
  }
}
