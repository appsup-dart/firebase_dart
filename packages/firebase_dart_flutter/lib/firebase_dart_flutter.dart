import 'dart:async';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:package_info/package_info.dart';

class FirebaseDartFlutter {
  static const _channel = const MethodChannel('firebase_dart_flutter');

  static Future<void> setup({
    void Function(String errorMessage, StackTrace stackTrace) onError,
  }) async {
    var isolated =
        String.fromEnvironment('FIREBASE_IN_ISOLATE').isNotEmpty && !kIsWeb;

    WidgetsFlutterBinding.ensureInitialized();

    var path;
    if (!kIsWeb) {
      var appDir = await getApplicationDocumentsDirectory();
      path = appDir.path;

      Hive.init(path);
    }

    PureDartFirebase.setup(
        storagePath: path,
        isolated: isolated,
        launchUrl: (url) async {
          await launch(url.toString(), option: CustomTabsOption());
        },
        getAuthResult: () async {
          if (!kIsWeb && platform_info.Platform.instance.isAndroid) {
            return await _channel.invokeMapMethod('getAuthResult');
          }

          throw UnimplementedError();
        },
        onError: onError,
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

    var i = await PackageInfo.fromPlatform();

    switch (p.operatingSystem) {
      case platform_info.OperatingSystem.android:
        return Platform.android(
          isOnline: true,
          packageId: i.packageName,
          sha1Cert: await _channel.invokeMethod('getSha1Cert'),
        );
      case platform_info.OperatingSystem.iOS:
        return Platform.ios(
          isOnline: true,
          appId: i.packageName,
        );
      default:
        throw UnsupportedError('Unsupported platform ${p.operatingSystem}');
    }
  }
}
