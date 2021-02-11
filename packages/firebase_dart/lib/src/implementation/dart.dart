import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/service.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../implementation.dart';

class PureDartFirebaseImplementation extends FirebaseImplementation {
  final http.Client _httpClient;

  final Function(Uri url) launchUrl;

  final Future<Map<String, dynamic>> Function() getAuthResult;

  final Future<OAuthCredential> Function(OAuthProvider provider) oauthSignIn;

  final Future<void> Function(String providerId) oauthSignOut;

  PureDartFirebaseImplementation.withHttpClient(this._httpClient,
      {this.launchUrl,
      this.getAuthResult,
      this.oauthSignIn,
      this.oauthSignOut});

  PureDartFirebaseImplementation(
      {@required this.launchUrl,
      @required this.getAuthResult,
      this.oauthSignIn,
      this.oauthSignOut})
      : _httpClient = null;

  static PureDartFirebaseImplementation get installation =>
      FirebaseImplementation.installation;
  @override
  FirebaseDatabase createDatabase(FirebaseApp app, {String databaseURL}) {
    return FirebaseService.findService<FirebaseDatabaseImpl>(
            app,
            (s) =>
                s.databaseURL ==
                FirebaseDatabaseImpl.normalizeUrl(
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
  FirebaseStorage createStorage(FirebaseApp app, {String storageBucket}) {
    return FirebaseService.findService<FirebaseStorageImpl>(
            app,
            (s) =>
                s.storageBucket == storageBucket ??
                app.options.storageBucket) ??
        FirebaseStorageImpl(app, storageBucket, httpClient: _httpClient);
  }
}
