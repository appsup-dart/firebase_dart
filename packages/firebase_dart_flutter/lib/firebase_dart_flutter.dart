import 'dart:async';
import 'dart:isolate';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/auth_handlers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

export 'package:firebase_dart/implementation/pure_dart.dart'
    show ApplicationVerifier, RecaptchaApplicationVerifier;
export 'package:firebase_dart_flutter/src/auth_handlers.dart'
    show FlutterApplicationVerifier;

class FirebaseDartFlutter {
  static const _channel = MethodChannel('firebase_dart_flutter');

  /// Setup the Firebase Dart Flutter SDK.
  ///
  /// When [isolated] is true, the SDK will run in an [Isolate].
  /// This is useful to avoid blocking the main thread.
  ///
  /// For certain tasks, like sending an sms code to verify a phone number, it
  /// is required to verify that the request is coming from a human. For that
  /// purpose, the [applicationVerifier] can be used. By default, an application
  /// verifier is used that tries silent verification first (on android through
  /// Play Integrity, on iOS through APNS). If that fails, it will fall back to
  /// a recaptcha.
  ///
  /// [socialAuthHandlers] is a list of [AuthHandler] that will be used to handle
  /// social authentication. See packages [firebase_dart_flutter_auth_google],
  /// [firebase_dart_flutter_auth_facebook] and
  /// [firebase_dart_flutter_auth_apple] for common social authentication handlers.
  static Future<void> setup({
    bool isolated = !kIsWeb,
    ApplicationVerifier? applicationVerifier,
    List<AuthHandler> socialAuthHandlers = const [],
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
          ...socialAuthHandlers,
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
