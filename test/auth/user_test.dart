import 'dart:io';

import 'package:clock/clock.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';
import 'package:firebase_dart/src/auth/user.dart' show UserUpdateInfo;
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
    });

    group('sendEmailVerification', () {
      var email = 'user@example.com';
      var pass = 'password';

      test('sendEmailVerification: success', () async {
        var result =
            await auth.signInWithEmailAndPassword(email: email, password: pass);
        var user = result.user;

        await user.sendEmailVerification();
      });

      test('sendEmailVerification: local copy wrong email', () async {
        var result =
            await auth.signInWithEmailAndPassword(email: email, password: pass);
        var user = result.user;

        // This user does not have an email.
        var user1 = FirebaseUserImpl.fromJson({
          ...user.toJson()..remove('email'),
        }, auth: auth);

        expect(user1.email, isNull);
        await user1.sendEmailVerification();
        expect(user1.email, email);

        // This user has the wrong email.
        var user2 = FirebaseUserImpl.fromJson({
          ...user.toJson(),
          'email': 'wrong@email.com',
        }, auth: auth);

        expect(user2.email, 'wrong@email.com');
        await user2.sendEmailVerification();
        expect(user2.email, email);
      });
    });

    group('unlinkFromProvider', () {
      var email = 'me@example.com';
      var password = 'password';

      setUp(() {
        tester.backend.storeUser(UserInfo()
          ..email = email
          ..rawPassword = password
          ..phoneNumber = '+16505550101'
          // User on server has two federated providers and one phone provider linked.
          ..providerUserInfo = [
            UserInfoProviderUserInfo.fromJson({
              'providerId': 'providerId1',
              'displayName': 'user1',
              'email': 'user1@example.com',
              'photoUrl': 'https://www.example.com/user1/photo.png',
              'rawId': 'providerUserId1'
            }),
            UserInfoProviderUserInfo.fromJson({
              'providerId': 'providerId2',
              'displayName': 'user2',
              'email': 'user2@example.com',
              'photoUrl': 'https://www.example.com/user2/photo.png',
              'rawId': 'providerUserId2'
            }),
            UserInfoProviderUserInfo.fromJson({
              'providerId': 'phone',
              'rawId': '+16505550101',
              'phoneNumber': '+16505550101'
            }),
          ]);
      });
      test('unlinkFromProvider: success', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2', 'phone']);

        await user.unlinkFromProvider('providerId2');
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'phone']);
      });
      test('unlinkFromProvider: already deleted', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2', 'phone']);

        // User on server has only one federated provider linked despite the local
        // copy having three.
        var backendUser = await tester.backend.getUserById(user.uid);
        backendUser.providerUserInfo
            .removeWhere((element) => element.providerId != 'providerId1');
        await tester.backend.storeUser(backendUser);

        expect(() => user.unlinkFromProvider('providerId2'),
            throwsA(AuthException.noSuchProvider()));
      });
      test('unlinkFromProvider: phone', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2', 'phone']);

        expect(user.phoneNumber, '+16505550101');

        await user.unlinkFromProvider('phone');
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2']);

        expect(user.phoneNumber, isNull);

        await user.reload();
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2']);

        expect(user.phoneNumber, isNull);
      });
    });

    group('updateProfile', () {
      test('updateProfile: success', () async {
        var u = await tester.backend.getUserById('user1');
        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);

        var user = r.user;

        await user.updateProfile(UserUpdateInfo()
          ..displayName = 'Jack Smith'
          ..photoUrl = 'http://www.example.com/photo/photo.png');

        expect(user.displayName, 'Jack Smith');
        expect(user.photoUrl, 'http://www.example.com/photo/photo.png');

        await user.reload();

        expect(user.displayName, 'Jack Smith');
        expect(user.photoUrl, 'http://www.example.com/photo/photo.png');
      });
      test('updateProfile: with password provider', () async {
        var u = await tester.backend.getUserById('user1');

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);

        var user = r.user;

        await user.updateProfile(UserUpdateInfo()
          ..displayName = 'Jack Smith'
          ..photoUrl = 'http://www.example.com/photo/photo.png');

        var p = user.providerData
            .firstWhere((element) => element.providerId == 'password');
        expect(p.displayName, 'Jack Smith');
        expect(p.photoUrl, 'http://www.example.com/photo/photo.png');
      });
      test('updateProfile: empty change', () async {
        var u = await tester.backend.getUserById('user1');

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);

        var user = r.user;

        await user.updateProfile(UserUpdateInfo());
      });
    });

    group('updateEmail', () {
      test('updateEmail: success', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);
        var user = r.user;
        expect(user.email, 'user@example.com');
        expect(user.isEmailVerified, isTrue);

        var newEmail = 'newuser@example.com';

        await user.updateEmail(newEmail);

        expect(user.email, newEmail);
        expect(user.isEmailVerified, isFalse);
      });
      test('updateEmail: user destroyed', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);
        var user = r.user;

        await auth.signOut();

        expect(() => user.updateEmail('newuser@example.com'),
            throwsA(AuthException.moduleDestroyed()));
      });
    });

    group('updatePassword', () {
      test('updatePassword: success', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);
        var user = r.user;

        await user.updatePassword('newPassword');
      });
      test('updatePassword: user destroyed', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email, password: u.rawPassword);
        var user = r.user;

        await auth.signOut();

        expect(() => user.updatePassword('newPassword'),
            throwsA(AuthException.moduleDestroyed()));
      });
    });
  });
}
