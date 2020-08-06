library fireauth.credentials;

import 'package:collection/collection.dart';

/// Represents [AuthCredential] from Firebase.
abstract class AuthCredential {
  // TODO use snapshot

  /// An id that identifies the specific type of provider.
  String get providerId;

  Map<String, dynamic> toJson();

  @override
  int get hashCode => MapEquality().hash(toJson());

  @override
  bool operator ==(other) =>
      other is AuthCredential && MapEquality().equals(toJson(), other.toJson());
}
