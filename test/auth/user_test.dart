import 'dart:io';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'auth_test.dart';
import 'jwt_util.dart';
import 'util.dart';

void main() async {
  Hive.init(Directory.systemTemp.path);
  var box = await Hive.openBox('firebase_auth');

  var app = await Firebase.initializeApp(options: getOptions());
  var tester = Tester(app);
  var auth = tester.auth;

  setUp(() async {
    await box.clear();
    tester.connect();
  });

  group('FirebaseUserImpl', () {
    var uid = 'defaultUserId';
    var jwt = createMockJwt(uid: uid, providerId: 'firebase');

    test('FirebaseUserImpl serialization', () {
      var json = {
        'apiKey': auth.rpcHandler.apiKey,
        'uid': uid,
        'displayName': 'defaultDisplayName',
        'lastLoginAt': 1506050282000,
        'createdAt': 1506044998000,
        'email': null,
        'emailVerified': false,
        'phoneNumber': null,
        'photoUrl': 'https://www.default.com/default/default.png',
        'credential': {
          'issuer': <String, dynamic>{},
          'client_id': '',
          'client_secret': null,
          'nonce': null,
          'token': <String, dynamic>{'accessToken': jwt}
        },
        'isAnonymous': false,
        'providerData': [
          {
            'uid': 'providerUserId1',
            'displayName': null,
            'photoUrl': 'https://www.example.com/user1/photo.png',
            'email': 'user1@example.com',
            'providerId': 'providerId1',
            'phoneNumber': null
          },
          {
            'uid': 'providerUserId2',
            'displayName': 'user2',
            'photoUrl': 'https://www.example.com/user2/photo.png',
            'email': 'user2@example.com',
            'providerId': 'providerId2',
            'phoneNumber': null
          }
        ]
      };
      var user = FirebaseUserImpl.fromJson(json, auth: auth);

      expect(user.uid, 'defaultUserId');
      expect(user.displayName, 'defaultDisplayName');
      expect(user.email, isNull);
      expect(user.photoUrl, 'https://www.default.com/default/default.png');
      expect(user.providerId, 'firebase');
      expect(user.isAnonymous, isFalse);
      expect(user.metadata.creationTime.millisecondsSinceEpoch, 1506044998000);
      expect(
          user.metadata.lastSignInTime.millisecondsSinceEpoch, 1506050282000);

      expect(user.toJson(), json);
      expect(user.lastAccessToken, jwt);
    });
  });

  group('FirebaseUser', () {
    group('delete', () {
      test('delete: success', () async {
        var email = 'me@example.com';
        var pass = 'password';

        var result = await auth.createUserWithEmailAndPassword(
            email: email, password: pass);

        var user = result.user as FirebaseUserImpl;

        await user.delete();

        expect(user.isDestroyed, isTrue);

        expect(await tester.backend.getUserByEmail(email), isNull);
      });
/*




function testDelete_error() {
  asyncTestCase.waitForSignals(1);

  user = new fireauth.AuthUser(config1, tokenResponse, accountInfo);
  goog.events.listen(
      user, fireauth.UserEventType.USER_DELETED, function(event) {
        fail('Auth change listener should not trigger!');
      });

  // Simulate rpcHandler deleteAccount.
  var expectedError =
      new fireauth.AuthError(fireauth.authenum.Error.INVALID_AUTH);
  stubs.replace(
      fireauth.RpcHandler.prototype,
      'deleteAccount',
      function(idToken) {
        assertEquals(jwt, idToken);
        return goog.Promise.reject(expectedError);
      });
  // Checks that destroy is not called.
  stubs.replace(
      user,
      'destroy',
      function() {
        fail('User destroy should not be called!');
      });
  user['delete']().thenCatch(function(error) {
    fireauth.common.testHelper.assertErrorEquals(expectedError, error);
    asyncTestCase.signal();
  });
}


function testDelete_userDestroyed() {
  assertFailsWhenUserIsDestroyed('delete', []);
}

 */
    });
  });
}
