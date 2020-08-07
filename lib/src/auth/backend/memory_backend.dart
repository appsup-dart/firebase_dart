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
  Future<void> deleteUser(String uid) async {
    assert(uid != null);
    print('delete user $uid');
    _users.remove(uid);
  }
}
