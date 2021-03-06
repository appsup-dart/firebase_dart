import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:openid_client/openid_client.dart' as openid;
import 'package:pedantic/pedantic.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../auth.dart';
import '../rpc/rpc_handler.dart';
import '../usermanager.dart';
import '../utils.dart';
import 'user.dart';

/// The entry point of the Firebase Authentication SDK.
class FirebaseAuthImpl extends FirebaseService implements FirebaseAuth {
  final RpcHandler rpcHandler;

  late final UserManager userStorageManager = UserManager(this);

  /// Completes when latest logged in user is loaded from storage
  late final Future<void> _onReady;

  late StreamSubscription _storageManagerUserChangedSubscription;

  final BehaviorSubject<FirebaseUserImpl?> _currentUser = BehaviorSubject();

  FirebaseAuthImpl(FirebaseApp app, {Client? httpClient})
      : rpcHandler = RpcHandler(app.options.apiKey, httpClient: httpClient),
        super(app) {
    _onReady = _init();
  }

  Future<void> _init() async {
    _currentUser.add(await userStorageManager.getCurrentUser());

    _storageManagerUserChangedSubscription =
        userStorageManager.onCurrentUserChanged.listen((user) {
      if (_currentUser.value != user) {
        _currentUser.value?.destroy();
        user?.initializeProactiveRefresh();
      }
      _currentUser.add(user);
    });
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    await _onReady;

    var user = currentUser;

    // If an anonymous user is already signed in, no need to sign him again.
    if (user != null && user.isAnonymous) {
      var additionalUserInfo = createAdditionalUserInfo(isNewUser: false);
      return UserCredentialImpl(
          // Return the signed in user reference.
          user: user,
          // Do not return credential for anonymous user.
          credential: null,
          // Return any additional IdP data.
          additionalUserInfo: additionalUserInfo,
          // Sign in operation type.
          operationType: UserCredentialImpl.operationTypeSignIn);
    } else {
      // No anonymous user currently signed in.
      var r = await rpcHandler.signInAnonymously();

      var result = await _signInWithIdTokenProvider(
          openidCredential: r, isNewUser: true);

      await _handleUserStateChange(result.user);
      return result;
    }
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    String? password,
  }) async {
    var r = await rpcHandler.verifyPassword(email, password);

    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: false);

    return result;
  }

  /// Handles user state changes.
  Future<void> _handleUserStateChange(User? user) async {
    return userStorageManager.setCurrentUser(user);
  }

  /// Signs in with ID token promise provider.
  Future<UserCredential> _signInWithIdTokenProvider(
      {required openid.Credential openidCredential,
      String? provider,
      AuthCredential? credential,
      bool? isNewUser,
      String? kind}) async {
    // Get additional IdP data if available in the response.
    var additionalUserInfo = createAdditionalUserInfo(
        credential: openidCredential,
        providerId: provider,
        isNewUser: isNewUser,
        kind: kind);

    // When custom token is exchanged for idToken, continue sign in with
    // ID token and return firebase Auth user.
    await _signInWithIdTokenResponse(openidCredential);

    // Resolve promise with a readonly user credential object.
    return UserCredentialImpl(
      // Return the current user reference.
      user: currentUser,
      // Return any credential passed from the backend.
      credential: credential,
      // Return any additional IdP data passed from the backend.
      additionalUserInfo: additionalUserInfo,
      // Sign in operation type.
      operationType: UserCredentialImpl.operationTypeSignIn,
    );
  }

  /// Completes the headless sign in with the server response containing the STS
  /// access and refresh tokens, and sets the Auth user as current user while
  /// setting all listeners to it and saving it to storage.
  Future<void> _signInWithIdTokenResponse(openid.Credential credential) async {
    // Wait for state to be ready.
    await _onReady;

    // Initialize an Auth user using the provided ID token response.
    var user =
        await FirebaseUserImpl.initializeFromOpenidCredential(this, credential);

    // Check if the same user is already signed in.
    if (currentUser != null && user.uid == currentUser!.uid) {
      // Same user signed in. Update user data and notify Auth listeners.
      // No need to resubscribe to user events.
      user = currentUser!..copy(user as FirebaseUserImpl?);
      return _handleUserStateChange(currentUser);
    }

    await _handleUserStateChange(user);
  }

  @override
  Future<void> confirmPasswordReset(String oobCode, String newPassword) async {
    await rpcHandler.confirmPasswordReset(oobCode, newPassword);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {required String email, String? password}) async {
    await _onReady;

    var r = await rpcHandler.createAccount(email, password);

    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: true);

    return result;
  }

  @override
  FirebaseUserImpl? get currentUser => _currentUser.value;

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) {
    return rpcHandler.fetchSignInMethodsForIdentifier(email);
  }

  @override
  bool isSignInWithEmailLink(String link) {
    // TODO: implement isSignInWithEmailLink
    throw UnimplementedError();
  }

  @override
  Stream<User?> authStateChanges() => _currentUser.stream.cast();

  @override
  Future<void> sendPasswordResetEmail(
      {required String email, ActionCodeSettings? actionCodeSettings}) {
    return rpcHandler.sendPasswordResetEmail(
        email: email, actionCodeSettings: actionCodeSettings);
  }

  @override
  Future<void> sendSignInLinkToEmail(
      {required String email,
      required ActionCodeSettings actionCodeSettings}) async {
    if (actionCodeSettings.url.isEmpty) {
      throw FirebaseAuthException.invalidContinueUri();
    }

    if (actionCodeSettings.handleCodeInApp == false) {
      throw FirebaseAuthException.argumentError(
          'handleCodeInApp true when sending sign in link to email.');
    }

    await rpcHandler.sendSignInLinkToEmail(
        email: email, actionCodeSettings: actionCodeSettings);
  }

  @override
  Future<void> setLanguageCode(String language) {
    // TODO: implement setLanguageCode
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    await _onReady;

    if (credential is PhoneAuthCredential) {
      var openidCredential = await rpcHandler.verifyPhoneNumber(
          sessionInfo: credential.verificationId, code: credential.smsCode);
      return _signInWithIdTokenProvider(
        openidCredential: openidCredential,
        credential: credential,
        isNewUser: false,
        provider: credential.providerId,
      );
    }

    if (credential is OAuthCredential) {
      var openidCredential = await rpcHandler.verifyAssertion(
          postBody: Uri(queryParameters: {
            if (credential.idToken != null) 'id_token': credential.idToken,
            if (credential.accessToken != null)
              'access_token': credential.accessToken,
            if (credential.secret != null)
              'oauth_token_secret': credential.secret,
            'providerId': credential.providerId,
            if (credential.rawNonce != null) 'nonce': credential.rawNonce
          }).query,
          requestUri: 'http://localhost');
      return _signInWithIdTokenProvider(
        openidCredential: openidCredential,
        credential: credential,
        isNewUser: false,
        provider: credential.providerId,
      );
    }

    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    // Wait for the redirect state to be determined before proceeding. If critical
    // errors like web storage unsupported are detected, fail before RPC, instead
    // of after.
    await _onReady;
    var r = await rpcHandler.verifyCustomToken(token);
    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: false);

    return result;
  }

  @override
  Future<void> signOut() async {
    await _onReady;
    // Ignore if already signed out.
    if (currentUser == null) {
      return;
    }
    await PureDartFirebaseImplementation.installation
        .oauthSignOut(currentUser!.providerId);
    // Detach all event listeners.
    currentUser!.destroy();
    // Set current user to null.
    await userStorageManager.removeCurrentUser();
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    @visibleForTesting String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
  }) async {
    var assertion = await ApplicationVerifier.instance.verify(this);
    var v = await rpcHandler.sendVerificationCode(
        phoneNumber: phoneNumber, recaptchaToken: assertion);

    codeSent(v, 0 /*TODO*/);

    unawaited(Future.delayed(timeout).then((_) => codeAutoRetrievalTimeout(v)));
  }

  @override
  Future<void> applyActionCode(String code) {
    // TODO: implement applyActionCode
    throw UnimplementedError();
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) {
    // TODO: implement checkActionCode
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithOAuthProvider(String providerId) async {
    var provider = OAuthProvider(providerId);

    var credential =
        await PureDartFirebaseImplementation.installation.oauthSignIn(provider);

    if (credential != null) {
      return signInWithCredential(credential);
    }

    await signInWithRedirect(provider);
    return getRedirectResult();
  }

  @override
  Future<UserCredential> getRedirectResult() async {
    var r = await PureDartFirebaseImplementation.installation.getAuthResult();

    if (r.containsKey('firebaseError')) {
      var e = json.decode(r['firebaseError']);
      throw FirebaseAuthException(e['code'] ?? 'unknown', e['message']);
    }
    var box = await userStorageManager.storage;
    var sessionId = box.get('redirect_session_id');

    var openidCredential = await rpcHandler.verifyAssertion(
        sessionId: sessionId, requestUri: r['link']);

    return _signInWithIdTokenProvider(
      openidCredential: openidCredential,
      isNewUser: false,
    );
  }

  @override
  Stream<User?> idTokenChanges() {
    return authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(user);
      return (user as FirebaseUserImpl).accessTokenChanged.map((_) => user);
    });
  }

  @override
  // TODO: implement languageCode
  String get languageCode => throw UnimplementedError();

  @override
  Future<void> setPersistence(Persistence persistence) {
    // TODO: implement setPersistence
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithEmailLink(
      {String? email, String? emailLink}) {
    // TODO: implement signInWithEmailLink
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) {
    // TODO: implement signInWithPopup
    throw UnimplementedError();
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    if (provider is OAuthProvider) {
      var eventId = Uuid().v4();

      String _randomString([int length = 32]) {
        assert(length > 0);
        var charset =
            '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

        var random = Random.secure();
        return Iterable.generate(
            length, (_) => charset[random.nextInt(charset.length)]).join();
      }

      var sessionId = _randomString();

      var box = await userStorageManager.storage;
      await box.put('redirect_session_id', sessionId);

      var platform = Platform.current;

      var url = Uri(
          scheme: 'https',
          host: app.options.authDomain,
          path: '__/auth/handler',
          queryParameters: {
            // TODO: version 'v': 'X$clientVersion',
            'authType': 'signInWithRedirect',
            'apiKey': app.options.apiKey,
            'providerId': provider.providerId,
            if (provider.scopes.isNotEmpty) 'scopes': provider.scopes.join(','),
            if (provider.parameters != null)
              'customParameters': json.encode(provider.parameters),
            // TODO: if (tenantId != null) 'tid': tenantId

            'eventId': eventId,

            if (platform is AndroidPlatform) ...{
              'eid': 'p',
              'sessionId': sessionId,
              'apn': platform.packageId,
              'sha1Cert': platform.sha1Cert.replaceAll(':', '').toLowerCase(),
              'publicKey':
                  '...', // seems encryption is not used, but public key needs to be present to assemble the correct redirect url
            },
            if (platform is IOsPlatform) ...{
              'sessionId': sessionId,
              'ibi': platform.appId,
              if (app.options.iosClientId != null)
                'clientId': app.options.iosClientId
              else
                'appId': app.options.appId,
            },
            if (platform is MacOsPlatform) ...{
              'sessionId': sessionId,
              'ibi': platform.appId,
              if (app.options.iosClientId != null)
                'clientId': app.options.iosClientId
              else
                'appId': app.options.appId,
            },
            if (platform is WebPlatform) ...{
              'redirectUrl': platform.currentUrl,
              'appName': app.name,
            }
          });
      await PureDartFirebaseImplementation.installation.launchUrl(url);
      return;
    }
    // TODO: implement signInWithRedirect
    throw UnimplementedError();
  }

  @override
  Stream<User?> userChanges() {
    return authStateChanges().switchMap((value) =>
        (value as FirebaseUserImpl?)?.userChanged ?? Stream.value(null));
  }

  @override
  Future<String> verifyPasswordResetCode(String code) {
    // TODO: implement verifyPasswordResetCode
    throw UnimplementedError();
  }

  @override
  String toString() {
    return 'FirebaseAuth(app: ${app.name})';
  }

  @override
  Future<void> delete() async {
    await _onReady;
    currentUser?.destroy();
    await userStorageManager.close();
    await _storageManagerUserChangedSubscription.cancel();
    await _currentUser.close();
    await super.delete();
  }
}

class UserCredentialImpl extends UserCredential {
  static const operationTypeSignIn = 'signIn';

  @override
  final User? user;

  @override
  final AdditionalUserInfo additionalUserInfo;

  @override
  final AuthCredential? credential;

  /// Returns the operation type.
  final String? operationType;

  UserCredentialImpl(
      {required this.user,
      required this.additionalUserInfo,
      required this.credential,
      required this.operationType});
}
