import 'dart:math';

import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/util/store.dart';
import 'package:firebaseapis/identitytoolkit/v1.dart';
import 'package:jose/jose.dart';
import 'package:openid_client/openid_client.dart';
import 'package:collection/collection.dart';

import 'backend.dart';

class StoreBackend extends BaseBackend {
  final Store<String, BackendUser> users;

  final Store<String, String> smsCodes;

  final Store<String, dynamic> settings;

  StoreBackend(
      {required String projectId,
      Store<String, BackendUser>? users,
      Store<String, String>? smsCodes,
      Store<String, dynamic>? settings})
      : users = users ?? MemoryStore(),
        smsCodes = smsCodes ?? MemoryStore(),
        settings = settings ?? MemoryStore(),
        super(projectId: projectId);

  @override
  Future<BackendUser> getUserById(String uid) async {
    var user = await users.get(uid);

    if (user == null) {
      throw FirebaseAuthException.userDeleted();
    }
    return user;
  }

  @override
  Future<BackendUser> storeUser(BackendUser user) async {
    if (user.rawPassword != null) {
      var providerUserInfo = user.providerUserInfo ??= [];
      var info = providerUserInfo
          .firstWhereOrNull((element) => element.providerId == 'password');

      if (info == null) {
        info = GoogleCloudIdentitytoolkitV1ProviderUserInfo()
          ..providerId = 'password';
        providerUserInfo.add(info);
      }

      info.displayName = user.displayName;
      info.photoUrl = user.photoUrl;
      info.email = user.email;
      info.rawId = user.email;
    }
    return await users.set(user.localId, user);
  }

  @override
  Future<BackendUser> getUserByEmail(String? email) async {
    return users.values.firstWhere((user) => user.email == email,
        orElse: () => throw FirebaseAuthException.userDeleted());
  }

  @override
  Future<BackendUser> getUserByPhoneNumber(String phoneNumber) async {
    return users.values.firstWhere((user) => user.phoneNumber == phoneNumber,
        orElse: () => throw FirebaseAuthException.userDeleted());
  }

  @override
  Future<void> deleteUser(String uid) async {
    await users.remove(uid);
  }

  @override
  Future<String?> receiveSmsCode(String phoneNumber) {
    return smsCodes.get(phoneNumber);
  }

  @override
  Future<String> sendVerificationCode(String phoneNumber, {String? uid}) async {
    var max = 100000;
    var code = (Random.secure().nextInt(max) + max).toString().substring(1);
    await smsCodes.set(phoneNumber, code);
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = {if (uid != null) 'uid': uid, 'phoneNumber': phoneNumber}
      ..addRecipient(await getTokenSigningKey());
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> signInWithPhoneNumber(String sessionInfo, String code) async {
    var s = JsonWebSignature.fromCompactSerialization(sessionInfo);

    var phoneNumber = s.unverifiedPayload.jsonContent['phoneNumber'];

    var v = await smsCodes.remove(phoneNumber);
    if (v != code) {
      throw FirebaseAuthException.invalidCode();
    }
    return phoneNumber;
  }

  @override
  Future<BackendUser> signInWithIdp(String providerId, String idToken) async {
    var s = IdToken.unverified(idToken);
    var rawId = s.claims.subject;
    var email = s.claims['email'];
    if (email != null) {
      try {
        var user = await getUserByEmail(email);
        if ((user.providerUserInfo ?? [])
            .any((v) => v.providerId == providerId && v.rawId == rawId)) {
          return user;
        } else {
          throw FirebaseAuthException.needConfirmation();
        }
        // ignore: empty_catches
      } on FirebaseAuthException catch (e) {
        if (e.code != FirebaseAuthException.userDeleted().code) {
          rethrow;
        }
      }
    }
    return getUserByProvider(providerId, rawId);
  }

  @override
  Future<BackendUser> getUserByProvider(String providerId, String rawId) {
    return users.values.firstWhere(
        (user) => (user.providerUserInfo ?? [])
            .any((v) => v.providerId == providerId && v.rawId == rawId),
        orElse: () => throw FirebaseAuthException.userDeleted());
  }

  @override
  Future<Duration> getTokenExpiresIn() async =>
      await settings.get('tokenExpiresIn');

  @override
  Future<JsonWebKey> getTokenSigningKey() async =>
      await settings.get('tokenSigningKey');

  @override
  Future<void> setTokenGenerationSettings(
      {Duration? tokenExpiresIn, JsonWebKey? tokenSigningKey}) async {
    if (tokenExpiresIn != null) {
      await settings.set('tokenExpiresIn', tokenExpiresIn);
    }
    if (tokenSigningKey != null) {
      await settings.set('tokenSigningKey', tokenSigningKey);
    }
  }
}
