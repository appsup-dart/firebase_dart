library firebase_dart.auth;

import 'package:firebase_dart/core.dart';

import 'impl/auth.dart';

import 'user.dart';

export 'user.dart';

/// The entry point of the Firebase Authentication SDK.
abstract class FirebaseAuth {
  FirebaseAuth();

  /// Provides an instance of this class corresponding to `app`.
  factory FirebaseAuth.fromApp(FirebaseApp app) {
    assert(app != null);
    return FirebaseAuthImpl(
      app.options.apiKey,
    );
  }

  /// Receive [FirebaseUser] each time the user signIn or signOut
  Stream<FirebaseUser> get onAuthStateChanged;

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// Errors:
  ///
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Anonymous accounts are not enabled.
  Future<AuthResult> signInAnonymously();

  /// Returns the currently signed-in [FirebaseUser] or [null] if there is none.
  Future<FirebaseUser> currentUser();
}

/// Result object obtained from operations that can affect the authentication
/// state. Contains a method that returns the currently signed-in user after
/// the operation has completed.
abstract class AuthResult {
  /// Returns the currently signed-in [FirebaseUser], or `null` if there isn't
  /// any (i.e. the user is signed out).
  FirebaseUser get user;

  /// Returns IDP-specific information for the user if the provider is one of
  /// Facebook, Github, Google, or Twitter.
  AdditionalUserInfo get additionalUserInfo;
}
