import 'dart:async';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/auth_handlers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

export 'package:firebase_dart/implementation/pure_dart.dart'
    show ApplicationVerifier, RecaptchaApplicationVerifier;
export 'package:firebase_dart_flutter/src/auth_handlers.dart'
    show FlutterApplicationVerifier;

class FirebaseDartFlutter {
  static const _channel = MethodChannel('firebase_dart_flutter');

  static Future<void> setup({
    bool isolated = !kIsWeb,
    ApplicationVerifier? applicationVerifier,
  }) async {
    isolated = isolated && !kIsWeb;
    WidgetsFlutterBinding.ensureInitialized();

    String? path;
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      path = appDir.path;
      if (isolated) {
        Hive.init(path);
      }
    }

    FirebaseDart.setup(
        storagePath: path,
        isolated: isolated,
        launchUrl: kIsWeb
            ? null
            : (url, {bool popup = false}) async {
                await launchUrl(url, mode: LaunchMode.inAppBrowserView);
              },
        authHandler: AuthHandler.from([
          GoogleAuthHandler(),
          FacebookAuthHandler(),
          AppleAuthHandler(),
          FlutterAuthHandler(),
          const AuthHandler(),
        ]),
        applicationVerifier: applicationVerifier ??
            (kIsWeb ? null : FlutterApplicationVerifier()),
        smsRetriever: AndroidSmsRetriever(),
        platform: await _getPlatform());
  }

  static Future<Platform> _getPlatform() async {
    var p = platform_info.Platform.instance;

    if (kIsWeb) {
      return Platform.web(
        currentUrl: Uri.base.toString(),
        isMobile: p.mobile,
        isOnline: true,
      );
    }

    if (p.android) {
      var i = await PackageInfo.fromPlatform();
      return Platform.android(
        isOnline: true,
        packageId: i.packageName,
        sha1Cert: await _channel.invokeMethod('getSha1Cert'),
      );
    } else if (p.iOS) {
      var i = await PackageInfo.fromPlatform();
      return Platform.ios(
        isOnline: true,
        appId: i.packageName,
      );
    } else if (p.macOS) {
      var i = await PackageInfo.fromPlatform();
      return Platform.macos(
        isOnline: true,
        appId: i.packageName,
      );
    } else if (p.linux) {
      return Platform.linux(
        isOnline: true,
      );
    } else if (p.windows) {
      return Platform.windows(
        isOnline: true,
      );
    } else {
      throw UnsupportedError('Unsupported platform ${p.operatingSystem}');
    }
  }
}
