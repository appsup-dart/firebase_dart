import 'dart:typed_data';

import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/auth/usermanager.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'auth_test.dart';
import 'jwt_util.dart';

void main() async {
  var tester = await Tester.create();

  var apiKey = tester.app.options.apiKey;
  var appId = tester.app.options.appId;

  group('UserManager', () {
    var auth = tester.auth as FirebaseAuthImpl;

    var uid = 'defaultUserId';
    var jwt = createMockJwt(uid: uid, providerId: 'firebase');
    var expectedUser = {
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
      ],
      'mfaInfo': [],
    };

    late Box storage;

    setUp(() async {
      storage = await Hive.openBox('test', bytes: Uint8List(0));
    });

    tearDown(() async {
      await storage.close();
    });

    var exampleUser = FirebaseUserImpl.fromJson(expectedUser, auth: auth);

    test('get, set and remove current user', () async {
      var userManager = UserManager(auth, storage);

      // Expected user with authDomain.
      var expectedUserWithAuthDomain = {
        ...expectedUser,
        'authDomain': 'project.firebaseapp.com'
      };

      await userManager.setCurrentUser(exampleUser);

      var user = await userManager.getCurrentUser();
      expect(user!.toJson(), expectedUser);
      expect(await storage.get('firebase:FirebaseUser:$appId'), expectedUser);

      // Get user with authDomain.
      user = await userManager.getCurrentUser('project.firebaseapp.com');
      expect(user!.toJson(), expectedUserWithAuthDomain);

      await userManager.removeCurrentUser();

      expect(await storage.get('firebase:FirebaseUser:$appId'), isNull);

      user = await userManager.getCurrentUser();
      expect(user, isNull);
    });

    test('add/remove current user change listener', () async {
      var userManager = UserManager(auth, storage);

      var key1 = 'firebase:FirebaseUser:$appId';
      var key2 = 'firebase:FirebaseUser:other_app_id';

      // Save existing Auth users for appId1 and appId2.
      await storage.put(key1, expectedUser);
      await storage.put(key2, expectedUser);

      await Future.delayed(Duration(milliseconds: 300));
      var calls = 0;
      var subscription = userManager.onCurrentUserChanged.listen((_) {
        calls++;
        if (calls > 1) {
          throw Exception('Listener should be called once.');
        }
      });
      await Future.delayed(Duration(milliseconds: 300));

      // Simulate appId1 user deletion.
      await Future.value(
          storage); // wait a bit so that delete is not executed before watch
      await storage.delete(key1);
      // This should trigger listener.
      expect(calls, 1);

      // Simulate appId2 user deletion.
      await storage.delete(key2);
      // This should not trigger listener.
      expect(calls, 1);

      // Remove listener.
      await subscription.cancel();

      // Simulate new user saved for appId1.
      // This should not trigger listener.
      await storage.put(key1, expectedUser);
    });

    group('UserManager.onCurrentUserChanged', () {
      test('UserManager.onCurrentUserChanged should fire when user is changed',
          () async {
        var userManager = UserManager(auth, storage);

        var values = <String?>[];
        userManager.onCurrentUserChanged.listen((v) => values.add(v?.uid));

        await userManager.setCurrentUser(exampleUser);

        expect(values, [exampleUser.uid]);
        values.clear();

        await userManager.removeCurrentUser();
        expect(values, [null]);
      });

      test(
          'UserManager.onCurrentUserChanged should fire when user is changed in other user manager',
          () async {
        var userManager1 = UserManager(auth, storage);
        var userManager2 = UserManager(auth, storage);

        var values = <String?>[];
        userManager1.onCurrentUserChanged.listen((v) => values.add(v?.uid));

        await userManager2.setCurrentUser(exampleUser);

        expect(values, [exampleUser.uid]);
        values.clear();

        await userManager2.removeCurrentUser();
        expect(values, [null]);
      });
    });

    group('UserManager.close', () {
      test('UserManager.close should fire onDone on onCurrentUserChanged',
          () async {
        var userManager = UserManager(auth, storage);

        var isDone = false;
        userManager.onCurrentUserChanged
            .listen((_) {}, onDone: () => isDone = true);

        await userManager.close();

        expect(isDone, true);
      });
      test(
          'UserManager.close should not end onCurrentUserChanged on other user manager',
          () async {
        var userManager = UserManager(auth, storage);
        var userManager2 = UserManager(auth, storage);

        var isDone = false;

        FirebaseUserImpl? last;
        var s = userManager2.onCurrentUserChanged
            .listen((v) => last = v, onDone: () => isDone = true);

        await userManager.close();

        await userManager2.setCurrentUser(exampleUser);

        expect(isDone, false);
        expect(last!.uid, exampleUser.uid);

        await s.cancel();
      });
    });
  });
}
