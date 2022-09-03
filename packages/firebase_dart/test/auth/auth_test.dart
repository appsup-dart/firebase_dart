import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth_lib;
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/database/impl/memory_backend.dart'
    as database;
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:firebaseapis/identitytoolkit/v1.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'jwt_util.dart';
import 'util.dart';

const identityToolkitBaseUrl =
    'https://www.googleapis.com/identitytoolkit/v3/relyingparty';

void main() {
  group('auth service', () => runAuthTests());
}

void runAuthTests({bool isolated = false}) {
  late FirebaseAuth auth;
  late Tester tester;
  setUpAll(() async {
    tester = await Tester.create(isolated: isolated);
    auth = tester.auth;
  });

  group('FirebaseAuth', () {
    setUp(() async {
      await auth.signOut();
      await Future.delayed(Duration(milliseconds: 1));
    });
    group('FirebaseAuth.signInAnonymously', () {
      test('FirebaseAuth.signInAnonymously: success', () async {
        var result = await auth.signInAnonymously() as UserCredentialImpl;

        expect(result.user!.uid, hasLength(24));
        expect(result.credential, isNull);
        expect(result.additionalUserInfo!.providerId, isNull);
        expect(result.additionalUserInfo!.isNewUser, isTrue);
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);

        expect(result.user!.isAnonymous, isTrue);

        // Confirm anonymous state saved.
        var user = await tester.getStoredUser();
        expect(user!, result.user!.toJson());
        expect(user['isAnonymous'], isTrue);
      });

      test('FirebaseAuth.signInAnonymously: anonymous user already signed in',
          () async {
        var uid = 'defaultUserId';
        var jwt = createMockJwt(uid: uid, providerId: 'firebase');
        var user = {
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
            'token': <String, dynamic>{
              'access_token': jwt,
              'expires_at': DateTime.now()
                      .add(Duration(hours: 1))
                      .millisecondsSinceEpoch ~/
                  1000,
              'expires_in': '3600'
            }
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
          ],
          'mfaInfo': [],
        };

        // Save anonymous user as current in storage.
        await tester.setStoredUser(user);

        await Future.delayed(Duration(milliseconds: 300));

        // All listeners should be called once with the saved anonymous user.
        var stateChanged = 0;
        var s = auth.authStateChanges().listen((user) {
          stateChanged++;
          expect(stateChanged, 1);
          expect(user!.uid, uid);
        });
        // signInAnonymously should resolve with the already signed in anonymous
        // user without calling RPC handler underneath.
        var result = await auth.signInAnonymously() as UserCredentialImpl;
        expect(result.user!.toJson(), user);
        expect(result.additionalUserInfo,
            GenericAdditionalUserInfo(providerId: null, isNewUser: false));
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);
        expect(auth.currentUser, result.user);
        expect(result.user!.isAnonymous, isTrue);

        // Save reference to current user.
        var currentUser = auth.currentUser;

        // Sign in anonymously again.
        result = await auth.signInAnonymously() as UserCredentialImpl;

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

        expect(result.user!.uid, 'user1');
        expect(result.credential, isNull);
        expect(result.additionalUserInfo!.providerId, 'password');
        expect(result.additionalUserInfo!.isNewUser, isFalse);
        expect(result.operationType, UserCredentialImpl.operationTypeSignIn);

        expect(result.user!.isAnonymous, isFalse);
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
        expect(result.user!.isAnonymous, isFalse);
        expect(result.additionalUserInfo!.providerId, isNull);
        expect(result.additionalUserInfo!.isNewUser, isFalse);

        // Confirm anonymous state saved.
        var user = await tester.getStoredUser();
        expect(user!, result.user!.toJson());
        expect(user['isAnonymous'], isFalse);
      });
    });

    group('FirebaseAuth.createUserWithEmailAndPassword', () {
      test('FirebaseAuth.createUserWithEmailAndPassword: success', () async {
        // Expected email and password.
        var email = 'user@example.com';
        var pass = 'password';

        var result = await auth.createUserWithEmailAndPassword(
            email: email, password: pass);

        expect(result.user!.email, email);
        expect(result.user!.isAnonymous, isFalse);
        expect(result.additionalUserInfo!.providerId, 'password');
        expect(result.additionalUserInfo!.isNewUser, isTrue);
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

        expect(r.user!.email, expectedEmail);

        await auth.confirmPasswordReset(expectedCode, 'password');
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

        await auth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            timeout: Duration(),
            verificationCompleted: (value) {
              credential.complete(value);
            },
            verificationFailed: (e) {
              throw e;
            },
            codeSent: (a, b) {},
            codeAutoRetrievalTimeout: (verificationId) async {
              var code = await tester.backend.receiveSmsCode(phoneNumber);
              credential.complete(PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: code!));
            });

        var r = await auth.signInWithCredential(await credential.future);

        expect(r.user!.uid, 'user1');
        expect(r.user!.phoneNumber, phoneNumber);
      });

      tearDown(() async {
        var u = await tester.backend.getUserById('user1');
        u.mfaInfo?.clear();
        await tester.backend.storeUser(u);
      });

      test('FirebaseAuth.verifyPhoneNumber with mfa session: success',
          () async {
        var phoneNumber = '+15551234567';

        var expectedEmail = 'user@example.com';
        var expectedPass = 'password';

        var result = await auth.signInWithEmailAndPassword(
            email: expectedEmail, password: expectedPass);
        var user = result.user!;

        final session = await user.multiFactor.getSession();

        var credential = Completer<PhoneAuthCredential>();

        await auth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            multiFactorSession: session,
            timeout: Duration(),
            verificationCompleted: (value) {
              credential.complete(value);
            },
            verificationFailed: (e) {
              throw e;
            },
            codeSent: (a, b) {},
            codeAutoRetrievalTimeout: (verificationId) async {
              var code = await tester.backend.receiveSmsCode(phoneNumber);
              credential.complete(PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: code!));
            });

        await user.multiFactor.enroll(
          PhoneMultiFactorGenerator.getAssertion(
            await credential.future,
          ),
          displayName: 'my phone',
        );

        expect(user.uid, 'user1');
        expect(user.phoneNumber, phoneNumber);

        var factors = await user.multiFactor.getEnrolledFactors();

        expect(factors.length, 1);
        expect(factors[0].factorId, 'phone');
        expect(factors[0].uid, isNotEmpty);
        expect(factors[0].displayName, 'my phone');
      });

      test('FirebaseAuth.verifyPhoneNumber with mfa sign in: success',
          () async {
        var phoneNumber = '+15551234567';

        var u = await tester.backend.getUserById('user1');
        u.mfaInfo = [
          GoogleCloudIdentitytoolkitV1MfaEnrollment()
            ..phoneInfo = phoneNumber
            ..enrolledAt = DateTime.now().toIso8601String()
            ..displayName = 'my phone'
            ..mfaEnrollmentId = Uuid().v4()
        ];
        await tester.backend.storeUser(u);

        try {
          await auth.signInWithEmailAndPassword(
            email: u.email!,
            password: u.rawPassword!,
          );
          throw Exception();
        } on FirebaseAuthMultiFactorException catch (e) {
          expect(e.resolver.hints, isNotEmpty);
          expect(e.resolver.hints[0].displayName, 'my phone');
          expect(e.resolver.hints[0].uid, isNotEmpty);
          expect(e.resolver.hints[0].factorId, 'phone');

          var credential = Completer<PhoneAuthCredential>();

          await auth.verifyPhoneNumber(
              multiFactorSession: e.resolver.session,
              multiFactorInfo: e.resolver.hints.first as PhoneMultiFactorInfo,
              timeout: Duration(),
              verificationCompleted: (value) {
                credential.complete(value);
              },
              verificationFailed: (e) {
                throw e;
              },
              codeSent: (a, b) {},
              codeAutoRetrievalTimeout: (verificationId) async {
                var code = await tester.backend.receiveSmsCode(phoneNumber);
                credential.complete(PhoneAuthProvider.credential(
                    verificationId: verificationId, smsCode: code!));
              });

          var r = await e.resolver.resolveSignIn(
              PhoneMultiFactorGenerator.getAssertion(await credential.future));

          expect(r.user!.uid, 'user1');
        }
      });
    });

    group('FirebaseAuth.authStateChanges', () {
      test(
          'FirebaseAuth.authStateChanges: should emit values when user signs in or out',
          () async {
        var values = <User?>[];
        auth.authStateChanges().listen((v) => values.add(v));

        // when not logged in, should emit null
        await Future.delayed(Duration(milliseconds: 1));
        expect(values, [null]);
        values.clear();

        // when signing in, should emit a User instance
        await auth.signInAnonymously();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, isA<User>());
        values.clear();

        // reload should not emit event
        await auth.currentUser!.reload();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, true);

        // refresh id token should not emit event
        await auth.currentUser!.getIdToken(true);
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, true);

        // signing out should emit event
        await auth.signOut();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, null);
      });
    });

    group('FirebaseAuth.idTokenChanges', () {
      test(
          'FirebaseAuth.idTokenChanges: should emit values when user signs in or out or id token changes',
          () async {
        var values = <User?>[];
        auth.idTokenChanges().listen((v) => values.add(v));

        // when not logged in, should emit null
        await Future.delayed(Duration(milliseconds: 1));
        expect(values, [null]);
        values.clear();

        // when signing in, should emit a User instance
        await auth.signInAnonymously();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, isA<User>());
        values.clear();

        // reload should not emit event
        await auth.currentUser!.reload();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, true);

        // refresh id token should emit an event
        await auth.currentUser!.getIdToken(true);
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, false);
        values.clear();

        // signing out should emit event
        await auth.signOut();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, null);
      });
    });
    group('FirebaseAuth.userChanges', () {
      test(
          'FirebaseAuth.userChanges: should emit values when user signs in or out or id token changes or user data changes',
          () async {
        var values = <User?>[];
        auth.userChanges().listen((v) => values.add(v));

        // when not logged in, should emit null
        await Future.delayed(Duration(milliseconds: 1));
        expect(values, [null]);
        values.clear();

        // when signing in, should emit a User instance
        await auth.signInAnonymously();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, isA<User>());
        values.clear();

        // refresh id token should emit an event
        await auth.currentUser!.getIdToken(true);
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, false);
        values.clear();

        // updating user data should emit an event
        await auth.currentUser!.updateProfile(displayName: 'Jane Doe');
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.isEmpty, false);
        values.clear();

        // signing out should emit event
        await auth.signOut();
        await Future.delayed(Duration(milliseconds: 1));
        expect(values.single, null);
      });
    });

    group('FirebaseAuth.signInWithCredential', () {
      test('FirebaseAuth.signInWithCredential: success', () async {
        var expectedGoogleCredential = GoogleAuthProvider.credential(
            idToken: createMockGoogleIdToken(uid: 'google_user_1'),
            accessToken: 'googleAccessToken');
        var r = await auth.signInWithCredential(expectedGoogleCredential);

        expect(r.user!.uid, 'user1');
      });
      test('FirebaseAuth.signInWithCredential: email/pass credential',
          () async {
        var r = await auth.signInWithCredential(EmailAuthProvider.credential(
            email: 'user@example.com', password: 'password'));

        expect(r.user!.uid, 'user1');
      });
      test('FirebaseAuth.signInWithCredential: error', () async {
        var expectedGoogleCredential = GoogleAuthProvider.credential(
            idToken: createMockGoogleIdToken(
                uid: 'google_user_2', email: 'user@example.com'),
            accessToken: 'googleAccessToken');
        expect(auth.signInWithCredential(expectedGoogleCredential),
            throwsA(FirebaseAuthException.needConfirmation()));
      });
    });

    group('FirebaseAuth.checkActionCode', () {
      test('FirebaseAuth.checkActionCode: success', () async {
        var code = await tester.backend
            .createActionCode('PASSWORD_RESET', 'user@example.com');
        var v = await auth.checkActionCode(code!);

        expect(v.operation, ActionCodeInfoOperation.passwordReset);
        expect(v.data['email'], 'user@example.com');
      });

      test('FirebaseAuth.checkActionCode: error', () async {
        expect(() => auth.checkActionCode('PASSWORD_RESET_CODE'),
            throwsA(FirebaseAuthException.invalidOobCode()));
      });
    });

    group('FirebaseAuth.applyActionCode', () {
      test('FirebaseAuth.applyActionCode: success', () async {
        var code = await tester.backend
            .createActionCode('EMAIL_VERIFICATION_CODE', 'user@example.com');
        await auth.applyActionCode(code!);
      });

      test('FirebaseAuth.applyActionCode: error', () async {
        expect(() => auth.applyActionCode('EMAIL_VERIFICATION_CODE'),
            throwsA(FirebaseAuthException.invalidOobCode()));
      });
    });

    group('FirebaseAuth.isSignInWithEmailLink', () {
      test('FirebaseAuth.isSignInWithEmailLink', () {
        var emailLink1 = 'https://www.example.com/action?mode=signIn&'
            'oobCode=oobCode&apiKey=API_KEY';
        var emailLink2 = 'https://www.example.com/action?mode=verifyEmail&'
            'oobCode=oobCode&apiKey=API_KEY';
        var emailLink3 = 'https://www.example.com/action?mode=signIn';
        expect(auth.isSignInWithEmailLink(emailLink1), true);
        expect(auth.isSignInWithEmailLink(emailLink2), false);
        expect(auth.isSignInWithEmailLink(emailLink3), false);
      });
      test('FirebaseAuth.isSignInWithEmailLink: deep link', () {
        var deepLink1 =
            'https://www.example.com/action?mode=signIn&oobCode=oobCode'
            '&apiKey=API_KEY';
        var deepLink2 = 'https://www.example.com/action?mode=verifyEmail&'
            'oobCode=oobCode&apiKey=API_KEY';
        var deepLink3 = 'https://www.example.com/action?mode=signIn';

        var emailLink1 =
            'https://example.app.goo.gl/?link=${Uri.encodeComponent(deepLink1)}';
        var emailLink2 =
            'https://example.app.goo.gl/?link=${Uri.encodeComponent(deepLink2)}';
        var emailLink3 =
            'https://example.app.goo.gl/?link=${Uri.encodeComponent(deepLink3)}';
        var emailLink4 =
            'comexampleiosurl://google/link?deep_link_id=${Uri.encodeComponent(deepLink1)}';

        expect(auth.isSignInWithEmailLink(emailLink1), true);
        expect(auth.isSignInWithEmailLink(emailLink2), false);
        expect(auth.isSignInWithEmailLink(emailLink3), false);
        expect(auth.isSignInWithEmailLink(emailLink4), true);
      });
    });

    group('FirebaseAuth.signInWithEmailLink', () {
      test('FirebaseAuth.signInWithEmailLink: success', () async {
        var expectedEmail = 'user@example.com';
        var code = await tester.backend
            .createActionCode('EMAIL_SIGNIN', expectedEmail);
        var expectedLink =
            'https://www.example.com?mode=signIn&oobCode=$code&apiKey=API_KEY';

        var r = await auth.signInWithEmailLink(
            email: expectedEmail, emailLink: expectedLink);

        expect(r.additionalUserInfo!.providerId, 'password');
        expect(r.additionalUserInfo!.isNewUser, false);
        expect(r.user!.email, 'user@example.com');
      });

      test('FirebaseAuth.signInWithEmailLink: deep link success', () async {
        var expectedEmail = 'user@example.com';
        var code = await tester.backend
            .createActionCode('EMAIL_SIGNIN', expectedEmail);
        var deepLink =
            'https://www.example.com?mode=signIn&oobCode=$code&apiKey=API_KEY';
        var expectedLink =
            'https://example.app.goo.gl/?link=${Uri.encodeComponent(deepLink)}';

        var r = await auth.signInWithEmailLink(
            email: expectedEmail, emailLink: expectedLink);

        expect(r.additionalUserInfo!.providerId, 'password');
        expect(r.additionalUserInfo!.isNewUser, false);
        expect(r.user!.email, 'user@example.com');
      });
      test('FirebaseAuth.signInWithEmailLink: invalid link error', () async {
        var expectedEmail = 'user@example.com';
        var expectedLink = 'https://www.example.com?mode=signIn';

        expect(
            () => auth.signInWithEmailLink(
                email: expectedEmail, emailLink: expectedLink),
            throwsA(
                FirebaseAuthException.argumentError('Invalid email link!')));
      });
    });

    group('FirebaseAuth.verifyPasswordResetCode', () {
      test('FirebaseAuth.verifyPasswordResetCode: success', () async {
        var expectedEmail = 'user@example.com';
        var code = await tester.backend
            .createActionCode('PASSWORD_RESET', expectedEmail);

        var email = await auth.verifyPasswordResetCode(code!);
        expect(email, expectedEmail);
      });
    });
  });

  if (!isolated) {
    group('FirebaseAuthImpl', () {
      group('FirebaseAuthImpl.delete', () {
        test(
            'FirebaseAuthImpl.delete should trigger onDone on authStateChanges',
            () async {
          var app =
              await Firebase.initializeApp(options: getOptions(), name: 'app1');

          var auth = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;

          var isDone = false;
          auth.authStateChanges().listen((_) {}, onDone: () => isDone = true);
          await app.delete();

          expect(auth.isDeleted, isTrue);
          expect(isDone, isTrue);
        });
        test(
            'FirebaseAuthImpl.delete: recreating a deleted app should function',
            () async {
          var app =
              await Firebase.initializeApp(options: getOptions(), name: 'app1');
          var auth = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
          auth.currentUser;

          await app.delete();
          app =
              await Firebase.initializeApp(options: getOptions(), name: 'app1');

          var auth2 = FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
          expect(auth2.currentUser, isNull);
          await auth2.signInAnonymously();
          expect(auth2.currentUser, isNotNull);
          await app.delete();
        });
      });
    });
  }

  group('Pass authentication to other services', () {
    test('Should auth before listen on database', () async {
      late FirebaseDatabase db;
      var backend = database.MemoryBackend.getInstance('test');
      backend.securityRules = {'.read': 'auth!=null'};
      var f = auth.authStateChanges().asyncMap((user) async {
        if (user == null) return false;
        await db.reference().child('users').child(user.uid).once();
        return true;
      }).firstWhere((v) => v);
      db = FirebaseDatabase(app: tester.app, databaseURL: 'mem://test');

      await auth.signInAnonymously();

      await f;
    });
  });
}

