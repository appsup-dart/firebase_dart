import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

export 'package:firebase_dart/src/auth/utils.dart' show Platform;

import 'dart:io' as io;

const bool _kIsWeb = identical(0, 0.0);

class FirebaseDart {
  /// Initializes the pure dart firebase implementation.
  ///
  /// On flutter, use the `FirebaseDartFlutter.setup()` method instead.
  ///
  /// When [storagePath] is defined, persistent cache will be stored in files at
  /// that location. On web, local storage will be used instead and the value of
  /// [storagePath] is ignored. On non-web platforms, a memory cache will be
  /// used instead of a file cache when [storagePath] is `null`.
  ///
  /// On android and ios apps, a [platform] should be specified containing some
  /// app specific properties. This is necessary for certain auth methods. On
  /// other platforms or when not using these auth methods, the [platform]
  /// argument can be omitted.
  ///
  /// For signing in with social auth providers, a number of platform specific
  /// callbacks are required: [launchUrl], [getAuthResult], [oauthSignIn] and
  /// [oauthSignOut]. When omitted, a default implementation will be used on web
  /// and on other platforms, attempts to sign in with social auth providers
  /// will throw errors.
  ///
  /// When [isolated] is true, all operations will run in a separate isolate.
  /// Isolates are not supported on web.
  ///
  /// A custom [httpClient] can be specified to handle all http requests. This
  /// can be usefull for testing purposes, but is generally unnecessary.
  ///
  static void setup(
      {String storagePath,
      Platform platform,
      bool isolated = false,
      Function(Uri url) launchUrl,
      Future<Map<String, dynamic>> Function() getAuthResult,
      Future<OAuthCredential> Function(OAuthProvider provider) oauthSignIn,
      Future<void> Function(String providerId) oauthSignOut,
      http.Client httpClient}) {
    platform ??= _kIsWeb
        ? Platform.web(
            currentUrl: Uri.base.toString(),
            isMobile: io.Platform.isAndroid || io.Platform.isIOS,
            isOnline: true,
          )
        : Platform.linux(isOnline: true);

    launchUrl ??= _kIsWeb
        ? (url) => throw UnimplementedError()
        : (url) => throw UnsupportedError(
            'Social sign in not supported on this platform.');
    getAuthResult ??= _kIsWeb
        ? () => throw UnimplementedError()
        : () => throw UnsupportedError(
            'Social sign in not supported on this platform.');
    oauthSignIn ??= _kIsWeb
        ? (proivider) => throw UnimplementedError()
        : (proivider) => throw UnsupportedError(
            'Social sign in not supported on this platform.');
    oauthSignOut ??= (proivider) => null;

    if (isolated && !_kIsWeb) {
      FirebaseImplementation.install(IsolateFirebaseImplementation(
          storagePath: storagePath,
          platform: platform,
          launchUrl: launchUrl,
          getAuthResult: getAuthResult,
          oauthSignIn: oauthSignIn,
          oauthSignOut: oauthSignOut,
          httpClient: httpClient));
    } else {
      if (storagePath != null) {
        Hive.init(storagePath);
      } else if (!_kIsWeb) PersistenceStorage.setupMemoryStorage();

      initPlatform(platform);
      FirebaseImplementation.install(PureDartFirebaseImplementation(
          launchUrl: launchUrl,
          getAuthResult: getAuthResult,
          oauthSignIn: oauthSignIn,
          oauthSignOut: oauthSignOut,
          httpClient: httpClient));
    }
  }
}
