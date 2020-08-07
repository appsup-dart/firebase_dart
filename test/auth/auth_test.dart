import 'dart:io';

import 'package:clock/clock.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart';
import 'package:firebase_dart/src/auth/backend/memory_backend.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';
import 'package:hive/hive.dart';
import 'package:mockito/mockito.dart';

import 'jwt_util.dart';
import 'util.dart';

import 'package:test/test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;

const identityToolkitBaseUrl =
    'https://www.googleapis.com/identitytoolkit/v3/relyingparty';

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

  group('signInAnonymously', () {
    test('signInAnonymously: success', () async {
      var result = await auth.signInAnonymously() as AuthResultImpl;

      expect(result.user.uid, hasLength(24));
      expect(result.credential, isNull);
      expect(result.additionalUserInfo.providerId, isNull);
      expect(result.additionalUserInfo.isNewUser, isTrue);
      expect(result.operationType, AuthResultImpl.operationTypeSignIn);

      expect(result.user.isAnonymous, isTrue);

      // Confirm anonymous state saved.
      var user = await auth.userStorageManager.getCurrentUser();
      expect(user.toJson(), result.user.toJson());
      expect(user.isAnonymous, isTrue);
    });

    test('signInAnonymously: anonymous user already signed in', () async {
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
      var s = auth.onAuthStateChanged.listen((user) {
        stateChanged++;
        expect(stateChanged, 1);
        expect(user.uid, uid);
      });
      // signInAnonymously should resolve with the already signed in anonymous
      // user without calling RPC handler underneath.
      var result = await auth.signInAnonymously() as AuthResultImpl;
      expect(result.user.toJson(), user.toJson());
      expect(result.additionalUserInfo,
          GenericAdditionalUserInfo(providerId: null, isNewUser: false));
      expect(result.operationType, AuthResultImpl.operationTypeSignIn);
      expect(await auth.currentUser(), result.user);
      expect(result.user.isAnonymous, isTrue);

      // Save reference to current user.
      var currentUser = await auth.currentUser();

      // Sign in anonymously again.
      result = await auth.signInAnonymously();

      // Exact same reference should be returned.
      expect(result.user, same(currentUser));

      await s.cancel();
    });

    test('signInAnonymously: error', () {
      tester.disconnect();

      expect(() => auth.signInAnonymously(),
          throwsA(AuthException.internalError()));
    });
  });

  group('signInWithEmailAndPassword', () {
    test('signInWithEmailAndPassword: success', () async {
      // Expected email and password.
      var expectedEmail = 'user@example.com';
      var expectedPass = 'password';

      var result = await auth.signInWithEmailAndPassword(
          email: expectedEmail, password: expectedPass) as AuthResultImpl;

      print(result.user.email);
      expect(result.user.uid, 'user1');
      expect(result.credential, isNull);
      expect(result.additionalUserInfo.providerId, 'password');
      expect(result.additionalUserInfo.isNewUser, isFalse);
      expect(result.operationType, AuthResultImpl.operationTypeSignIn);

      expect(result.user.isAnonymous, isFalse);
    });

    test('signInWithEmailAndPassword: wrong password', () async {
      expect(
          () => auth.signInWithEmailAndPassword(
              email: 'user@example.com', password: 'wrong_password'),
          throwsA(AuthException.invalidPassword()));
    });
  });

  group('fetchSignInMethodsForEmail', () {
    test('fetchSignInMethodsForEmail: success', () async {
      var signInMethods =
          await auth.fetchSignInMethodsForEmail(email: 'user@example.com');

      expect(signInMethods, ['password', 'google.com']);
    });
  });

  group('signInWithCustomToken', () {
    test('signInWithCustomToken: success', () async {
      var expectedCustomToken = createMockCustomToken(uid: 'user1');
      // Sign in with custom token.
      var result = await auth.signInWithCustomToken(token: expectedCustomToken);

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

  group('createUserWithEmailAndPassword', () {
    test('createUserWithEmailAndPassword: success', () async {
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
}

class Tester {
  final MemoryBackend backend =
      MemoryBackend(tokenSigningKey: key, projectId: '12345678')
        ..storeUser(UserInfo()
          ..localId = 'user1'
          ..createdAt = clock.now().millisecondsSinceEpoch.toString()
          ..lastLoginAt = clock.now().millisecondsSinceEpoch.toString()
          ..email = 'user@example.com'
          ..rawPassword = 'password'
          ..providerUserInfo = [
            UserInfoProviderUserInfo()..providerId = 'password',
            UserInfoProviderUserInfo()..providerId = 'google.com',
          ]);

  BackendConnection _connection;

  http.Client _httpClient;

  FirebaseAuthImpl _auth;

  http.Client get httpClient => _httpClient;

  FirebaseAuthImpl get auth => _auth;

  Tester(FirebaseApp app) {
    mockOpenidResponses();

    _httpClient = ProxyClient({
      RegExp(r'https:\/\/securetoken.google.com\/.*'): mockHttpClient,
      RegExp('.*'): http.MockClient((r) {
        try {
          return _connection.handleRequest(r);
        } catch (e) {
          throw AuthException.internalError();
        }
      })
    });

    _auth = FirebaseAuthImpl(app, httpClient: httpClient);

    connect();
  }

  void connect() {
    _connection = BackendConnection(backend);
  }

  void disconnect() {
    _connection = null;
  }
}

class MockBackendConnection extends Mock implements BackendConnection {}
