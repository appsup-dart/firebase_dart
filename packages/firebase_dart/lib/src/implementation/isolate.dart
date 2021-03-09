import 'dart:async';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import 'isolate/auth.dart';
import 'isolate/database.dart';
import 'isolate/storage.dart';
import 'isolate/util.dart';

class IsolateFirebaseImplementation extends FirebaseImplementation {
  final String storagePath;
  final Platform platform;

  final Function(Uri url) launchUrl;

  final Future<Map<String, dynamic>> Function() getAuthResult;

  final Future<OAuthCredential> Function(OAuthProvider provider) oauthSignIn;

  final Future<void> Function(String providerId) oauthSignOut;

  final http.Client httpClient;

  Future<IsolateCommander> _commander;

  Future<IsolateCommander> get commander => _commander ??= _setup();

  IsolateFirebaseImplementation(
      {@required this.storagePath,
      @required this.platform,
      @required this.launchUrl,
      @required this.getAuthResult,
      @required this.oauthSignIn,
      @required this.oauthSignOut,
      this.httpClient})
      : assert(platform != null);

  Future<IsolateCommander> _setup() async {
    var worker = IsolateWorker()
      ..registerFunction(#oauthSignOut, oauthSignOut)
      ..registerFunction(#oauthSignIn, oauthSignIn)
      ..registerFunction(#launchUrl, launchUrl)
      ..registerFunction(#getAuthResult, getAuthResult);

    var commander = await IsolateWorker.startWorkerInIsolate();

    await commander.execute(StaticFunctionCall(_setupInIsolate,
        [storagePath, platform, worker.commander, httpClient]));

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
    String storagePath,
    Platform platform,
    IsolateCommander commander,
    http.Client httpClient,
  ) async {
    _registerFunctions();
    FirebaseDart.setup(
        storagePath: storagePath,
        platform: platform,
        oauthSignOut: (providerId) {
          return commander
              .execute(RegisteredFunctionCall(#oauthSignOut, [providerId]));
        },
        oauthSignIn: (providerId) {
          return commander
              .execute(RegisteredFunctionCall(#oauthSignIn, [providerId]));
        },
        launchUrl: (url) {
          return commander.execute(RegisteredFunctionCall(#launchUrl, [url]));
        },
        getAuthResult: () {
          return commander.execute(RegisteredFunctionCall(#getAuthResult));
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
  FirebaseAuth createAuth(FirebaseApp app) {
    return FirebaseService.findService<IsolateFirebaseAuth>(app) ??
        IsolateFirebaseAuth(app);
  }

  @override
  FirebaseDatabase createDatabase(FirebaseApp app, {String databaseURL}) {
    databaseURL = FirebaseDatabaseImpl.normalizeUrl(
        databaseURL ?? app.options.databaseURL);
    return FirebaseService.findService<IsolateFirebaseDatabase>(
            app, (s) => s.databaseURL == databaseURL) ??
        IsolateFirebaseDatabase(app: app, databaseURL: databaseURL);
  }

  @override
  FirebaseStorage createStorage(FirebaseApp app, {String storageBucket}) {
    return FirebaseService.findService<IsolateFirebaseStorage>(
            app, (s) => s.storageBucket == storageBucket) ??
        IsolateFirebaseStorage(app: app, storageBucket: storageBucket);
  }
}

class IsolateFirebaseApp extends FirebaseApp {
  final IsolateCommander commander;

  IsolateFirebaseApp(String name, FirebaseOptions options, this.commander)
      : super(name, options);

  @override
  Future<void> delete() async {
    await commander.execute(RegisteredFunctionCall(#app.delete, [name]));
    return super.delete();
  }
}

abstract class IsolateFirebaseService extends FirebaseService {
  IsolateFirebaseService(IsolateFirebaseApp app) : super(app);

  @override
  IsolateFirebaseApp get app => super.app;
}
