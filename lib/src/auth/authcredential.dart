library fireauth.credentials;

import 'package:collection/collection.dart';
import 'package:firebase_dart/src/auth/auth.dart';

import 'package:meta/meta.dart';

part 'authcredentials/oauth.dart';
part 'authcredentials/facebook.dart';
part 'authcredentials/github.dart';
part 'authcredentials/google.dart';
part 'authcredentials/twitter.dart';
part 'authcredentials/email.dart';
part 'authcredentials/phone.dart';
part 'authcredentials/saml.dart';

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
