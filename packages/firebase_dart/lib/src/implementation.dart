import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/firestore.dart';
import 'package:firebase_dart/storage.dart';

abstract class FirebaseImplementation {
  static FirebaseImplementation? _installation;

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
      {String? databaseURL});

  FirebaseAuth createAuth(covariant FirebaseApp app);

  FirebaseStorage createStorage(covariant FirebaseApp app,
      {String? storageBucket});

  FirebaseFirestore createFirestore(covariant FirebaseApp app);
}

abstract class BaseFirebaseImplementation extends FirebaseImplementation {
  final Function(Uri url, {bool popup}) launchUrl;

  BaseFirebaseImplementation({required this.launchUrl});
}

abstract class AuthTokenProvider {
  Future<String?> getToken([bool fordeRefresh = false]);

  Stream<Future<String>?> get onTokenChanged;

  factory AuthTokenProvider.fromFirebaseAuth(FirebaseAuth auth) =>
      _AuthTokenProviderFromFirebaseAuth(auth);
}

class _AuthTokenProviderFromFirebaseAuth implements AuthTokenProvider {
  final FirebaseAuth auth;

  _AuthTokenProviderFromFirebaseAuth(this.auth);

  @override
  Future<String?> getToken([bool forceRefresh = false]) async {
    var user = await auth.authStateChanges().first;
    if (user == null) return null;

    var token = await user.getIdToken(forceRefresh);
    return token;
  }

  @override
  Stream<Future<String>?> get onTokenChanged =>
      auth.idTokenChanges().map((event) => event?.getIdToken());
}
