import 'dart:math';

import 'package:firebase_dart/src/auth/error.dart';
import 'package:jose/jose.dart';

import 'backend.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';

class MemoryBackend extends BaseBackend {
  MemoryBackend({JsonWebKey tokenSigningKey, String projectId})
      : super(tokenSigningKey: tokenSigningKey, projectId: projectId);

  final Map<String, UserInfo> _users = {};

  @override
  Future<UserInfo> getUserById(String uid) async => _users[uid];

  @override
  Future<UserInfo> storeUser(UserInfo user) async =>
      _users[user.localId] = user;

  @override
  Future<UserInfo> getUserByEmail(String email) async {
    return _users.values
        .firstWhere((user) => user.email == email, orElse: () => null);
  }

  @override
  Future<UserInfo> getUserByPhoneNumber(String phoneNumber) async {
    return _users.values.firstWhere((user) => user.phoneNumber == phoneNumber,
        orElse: () => null);
  }

  @override
  Future<void> deleteUser(String uid) async {
    assert(uid != null);
    print('delete user $uid');
    _users.remove(uid);
  }

  final Map<String, Future<String>> _smsCodes = {};

  Future<String> receiveSmsCode(String phoneNumber) => _smsCodes[phoneNumber];

  @override
  Future<String> sendVerificationCode(String phoneNumber) async {
    var user = await getUserByPhoneNumber(phoneNumber);
    if (user == null) {
      throw AuthException.userDeleted();
    }

    var max = 100000;
    var code = (Random.secure().nextInt(max) + max).toString().substring(1);
    _smsCodes[phoneNumber] = Future.value(code);
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = user.phoneNumber
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<UserInfo> verifyPhoneNumber(String sessionInfo, String code) async {
    var s = JsonWebSignature.fromCompactSerialization(sessionInfo);

    var phoneNumber = s.unverifiedPayload.jsonContent;

    var v = await _smsCodes.remove(phoneNumber);
    if (v != code) {
      throw AuthException.invalidCode();
    }
    return getUserByPhoneNumber(phoneNumber);
  }
}
