import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:test/test.dart';

import 'jwt_util.dart';

void main() {
  group('FirebaseUserImpl', () {
    var apiKey = 'apiKey1';
    var uid = 'defaultUserId';
    var jwt = createMockJwt(uid: uid, providerId: 'firebase');

    test('FirebaseUserImpl serialization', () {
      var json = {
        'apiKey': apiKey,
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
      var user = FirebaseUserImpl.fromJson(json);

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
}
