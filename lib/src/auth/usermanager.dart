import 'dart:async';

import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/user.dart';
import 'package:hive/hive.dart';

import 'impl/user.dart';

/// Defines the Auth user storage manager.
///
/// It provides methods to store, load and delete an authenticated current user.
/// It also provides methods to listen to external user changes (updates, sign
/// in, sign out, etc.)
class UserManager {
  final FirebaseAuthImpl auth;

  /// The Auth state's application ID
  String get appId => auth.app.options.appId;

  /// The underlying storage manager.
  final FutureOr<Box> storage;

  Stream<FirebaseUser> get onCurrentUserChanged {
    return Stream.fromFuture(Future.value(storage))
        .asyncExpand((event) async* {
          yield* event.watch(key: _key).map((v) => v?.value);
        })
        .distinct()
        .cast<Map>()
        .map((v) =>
            v == null ? null : FirebaseUserImpl.fromJson(v.cast(), auth: auth));
  }

  UserManager(this.auth, [FutureOr<Box> storage])
      : storage = storage ?? Hive.openBox('firebase_auth');

  String get _key => 'firebase:FirebaseUser:$appId';

  /// Stores the current Auth user for the provided application ID.
  Future<void> setCurrentUser(FirebaseUser currentUser) async {
    // Wait for any pending persistence change to be resolved.
    await (await storage).put(_key, currentUser?.toJson());
  }

  /// Removes the stored current user for provided app ID.
  Future<void> removeCurrentUser() async {
    await (await storage).delete(_key);
  }

  Future<FirebaseUser> getCurrentUser([String authDomain]) async {
    var response = await (await storage).get(_key);

    return response == null
        ? null
        : FirebaseUserImpl.fromJson({
            ...response,
            if (authDomain != null) 'authDomain': authDomain,
          }, auth: auth);
  }
}
