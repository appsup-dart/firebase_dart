import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/service.dart';
import 'package:http/http.dart' as http;

import '../implementation.dart';

class PureDartFirebaseImplementation extends FirebaseImplementation {
  final http.Client _httpClient;

  PureDartFirebaseImplementation.withHttpClient(this._httpClient);

  PureDartFirebaseImplementation() : _httpClient = null;

  @override
  FirebaseDatabase createDatabase(FirebaseApp app, {String databaseURL}) {
    return FirebaseDatabaseImpl(app: app, databaseURL: databaseURL);
  }

  @override
  Future<FirebaseApp> createApp(String name, FirebaseOptions options) async {
    return FirebaseAppImpl(name, options);
  }

  @override
  FirebaseAuth createAuth(FirebaseApp app) {
    return FirebaseAuthImpl(app, httpClient: _httpClient);
  }

  @override
  FirebaseStorage createStorage(FirebaseApp app, {String storageBucket}) {
    return FirebaseStorageImpl(app, storageBucket, httpClient: _httpClient);
  }
}