class Tester {
  final auth_lib.AuthBackend backend;

  final FirebaseApp app;

  Tester._(this.app, this.backend);

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: app);

  Future<Map<String, dynamic>?> getStoredUser() async {
    if (auth is FirebaseAuthImpl) {
      return _getStoredUser(_key);
    }
    var commander = await (FirebaseImplementation.installation
            as IsolateFirebaseImplementation)
        .commander;
    return commander.execute(StaticFunctionCall(_getStoredUser, [_key]));
  }

  static Future<Map<String, dynamic>?> _getStoredUser(String key) async {
    var box = await PersistenceStorage.openBox('firebase_auth');
    return box.get(key);
  }

  Future<void> setStoredUser(Map<String, dynamic>? user) async {
    if (auth is FirebaseAuthImpl) {
      return _setStoredUser(_key, user);
    }
    var commander = await (FirebaseImplementation.installation
            as IsolateFirebaseImplementation)
        .commander;
    return commander.execute(StaticFunctionCall(_setStoredUser, [_key, user]));
  }

  static Future<void> _setStoredUser(
      String key, Map<String, dynamic>? user) async {
    var box = await PersistenceStorage.openBox('firebase_auth');
    return box.put(key, user);
  }

  String get appId => auth.app.options.appId;

  String get _key => 'firebase:FirebaseUser:$appId';

  static Future<Tester> create({bool isolated = false}) async {
    PersistenceStorage.setupMemoryStorage();
    await FirebaseTesting.setup(isolated: isolated);

    var app = await Firebase.initializeApp(options: getOptions());

    var backend = FirebaseTesting.getBackend(app.options);

    await backend.authBackend.storeUser(BackendUser('user1')
      ..createdAt = clock.now().millisecondsSinceEpoch.toString()
      ..lastLoginAt = clock.now().millisecondsSinceEpoch.toString()
      ..email = 'user@example.com'
      ..rawPassword = 'password'
      ..providerUserInfo = [
        GoogleCloudIdentitytoolkitV1ProviderUserInfo()..providerId = 'password',
        GoogleCloudIdentitytoolkitV1ProviderUserInfo()
          ..providerId = 'google.com'
          ..rawId = 'google_user_1',
      ]);

    return Tester._(app, backend.authBackend);
  }
}
