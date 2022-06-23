import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/service.dart';
import 'package:http/http.dart' as http;

import '../implementation.dart';

class PureDartFirebaseImplementation extends BaseFirebaseImplementation {
  final http.Client? _httpClient;

  final AuthHandler authHandler;

  final ApplicationVerifier applicationVerifier;

  final SmsRetriever smsRetriever;

  PureDartFirebaseImplementation(
      {required Function(Uri url, {bool popup}) launchUrl,
      required this.authHandler,
      required this.applicationVerifier,
      required this.smsRetriever,
      http.Client? httpClient})
      : _httpClient = httpClient,
        super(launchUrl: launchUrl);

  static PureDartFirebaseImplementation get installation =>
      FirebaseImplementation.installation as PureDartFirebaseImplementation;
  @override
  FirebaseDatabase createDatabase(FirebaseApp app, {String? databaseURL}) {
    return FirebaseService.findService<FirebaseDatabaseImpl>(
            app,
            (s) =>
                s.databaseURL ==
                BaseFirebaseDatabase.normalizeUrl(
                    databaseURL ?? app.options.databaseURL)) ??
        FirebaseDatabaseImpl(app: app, databaseURL: databaseURL);
  }

  @override
  Future<FirebaseApp> createApp(String name, FirebaseOptions options) async {
    return FirebaseAppImpl(name, options);
  }

  @override
  FirebaseAuth createAuth(FirebaseApp app) {
    return FirebaseService.findService<FirebaseAuthImpl>(app) ??
        FirebaseAuthImpl(app, httpClient: _httpClient);
  }

  @override
  FirebaseStorage createStorage(FirebaseApp app, {String? storageBucket}) {
    return FirebaseService.findService<FirebaseStorageImpl>(app,
            (s) => s.bucket == (storageBucket ?? app.options.storageBucket)) ??
        FirebaseStorageImpl(app, storageBucket, httpClient: _httpClient);
  }
}
