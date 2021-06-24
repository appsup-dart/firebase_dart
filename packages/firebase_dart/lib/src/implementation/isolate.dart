import 'dart:async';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:http/http.dart' as http;

import 'isolate/auth.dart';
import 'isolate/database.dart';
import 'isolate/storage.dart';
import 'isolate/util.dart';

class IsolateFirebaseImplementation extends FirebaseImplementation {
  final String? storagePath;
  final Platform platform;

  final Function(Uri url, {bool popup}) launchUrl;

  final AuthHandler authHandler;

  final http.Client? httpClient;

  Future<IsolateCommander>? _commander;

  Future<IsolateCommander> get commander => _commander ??= _setup();

  IsolateFirebaseImplementation(
      {required this.storagePath,
      required this.platform,
      required this.launchUrl,
      required this.authHandler,
      this.httpClient});

  Future<IsolateCommander> _setup() async {
    var worker = IsolateWorker()..registerFunction(#launchUrl, launchUrl);
    var commander =
        await IsolateWorker.startWorkerInIsolate(debugName: 'firebase');

    await commander.execute(StaticFunctionCall(_setupInIsolate, [
      storagePath,
      platform,
      worker.commander,
      IsolateAuthHandler.from(authHandler),
      httpClient
    ]));

    return commander;
  }

  static void _registerFunctions() {
    IsolateWorker.current
      ..registerFunction(#createApp,
          (String name, FirebaseOptions options) async {
        await Firebase.initializeApp(name: name, options: options);
      })
      ..registerFunction(#app.delete, (String name) {
        return Firebase.app(name).delete();
      });
  }

  static Future<void> _setupInIsolate(
    String? storagePath,
    Platform? platform,
    IsolateCommander commander,
    AuthHandler authHandler,
    http.Client? httpClient,
  ) async {
    _registerFunctions();
    FirebaseDart.setup(
        storagePath: storagePath,
        platform: platform,
        authHandler: authHandler,
        launchUrl: (url, {bool popup = false}) {
          return commander.execute(
              RegisteredFunctionCall(#launchUrl, [url], {#popup: popup}));
        },
        httpClient: httpClient);
  }

  @override
  Future<FirebaseApp> createApp(String name, FirebaseOptions options) async {
    var commander = await this.commander;
    var app = IsolateFirebaseApp(name, options, commander);

    await commander
        .execute(RegisteredFunctionCall(#createApp, [name, options]));

    return app;
  }

  @override
  FirebaseAuth createAuth(IsolateFirebaseApp app) {
    return FirebaseService.findService<IsolateFirebaseAuth>(app) ??
        IsolateFirebaseAuth(app);
  }

  @override
  FirebaseDatabase createDatabase(IsolateFirebaseApp app,
      {String? databaseURL}) {
    databaseURL = FirebaseDatabaseImpl.normalizeUrl(
        databaseURL ?? app.options.databaseURL);
    return FirebaseService.findService<IsolateFirebaseDatabase>(
            app, (s) => s.databaseURL == databaseURL) ??
        IsolateFirebaseDatabase(app: app, databaseURL: databaseURL);
  }

  @override
  FirebaseStorage createStorage(IsolateFirebaseApp app,
      {String? storageBucket}) {
    return FirebaseService.findService<IsolateFirebaseStorage>(
            app, (s) => s.bucket == storageBucket) ??
        IsolateFirebaseStorage(app: app, storageBucket: storageBucket);
  }

  @override
  AuthTokenProvider createAuthTokenProvider(IsolateFirebaseApp app) {
    return AuthTokenProvider.fromFirebaseAuth(createAuth(app));
  }
}

class IsolateFirebaseApp extends FirebaseApp {
  final IsolateCommander commander;

  IsolateFirebaseApp(String name, FirebaseOptions options, this.commander)
      : super(name, options);

  @override
  Future<void> delete() async {
    await commander.execute(RegisteredFunctionCall(#app.delete, [name]));
    await super.delete();
    await FirebaseService.deleteAllForApp(this);
  }
}

abstract class IsolateFirebaseService extends FirebaseService {
  IsolateFirebaseService(IsolateFirebaseApp app) : super(app);

  @override
  IsolateFirebaseApp get app => super.app as IsolateFirebaseApp;
}

class IsolateAuthHandler implements AuthHandler {
  late final IsolateCommander _commander;

  IsolateAuthHandler.from(AuthHandler authHandler) {
    var worker = IsolateWorker()
      ..registerFunction(#getSignInResult, (String appName) {
        var app = Firebase.app(appName);
        return authHandler.getSignInResult(app);
      })
      ..registerFunction(#signIn, (String appName, AuthProvider provider,
          {bool isPopup = false}) {
        var app = Firebase.app(appName);
        return authHandler.signIn(app, provider, isPopup: isPopup);
      })
      ..registerFunction(#signOut, (String appName, String uid) {
        var app = Firebase.app(appName);
        var user = FirebaseAuth.instanceFor(app: app).currentUser;
        assert(user?.uid == uid);
        return authHandler.signOut(app, user!);
      });

    _commander = worker.commander;
  }

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) {
    return _commander
        .execute(RegisteredFunctionCall(#getSignInResult, [app.name]));
  }

  @override
  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false}) {
    return _commander.execute(RegisteredFunctionCall(
        #signIn, [app.name, provider], {#isPopup: isPopup}));
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) {
    return _commander
        .execute(RegisteredFunctionCall(#signOut, [app.name, user.uid]));
  }
}
