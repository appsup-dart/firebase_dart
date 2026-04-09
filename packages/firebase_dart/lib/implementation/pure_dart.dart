import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/iframeclient/auth_methods.dart';
import 'package:firebase_dart/src/auth/sms_retriever.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/implementation/pure_dart_setup_web.dart'
    if (dart.library.io) 'package:firebase_dart/src/implementation/pure_dart_setup_io.dart'
    if (dart.library.js_interop) 'package:firebase_dart/src/implementation/pure_dart_setup_web.dart';
import 'package:http/http.dart' as http;

import 'package:meta/meta.dart';

import '../src/core.dart';

export 'package:firebase_dart/src/auth/utils.dart'
    show
        Platform,
        AndroidPlatform,
        IOsPlatform,
        LinuxPlatform,
        MacOsPlatform,
        WindowsPlatform,
        WebPlatform;
export 'package:firebase_dart/src/auth/authhandlers.dart'
    show FirebaseAppAuthHandler;
export 'package:firebase_dart/src/auth/sms_retriever.dart' show SmsRetriever;
export 'package:firebase_dart/src/auth/app_verifier.dart'
    show
        ApplicationVerificationResult,
        RecaptchaApplicationVerifier,
        ApplicationVerifier,
        BaseApplicationVerifier;

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
  /// An [authHandler] can be spedified to handle auth requests with
  /// [FirebaseAuth.signInWithRedirect] and [FirebaseAuth.signInWithPopup]. When
  /// omitted, a default implementation will be used in a web context. On other
  /// platforms no default implementation is provided. On flutter, use the
  /// `firebase_dart_flutter` package with `FirebaseDartFlutter.setup` instead.
  ///
  /// Several firebase methods might need to launch an external url. Set the
  /// [launchUrl] parameter to handle these. When omitted, a default
  /// implementation will be used in a web context. On flutter, use the
  /// `firebase_dart_flutter` package with `FirebaseDartFlutter.setup` instead.
  ///
  /// When [isolated] is true, all operations will run in a separate isolate.
  /// Isolates are not supported on web.
  ///
  /// A custom [httpClient] can be specified to handle all http requests. This
  /// can be usefull for testing purposes, but is generally unnecessary.
  ///
  static void setup(
      {String? storagePath,
      Platform? platform,
      bool isolated = false,
      Function(Uri url, {bool popup})? launchUrl,
      AuthHandler? authHandler,
      ApplicationVerifier? applicationVerifier,
      SmsRetriever? smsRetriever,
      http.Client? httpClient}) {
    baseUrl = Uri.base;

    setupPureDartImplementation(
      authHandler: authHandler ?? DefaultAuthHandler(),
      applicationVerifier:
          applicationVerifier ?? RecaptchaApplicationVerifier(),
      smsRetriever: smsRetriever ?? DummySmsRetriever(),
      launchUrl: launchUrl ?? _defaultLaunchUrl,
      platform: platform,
      httpClient: httpClient,
      isolated: isolated,
      storagePath: storagePath,
    );

    if (_keepQueriesSyncedDuration != null) {
      updateDatabaseConfiguration(
          keepQueriesSyncedDuration: _keepQueriesSyncedDuration);
    }
  }

  final PureDartFirebaseImplementation _installation;

  FirebaseDart(this._installation);

  /// Returns the current [FirebaseDart] instance representing the setup that was
  /// configured via [FirebaseDart.setup].
  ///
  /// This instance contains the details of the current Firebase implementation,
  /// including handlers, clients, and configuration resulting from the setup
  /// process.
  static FirebaseDart get instance =>
      FirebaseDart(PureDartFirebaseImplementation.installation);

  /// Opens the given [url] in a browser context.
  ///
  /// This can be used to implement [AuthHandler]s or [ApplicationVerifier]s
  /// when they need to open an URL in a browser for sign in, reCAPTCHA, or
  /// other purposes.
  ///
  /// Override this handler in [setup] using the [launchUrl] parameter if your
  /// application requires custom UI or navigation.
  void launchUrl(Uri url, {bool popup = false}) {
    _installation.launchUrl(url, popup: popup);
  }

  static void _defaultLaunchUrl(Uri uri, {bool popup = false}) {
    if (_kIsWeb) {
      webLaunchUrl(uri, popup: popup);
    } else {
      throw UnsupportedError('Social sign in not supported on this platform.');
    }
  }

  static late final Uri baseUrl;

  static Duration? _keepQueriesSyncedDuration;

  /// Updates global database configurations and optimization settings.
  ///
  /// The [keepQueriesSyncedDuration] parameter can be used to specify how long
  /// queries should be kept in sync. This can be useful to reduce the number of
  /// queries made to the server. The default value is 2 seconds.
  static void updateDatabaseConfiguration(
      {Duration? keepQueriesSyncedDuration}) {
    _keepQueriesSyncedDuration = keepQueriesSyncedDuration;
    try {
      FirebaseImplementation.installation.updateDatabaseConfiguration(
          keepQueriesSyncedDuration: keepQueriesSyncedDuration);
    } on FirebaseCoreException {
      // ignore
    }
  }
}

abstract class AuthHandler {
  const factory AuthHandler() = DefaultAuthHandler;

  const factory AuthHandler.from(List<AuthHandler> handlers) = MultiAuthHandler;

  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false});

  Future<AuthCredential?> getSignInResult(FirebaseApp app);

  Future<void> signOut(FirebaseApp app, User user);
}

abstract class DirectAuthHandler<T extends AuthProvider>
    implements AuthHandler {
  final String providerId;

  final Map<String, AuthCredential> _authCredentials = {};

  DirectAuthHandler(this.providerId);

  @visibleForOverriding
  Future<AuthCredential?> directSignIn(FirebaseApp app, T provider);

  @override
  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false}) async {
    if (provider is! T) return false;
    if (provider.providerId != providerId) return false;
    var credential = await directSignIn(app, provider);
    if (credential == null) return false;
    _authCredentials[app.name] = credential;
    return true;
  }

  @override
  Future<void> signOut(FirebaseApp app, User user);

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    return _authCredentials.remove(app.name);
  }
}

class MultiAuthHandler implements AuthHandler {
  final List<AuthHandler> authHandlers;

  const MultiAuthHandler(this.authHandlers);

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    for (var h in authHandlers) {
      var v = await h.getSignInResult(app);
      if (v != null) return v;
    }
    return null;
  }

  @override
  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false}) async {
    for (var h in authHandlers) {
      if (await h.signIn(app, provider, isPopup: isPopup)) return true;
    }
    return false;
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    for (var h in authHandlers) {
      await h.signOut(app, user);
    }
  }
}
