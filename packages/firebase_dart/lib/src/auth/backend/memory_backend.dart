import 'dart:math';

import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/implementation/isolate/store.dart';
import 'package:jose/jose.dart';

import 'backend.dart';

class StoreBackend extends BaseBackend {
  final Store<String, BackendUser> users;

  final Store<String, String> smsCodes;

  StoreBackend(
      {required JsonWebKey tokenSigningKey,
      required String projectId,
      Store<String, BackendUser>? users,
      Store<String, String>? smsCodes})
      : users = users ?? MemoryStore(),
        smsCodes = smsCodes ?? MemoryStore(),
        super(tokenSigningKey: tokenSigningKey, projectId: projectId);

  @override
  Future<BackendUser> getUserById(String uid) async {
    var user = await users.get(uid);

    if (user == null) {
      throw FirebaseAuthException.userDeleted();
    }
    return user;
  }

  @override
  Future<BackendUser> storeUser(BackendUser user) async =>
      await users.set(user.localId, user);

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
  Future<String> sendVerificationCode(String phoneNumber) async {
    var user = await getUserByPhoneNumber(phoneNumber);

    var max = 100000;
    var code = (Random.secure().nextInt(max) + max).toString().substring(1);
    await smsCodes.set(phoneNumber, code);
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = user.phoneNumber
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<BackendUser> verifyPhoneNumber(String sessionInfo, String code) async {
    var s = JsonWebSignature.fromCompactSerialization(sessionInfo);

    var phoneNumber = s.unverifiedPayload.jsonContent;

    var v = await smsCodes.remove(phoneNumber);
    if (v != code) {
      throw FirebaseAuthException.invalidCode();
    }
    return getUserByPhoneNumber(phoneNumber);
  }
}
