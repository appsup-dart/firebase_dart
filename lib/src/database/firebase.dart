// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

/// A Firebase reference represents a particular location in your database and
/// can be used for reading or writing data to that database location.
@deprecated
abstract class Firebase implements DatabaseReference {
  /// Construct a Firebase reference from a full Firebase URL.
  factory Firebase(String url) {
    var uri = Uri.parse(url);
    return Firebase._(
        FirebaseDatabase(databaseURL: uri.replace(pathSegments: []).toString()),
        uri.pathSegments.map(Uri.decodeComponent).toList());
  }

  factory Firebase._(FirebaseDatabase db, List<String> path) =>
      FirebaseImpl(db, path);

  @deprecated
  Future<Map> authWithCustomToken(String token);

  /// Authenticates a Firebase client using an authentication token or Firebase
  /// Secret.
  /// Takes a single token as an argument and returns a Future that will be
  /// resolved when the authentication succeeds (or fails).
  Future<Map> authenticate(FutureOr<String> token);

  /// Synchronously retrieves the current authentication state of the client.
  dynamic get auth;

  /// Listens for changes to the client's authentication state.
  Stream<Map> get onAuth;

  /// Unauthenticates a Firebase client (i.e. logs out).
  Future unauth();
}
