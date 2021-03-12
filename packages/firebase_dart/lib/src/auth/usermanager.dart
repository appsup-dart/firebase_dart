import 'dart:async';

import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/user.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
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

  final StreamController<FirebaseUserImpl?> _controller =
      StreamController.broadcast();

  late StreamSubscription _subscription;

  Future<void>? _onReady;

  Future<void>? get onReady => _onReady;

  Stream<FirebaseUserImpl?> get onCurrentUserChanged => _controller.stream;

  UserManager(this.auth, [FutureOr<Box>? storage])
      : storage = storage ?? PersistenceStorage.openBox('firebase_auth') {
    _onReady = _init();
  }

  Future<void> _init() async {
    var storage = await this.storage;

    _subscription = storage
        .watch(key: _key)
        .map((v) => v.value)
        .distinct()
        .cast<Map?>()
        .map((v) =>
            v == null ? null : FirebaseUserImpl.fromJson(v.cast(), auth: auth))
        .listen(_controller.add);
  }

  String get _key => 'firebase:FirebaseUser:$appId';

  /// Stores the current Auth user for the provided application ID.
  Future<void> setCurrentUser(User? currentUser) async {
    await onReady;
    // Wait for any pending persistence change to be resolved.
    await (await storage).put(_key, currentUser?.toJson());
  }

  /// Removes the stored current user for provided app ID.
  Future<void> removeCurrentUser() async {
    await onReady;
    await (await storage).delete(_key);
  }

  Future<FirebaseUserImpl?> getCurrentUser([String? authDomain]) async {
    await onReady;
    var response = await (await storage).get(_key);

    return response == null
        ? null
        : FirebaseUserImpl.fromJson({
            ...response,
            if (authDomain != null) 'authDomain': authDomain,
          }, auth: auth);
  }

  Future<void> close() async {
    await onReady;
    await _subscription.cancel();
    await _controller.close();
  }
}
