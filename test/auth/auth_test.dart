import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart';
import 'package:firebase_dart/src/auth/backend/memory_backend.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';
import 'package:firebase_dart/src/database/impl/memory_backend.dart'
    as database;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'jwt_util.dart';
import 'util.dart';

const identityToolkitBaseUrl =
    'https://www.googleapis.com/identitytoolkit/v3/relyingparty';

void main() async {
  var tester = await Tester.create();
  var auth = tester.auth;

  group('FirebaseAuth', () {
    group('FirebaseAuth.signInAnonymously', () {
      test('FirebaseAuth.signInAnonymously: success', () async {
        var result = await auth.signInAnonymously() as UserCredentialImpl;

        expect(result.user.uid, hasLength(24));
        expect(result.credential, isNull);
        expect(result.additionalUserInfo.providerId, isNull);
        expect(result.additionalUserInfo.isNewUser, isTrue);
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);

        expect(result.user.isAnonymous, isTrue);

        // Confirm anonymous state saved.
        var user = await auth.userStorageManager.getCurrentUser();
        expect(user.toJson(), result.user.toJson());
        expect(user.isAnonymous, isTrue);
      });

      test('FirebaseAuth.signInAnonymously: anonymous user already signed in',
          () async {
        var uid = 'defaultUserId';
        var jwt = createMockJwt(uid: uid, providerId: 'firebase');
        var user = FirebaseUserImpl.fromJson({
          'apiKey': 'apiKey',
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
          'isAnonymous': true,
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
        }, auth: auth);

        // Save anonymous user as current in storage.
        await auth.userStorageManager.setCurrentUser(user);
        var u = await auth.userStorageManager.getCurrentUser();

        print(u?.uid);
        await Future.delayed(Duration(milliseconds: 300));

        // All listeners should be called once with the saved anonymous user.
        var stateChanged = 0;
        var s = auth.authStateChanges().listen((user) {
          stateChanged++;
          expect(stateChanged, 1);
          expect(user.uid, uid);
        });
        // signInAnonymously should resolve with the already signed in anonymous
        // user without calling RPC handler underneath.
        var result = await auth.signInAnonymously() as UserCredentialImpl;
        expect(result.user.toJson(), user.toJson());
        expect(result.additionalUserInfo,
            GenericAdditionalUserInfo(providerId: null, isNewUser: false));
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);
        expect(auth.currentUser, result.user);
        expect(result.user.isAnonymous, isTrue);

        // Save reference to current user.
        var currentUser = auth.currentUser;

        // Sign in anonymously again.
        result = await auth.signInAnonymously();

        // Exact same reference should be returned.
        expect(result.user, same(currentUser));

        await s.cancel();
      });
    });

    group('FirebaseAuth.signInWithEmailAndPassword', () {
      test('FirebaseAuth.signInWithEmailAndPassword: success', () async {
        // Expected email and password.
        var expectedEmail = 'user@example.com';
        var expectedPass = 'password';

        var result = await auth.signInWithEmailAndPassword(
            email: expectedEmail, password: expectedPass) as UserCredentialImpl;

        print(result.user.email);
        expect(result.user.uid, 'user1');
        expect(result.credential, isNull);
        expect(result.additionalUserInfo.providerId, 'password');
        expect(result.additionalUserInfo.isNewUser, isFalse);
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);

        expect(result.user.isAnonymous, isFalse);
      });

      test('FirebaseAuth.signInWithEmailAndPassword: wrong password', () async {
        expect(
            () => auth.signInWithEmailAndPassword(
                email: 'user@example.com', password: 'wrong_password'),
            throwsA(FirebaseAuthException.invalidPassword()));
      });
    });

    group('FirebaseAuth.fetchSignInMethodsForEmail', () {
      test('FirebaseAuth.fetchSignInMethodsForEmail: success', () async {
        var signInMethods =
            await auth.fetchSignInMethodsForEmail('user@example.com');

        expect(signInMethods, ['password', 'google.com']);
      });
    });

    group('FirebaseAuth.signInWithCustomToken', () {
      test('FirebaseAuth.signInWithCustomToken: success', () async {
        var expectedCustomToken = createMockCustomToken(uid: 'user1');
        // Sign in with custom token.
        var result = await auth.signInWithCustomToken(expectedCustomToken);

        // Anonymous status should be set to false.
        expect(result.user.isAnonymous, isFalse);
        expect(result.additionalUserInfo.providerId, isNull);
        expect(result.additionalUserInfo.isNewUser, isFalse);

        // Confirm anonymous state saved.
        var user = await auth.userStorageManager.getCurrentUser();
        expect(user.toJson(), result.user.toJson());
        expect(user.isAnonymous, isFalse);
      });
    });

    group('FirebaseAuth.createUserWithEmailAndPassword', () {
      test('FirebaseAuth.createUserWithEmailAndPassword: success', () async {
        // Expected email and password.
        var email = 'user@example.com';
        var pass = 'password';

        var result = await auth.createUserWithEmailAndPassword(
            email: email, password: pass);

        expect(result.user.email, email);
        expect(result.user.isAnonymous, isFalse);
        expect(result.additionalUserInfo.providerId, 'password');
        expect(result.additionalUserInfo.isNewUser, isTrue);
      });
    });

    group('FirebaseAuth.sendSignInLinkToEmail', () {
      test('FirebaseAuth.sendSignInLinkToEmail: success', () async {
        await auth.sendSignInLinkToEmail(
            email: 'user@example.com',
            actionCodeSettings:
                ActionCodeSettings(url: 'https://www.example.com/?state=abc'));
      });
      test('FirebaseAuth.sendSignInLinkToEmail: empty continue url error',
          () async {
        expect(
            () => auth.sendSignInLinkToEmail(
                email: 'user@example.com',
                actionCodeSettings:
                    ActionCodeSettings(url: '', handleCodeInApp: true)),
            throwsA(FirebaseAuthException.invalidContinueUri()));
      });
      test('FirebaseAuth.sendSignInLinkToEmail: handle code in app error',
          () async {
        expect(
            () => auth.sendSignInLinkToEmail(
                email: 'user@example.com',
                actionCodeSettings: ActionCodeSettings(
                    url: 'https://www.example.com/?state=abc',
                    handleCodeInApp: false)),
            throwsA(FirebaseAuthException.argumentError(
                'handleCodeInApp must be true when sending sign in link to email')));
      });
    });

    group('FirebaseAuth.sendPasswordResetEmail', () {
      var email = 'user@example.com';

      test('FirebaseAuth.sendPasswordResetEmail: success', () async {
        await auth.sendPasswordResetEmail(email: email);
      });
    });

    group('FirebaseAuth.confirmPasswordReset', () {
      var expectedEmail = 'user@example.com';
      var expectedCode = createMockJwt(uid: 'user1');
      var expectedNewPassword = 'newPassword';
      test('FirebaseAuth.confirmPasswordReset: success', () async {
        expect(
            () => auth.signInWithEmailAndPassword(
                email: expectedEmail, password: expectedNewPassword),
            throwsA(FirebaseAuthException.invalidPassword()));

        await auth.confirmPasswordReset(expectedCode, expectedNewPassword);
        var r = await auth.signInWithEmailAndPassword(
            email: expectedEmail, password: expectedNewPassword);

        expect(r.user.email, expectedEmail);
      });

      test('FirebaseAuth.confirmPasswordReset: error', () async {
        expect(
            () =>
                auth.confirmPasswordReset('INVALID_CODE', expectedNewPassword),
            throwsA(FirebaseAuthException.invalidOobCode()));
      });
    });

    group('FirebaseAuth.verifyPhoneNumber', () {
      test('FirebaseAuth.verifyPhoneNumber: success', () async {
        var phoneNumber = '+15551234567';

        var u = await tester.backend.getUserById('user1');
        u.phoneNumber = phoneNumber;
        await tester.backend.storeUser(u);

        var credential = Completer<AuthCredential>();

        ApplicationVerifier.instance = DummyApplicationVerifier();

        await auth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            timeout: Duration(),
            verificationCompleted: (value) {
              credential.complete(value);
            },
            verificationFailed: (e) {
              throw e;
            },
            codeSent: (a, b) => null,
            codeAutoRetrievalTimeout: (verificationId) async {
              var code = await tester.backend.receiveSmsCode(phoneNumber);
              credential.complete(PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: code));
            });

        var r = await auth.signInWithCredential(await credential.future);

        expect(r.user.uid, 'user1');
        expect(r.user.phoneNumber, phoneNumber);
      });
    });
  });

  group('FirebaseAuthImpl', () {
    group('FirebaseAuthImpl.delete', () {
      test('FirebaseAuthImpl.delete should trigger onDone on authStateChanges',
          () async {
        var app =
            await Firebase.initializeApp(options: getOptions(), name: 'app1');

        var auth = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;

        var isDone = false;
        auth
            .authStateChanges()
            .listen((_) => null, onDone: () => isDone = true);
        await app.delete();

        expect(auth.isDeleted, isTrue);
        expect(isDone, isTrue);
      });
      test('FirebaseAuthImpl.delete: recreating a deleted app should function',
          () async {
        var app =
            await Firebase.initializeApp(options: getOptions(), name: 'app1');
        var auth = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
        await auth.currentUser;

        await app.delete();
        app = await Firebase.initializeApp(options: getOptions(), name: 'app1');

        var auth2 = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
        expect(auth2.currentUser, isNull);
        await auth2.signInAnonymously();
        expect(auth2.currentUser, isNotNull);
        await app.delete();
      });
    });
  });

  group('Pass authentication to other services', () {
    test('Should auth before listen on database', () async {
      FirebaseDatabase db;
      var backend = database.MemoryBackend.getInstance('test');
      backend.securityRules = {'.read': 'auth!=null'};
      var s = auth.authStateChanges().listen((user) async {
        if (user == null) return;
        await db.reference().child('users').child(user.uid).once();
      });
      db = FirebaseDatabase(app: tester.app, databaseURL: 'mem://test');

      await auth.signInAnonymously();

      await s.cancel();
    });
  });
}

class Tester {
  final MemoryBackend backend;

  final FirebaseApp app;

  Tester._(this.app, this.backend);

  FirebaseAuthImpl get auth => FirebaseAuth.instanceFor(app: app);

  static Future<Tester> create() async {
    await FirebaseTesting.setup();

    var app = await Firebase.initializeApp(options: getOptions());

    var backend = FirebaseTesting.getBackend(app.options);

    await backend.authBackend.storeUser(BackendUser()
      ..localId = 'user1'
      ..createdAt = clock.now().millisecondsSinceEpoch.toString()
      ..lastLoginAt = clock.now().millisecondsSinceEpoch.toString()
      ..email = 'user@example.com'
      ..rawPassword = 'password'
      ..providerUserInfo = [
        UserInfoProviderUserInfo()..providerId = 'password',
        UserInfoProviderUserInfo()..providerId = 'google.com',
      ]);

    return Tester._(app, backend.authBackend);
  }
}
