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

class FirebaseDartFlutter {
  static const _channel = MethodChannel('firebase_dart_flutter');

  static Future<void> setup({
    bool isolated = !kIsWeb,
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
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
        authHandler: AuthHandler.from([
          GoogleAuthHandler(),
          FacebookAuthHandler(),
          AppleAuthHandler(),
          AndroidAuthHandler(),
          const AuthHandler(),
        ]),
        applicationVerifier: AndroidAuthHandler(),
        smsRetriever: AndroidSmsRetriever(),
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
