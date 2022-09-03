import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/implementation/isolate/auth.dart';
import 'package:firebaseapis/identitytoolkit/v1.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'auth_test.dart';
import 'jwt_util.dart';

void main() {
  group('auth service - user', () => runUserTests());
}

void runUserTests({bool isolated = false}) {
  late FirebaseAuth auth;
  late Tester tester;
  setUpAll(() async {
    tester = await Tester.create(isolated: isolated);
    auth = tester.auth;
  });
  group('FirebaseUserImpl', () {
    var uid = 'defaultUserId';
    var jwt = createMockJwt(uid: uid, providerId: 'firebase');

    test('FirebaseUserImpl serialization', () {
      var json = {
        'apiKey': auth.app.options.apiKey,
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
      var user = UserBase.fromJson(json);

      expect(user.uid, 'defaultUserId');
      expect(user.displayName, 'defaultDisplayName');
      expect(user.email, isNull);
      expect(user.photoURL, 'https://www.default.com/default/default.png');
      expect(user.providerId, 'firebase');
      expect(user.isAnonymous, isFalse);
      expect(user.metadata.creationTime!.millisecondsSinceEpoch, 1506044998000);
      expect(
          user.metadata.lastSignInTime!.millisecondsSinceEpoch, 1506050282000);

      expect(user.toJson(), json);
    });
  });

  group('FirebaseUser', () {
    group('delete', () {
      test('delete: success', () async {
        var email = 'me@example.com';
        var pass = 'password';

        var result = await auth.createUserWithEmailAndPassword(
            email: email, password: pass);

        var user = result.user!;

        await user.delete();

        if (user is FirebaseUserImpl) {
          expect(user.isDestroyed, isTrue);
        }

        await expectLater(() => tester.backend.getUserByEmail(email),
            throwsA(FirebaseAuthException.userDeleted()));
      });
    });

    group('sendEmailVerification', () {
      var email = 'user@example.com';
      var pass = 'password';

      test('sendEmailVerification: success', () async {
        var result =
            await auth.signInWithEmailAndPassword(email: email, password: pass);
        var user = result.user!;

        await user.sendEmailVerification();
      });

      test('sendEmailVerification: local copy wrong email', () async {
        var result =
            await auth.signInWithEmailAndPassword(email: email, password: pass);
        var user = result.user!;

        // This user does not have an email.
        if (user is FirebaseUserImpl) {
          user.setAccountInfo(
              AccountInfo.fromJson(user.toJson()..remove('email')));
        } else if (user is IsolateUser) {
          await user.setAccountInfo(
              AccountInfo.fromJson(user.toJson()..remove('email')));
        }

        expect(user.email, isNull);
        await user.sendEmailVerification();
        await Future.delayed(Duration(milliseconds: 100));
        expect(user.email, email);

        // This user has the wrong email.
        var info = AccountInfo.fromJson(
            {...user.toJson(), 'email': 'wrong@email.com'});
        if (user is FirebaseUserImpl) {
          user.setAccountInfo(info);
        } else if (user is IsolateUser) {
          await user.setAccountInfo(info);
        }

        expect(user.email, 'wrong@email.com');
        await user.sendEmailVerification();
        await Future.delayed(Duration(milliseconds: 100));
        expect(user.email, email);
      });
    });

    group('unlink', () {
      var email = 'me@example.com';
      var password = 'password';

      setUp(() {
        tester.backend.storeUser(BackendUser('user2')
          ..email = email
          ..rawPassword = password
          ..phoneNumber = '+16505550101'
          // User on server has two federated providers and one phone provider linked.
          ..providerUserInfo = [
            GoogleCloudIdentitytoolkitV1ProviderUserInfo.fromJson({
              'providerId': 'providerId1',
              'displayName': 'user1',
              'email': 'user1@example.com',
              'photoUrl': 'https://www.example.com/user1/photo.png',
              'rawId': 'providerUserId1'
            }),
            GoogleCloudIdentitytoolkitV1ProviderUserInfo.fromJson({
              'providerId': 'providerId2',
              'displayName': 'user2',
              'email': 'user2@example.com',
              'photoUrl': 'https://www.example.com/user2/photo.png',
              'rawId': 'providerUserId2'
            }),
            GoogleCloudIdentitytoolkitV1ProviderUserInfo.fromJson({
              'providerId': 'phone',
              'rawId': '+16505550101',
              'phoneNumber': '+16505550101'
            }),
          ]);
      });
      test('unlink: success', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user!;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(
            providerIds, ['providerId1', 'providerId2', 'phone', 'password']);

        await user.unlink('providerId2');
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'phone', 'password']);
      });
      test('unlink: already deleted', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user!;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(
            providerIds, ['providerId1', 'providerId2', 'phone', 'password']);

        // User on server has only one federated provider linked despite the local
        // copy having three.
        var backendUser = await tester.backend.getUserById(user.uid);
        backendUser.providerUserInfo!
            .removeWhere((element) => element.providerId != 'providerId1');
        await tester.backend.storeUser(backendUser);

        expect(() => user.unlink('providerId2'),
            throwsA(FirebaseAuthException.noSuchProvider()));
      });
      test('unlink: phone', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: email, password: password);

        var user = r.user!;
        var providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(
            providerIds, ['providerId1', 'providerId2', 'phone', 'password']);

        expect(user.phoneNumber, '+16505550101');

        await user.unlink('phone');
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2', 'password']);

        expect(user.phoneNumber, isNull);

        await user.reload();
        providerIds = user.providerData.map((v) => v.providerId).toSet();
        expect(providerIds, ['providerId1', 'providerId2', 'password']);

        expect(user.phoneNumber, isNull);
      });
    });

    group('updateProfile', () {
      test('updateProfile: success', () async {
        var u = await tester.backend.getUserById('user1');
        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);

        var user = r.user!;

        await user.updateProfile(
            displayName: 'Jack Smith',
            photoURL: 'http://www.example.com/photo/photo.png');

        expect(user.displayName, 'Jack Smith');
        expect(user.photoURL, 'http://www.example.com/photo/photo.png');

        await user.reload();

        expect(user.displayName, 'Jack Smith');
        expect(user.photoURL, 'http://www.example.com/photo/photo.png');
      });
      test('updateProfile: with password provider', () async {
        var u = await tester.backend.getUserById('user1');

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);

        var user = r.user!;

        await user.updateProfile(
            displayName: 'Jack Smith',
            photoURL: 'http://www.example.com/photo/photo.png');

        expect(user.displayName, 'Jack Smith');
        expect(user.photoURL, 'http://www.example.com/photo/photo.png');

        var p = user.providerData
            .firstWhere((element) => element.providerId == 'password');
        expect(p.displayName, 'Jack Smith');
        expect(p.photoURL, 'http://www.example.com/photo/photo.png');

        await user.reload();
        expect(user.displayName, 'Jack Smith');
        expect(user.photoURL, 'http://www.example.com/photo/photo.png');

        p = user.providerData
            .firstWhere((element) => element.providerId == 'password');
        expect(p.displayName, 'Jack Smith');
        expect(p.photoURL, 'http://www.example.com/photo/photo.png');
      });
      test('updateProfile: empty change', () async {
        var u = await tester.backend.getUserById('user1');

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);

        var user = r.user!;

        await user.updateProfile();
      });
    });

    group('updateEmail', () {
      test('updateEmail: success', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);
        var user = r.user!;
        expect(user.email, 'user@example.com');
        expect(user.emailVerified, isTrue);

        var newEmail = 'newuser@example.com';

        await user.updateEmail(newEmail);

        expect(user.email, newEmail);
        expect(user.emailVerified, isFalse);

        await user.updateEmail('user@example.com');
      });
      test('updateEmail: user destroyed', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);
        var user = r.user;

        await auth.signOut();

        expect(() => user!.updateEmail('newuser@example.com'),
            throwsA(FirebaseAuthException.moduleDestroyed()));
      });
    });

    group('updatePassword', () {
      test('updatePassword: success', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);
        var user = r.user!;

        await user.updatePassword('newPassword');
      });
      test('updatePassword: user destroyed', () async {
        var u = await tester.backend.getUserById('user1');
        await tester.backend.storeUser(u..emailVerified = true);

        var r = await auth.signInWithEmailAndPassword(
            email: u.email!, password: u.rawPassword!);
        var user = r.user;

        await auth.signOut();

        expect(() => user!.updatePassword('newPassword'),
            throwsA(FirebaseAuthException.moduleDestroyed()));
      });
    });

    group('getIdTokenResult', () {
      test('getIdTokenResult: success', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: 'user@example.com', password: 'password');

        var user = r.user!;

        var token = await user.getIdTokenResult();

        expect(token.authTime!.millisecondsSinceEpoch,
            closeTo(clock.now().millisecondsSinceEpoch, 5000));

        expect(
            token.expirationTime!.millisecondsSinceEpoch,
            closeTo(clock.now().add(Duration(hours: 1)).millisecondsSinceEpoch,
                5000));
        expect(token.issuedAtTime!.millisecondsSinceEpoch,
            closeTo(clock.now().millisecondsSinceEpoch, 5000));
        expect(token.signInProvider, 'password');
        expect(token.claims!['firebase'], {
          'identities': {
            'email': ['user@example.com']
          },
          'sign_in_provider': 'password'
        });
        expect(token.claims!['email'], 'user@example.com');
        expect(token.claims!['sub'], user.uid);
      });

      test('getIdTokenResult: force refresh', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: 'user@example.com', password: 'password');

        var user = r.user!;

        var token1 = await user.getIdTokenResult();
        var token2 = await user.getIdTokenResult();

        expect(token2, token1);

        await Future.delayed(Duration(seconds: 1));
        var token3 = await user.getIdTokenResult(true);

        expect(token3, isNot(token1));
        expect(token3.issuedAtTime!.isAfter(token1.issuedAtTime!), true);
      });

      test('getIdTokenResult: expired token', () async {
        await tester.backend
            .setTokenGenerationSettings(tokenExpiresIn: Duration(seconds: 1));
        var r = await auth.signInWithEmailAndPassword(
            email: 'user@example.com', password: 'password');

        var user = r.user!;

        var token1 = await user.getIdTokenResult();
        await Future.delayed(Duration(seconds: 2));
        expect(token1.expirationTime!.isBefore(clock.now()), true);
        var token2 = await user.getIdTokenResult();

        expect(token2, isNot(token1));
        await tester.backend
            .setTokenGenerationSettings(tokenExpiresIn: Duration(hours: 1));
      });
    });

    group('reload', () {
      test('reload: success', () async {
        var r = await auth.signInWithEmailAndPassword(
            email: 'user@example.com', password: 'password');

        expect(r.user!.email, 'user@example.com');
        var backendUser =
            await tester.backend.getUserByEmail('user@example.com');
        backendUser.email = 'user@fake.com';
        await tester.backend.storeUser(backendUser);

        await r.user!.reload();
        expect(r.user!.email, 'user@fake.com');

        backendUser.email = 'user@example.com';
        await tester.backend.storeUser(backendUser);
      });

      test('reload: user not found error', () async {
        var r = await auth.signInAnonymously();

        await tester.backend.deleteUser(r.user!.uid);

        expect(() => r.user!.reload(),
            throwsA(FirebaseAuthException.userDeleted()));
      });
    });

    group('multiFactor', () {
      group('multiFactor.unenroll', () {
        test('unenroll: success', () async {
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
                PhoneMultiFactorGenerator.getAssertion(
                    await credential.future));

            var user = r.user!;
            expect(user.uid, 'user1');

            var factor = user.multiFactor.enrolledFactors.first;
            await user.multiFactor.unenroll(factorUid: factor.uid);

            expect(user.multiFactor.enrolledFactors, isEmpty);
          }
        });

        test('unenroll with info : success', () async {
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
                PhoneMultiFactorGenerator.getAssertion(
                    await credential.future));

            var user = r.user!;
            expect(user.uid, 'user1');

            var factor = user.multiFactor.enrolledFactors.first;
            await user.multiFactor.unenroll(multiFactorInfo: factor);

            expect(user.multiFactor.enrolledFactors, isEmpty);
          }
        });
      });
    });
  });
}
