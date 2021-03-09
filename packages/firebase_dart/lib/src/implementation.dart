import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/storage.dart';

abstract class FirebaseImplementation {
  static FirebaseImplementation _installation;

  static FirebaseImplementation get installation {
    var i = _installation;
    if (i == null) {
      throw FirebaseCoreException.noSetup();
    }
    return i;
  }

  static void install(FirebaseImplementation value) {
    assert(_installation == null,
        'A firebase implementation has already been setup.');
    _installation = value;
  }

  Future<FirebaseApp> createApp(String name, FirebaseOptions options);

  FirebaseDatabase createDatabase(covariant FirebaseApp app,
      {String databaseURL});

  FirebaseAuth createAuth(covariant FirebaseApp app);

  FirebaseStorage createStorage(covariant FirebaseApp app,
      {String storageBucket});
}
