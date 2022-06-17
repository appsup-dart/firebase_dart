import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/implementation/testing.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/implementation/testing_no_isolate.dart'
    if (dart.library.isolate) 'package:firebase_dart/src/implementation/testing_isolate.dart';

export 'package:firebase_dart/src/auth/backend/backend.dart' show BackendUser;

class FirebaseTesting {
  /// Initializes the pure dart firebase implementation for testing purposes.
  static Future<void> setup({bool isolated = false}) async {
    FirebaseDart.setup(
        isolated: isolated,
        platform: Platform.web(
            currentUrl: 'http://localhost', isMobile: true, isOnline: true),
        applicationVerifier: DummyApplicationVerifier(),
        httpClient: createHttpClient());
  }

  static Backend getBackend(FirebaseOptions options) => BackendImpl(options);
}

abstract class Backend {
  auth.AuthBackend get authBackend;
  storage.StorageBackend get storageBackend;
}
