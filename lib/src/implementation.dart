import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/storage.dart';

abstract class FirebaseImplementation {
  static FirebaseImplementation _installation;

  static FirebaseImplementation get installation {
    assert(_installation != null, 'No firebase implementation has been setup.');
    return _installation;
  }

  static void install(FirebaseImplementation value) {
    assert(_installation == null,
        'A firebase implementation has already been setup.');
    _installation = value;
  }

  Future<FirebaseApp> createApp(String name, FirebaseOptions options);

  FirebaseDatabase createDatabase(FirebaseApp app, {String databaseURL});

  FirebaseAuth createAuth(FirebaseApp app);

  FirebaseStorage createStorage(FirebaseApp app, {String storageBucket});
}
