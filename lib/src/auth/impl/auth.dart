import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/error.dart';

import '../user.dart';
import '../usermanager.dart';
import 'user.dart';
import '../rpc/rpc_handler.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:openid_client/openid_client.dart' as openid;
import '../authcredential.dart';
import '../auth.dart';

/// The entry point of the Firebase Authentication SDK.
class FirebaseAuthImpl extends FirebaseAuth {
  final RpcHandler _rpcHandler;

  FirebaseUserImpl _currentUser;

  UserManager _userStorageManager;

  UserManager get userStorageManager => _userStorageManager;

  RpcHandler get rpcHandler => _rpcHandler;

  /// Completes when latest logged in user is loaded from storage
  Future<void> _onReady;

  FirebaseAuthImpl(this.app, {Client httpClient})
      : _rpcHandler = RpcHandler(app.options.apiKey, httpClient: httpClient) {
    _userStorageManager = UserManager(this);
    _onReady = _init();
  }

  Future<void> _init() async {
    _currentUser = await _userStorageManager.getCurrentUser();

    _userStorageManager.onCurrentUserChanged.listen((user) {
      _currentUser = user;
    }); // TODO cancel subscription
  }

  @override
  Future<AuthResult> signInAnonymously() async {
    await _onReady;

    var user = _currentUser;

    // If an anonymous user is already signed in, no need to sign him again.
    if (user != null && user.isAnonymous) {
      var additionalUserInfo = createAdditionalUserInfo(isNewUser: false);
      return AuthResultImpl(
          // Return the signed in user reference.
          user: user,
          // Do not return credential for anonymous user.
          credential: null,
          // Return any additional IdP data.
          additionalUserInfo: additionalUserInfo,
          // Sign in operation type.
          operationType: AuthResultImpl.operationTypeSignIn);
    } else {
      // No anonymous user currently signed in.
      var r = await _rpcHandler.signInAnonymously();

      var result = await _signInWithIdTokenProvider(
          openidCredential: r, isNewUser: true);

      await _handleUserStateChange(result.user);
      return result;
    }
  }

  @override
  Future<AuthResult> signInWithEmailAndPassword({
    String email,
    String password,
  }) async {
    var r = await _rpcHandler.verifyPassword(email, password);

    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: false);

    return result;
  }

  /// Handles user state changes.
  Future<void> _handleUserStateChange(FirebaseUser user) {
    return _userStorageManager.setCurrentUser(user);
  }

  /// Signs in with ID token promise provider.
  Future<AuthResult> _signInWithIdTokenProvider(
      {@required openid.Credential openidCredential,
      String provider,
      AuthCredential credential,
      bool isNewUser,
      String kind}) async {
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
    return AuthResultImpl(
      // Return the current user reference.
      user: _currentUser,
      // Return any credential passed from the backend.
      credential: credential,
      // Return any additional IdP data passed from the backend.
      additionalUserInfo: additionalUserInfo,
      // Sign in operation type.
      operationType: AuthResultImpl.operationTypeSignIn,
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
    if (_currentUser != null && user.uid == _currentUser.uid) {
      // Same user signed in. Update user data and notify Auth listeners.
      // No need to resubscribe to user events.
      user = _currentUser..copy(user);
      return _handleUserStateChange(_currentUser);
    }

    await _handleUserStateChange(user);
  }

  @override
  final FirebaseApp app;

  @override
  Future<void> confirmPasswordReset(String oobCode, String newPassword) async {
    await rpcHandler.confirmPasswordReset(oobCode, newPassword);
  }

  @override
  Future<AuthResult> createUserWithEmailAndPassword(
      {String email, String password}) async {
    await _onReady;

    var r = await _rpcHandler.createAccount(email, password);

    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: true);

    return result;
  }

  @override
  Future<FirebaseUser> currentUser() async {
    await _onReady;
    return _currentUser;
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail({String email}) {
    return _rpcHandler.fetchSignInMethodsForIdentifier(email);
  }

  @override
  Future<bool> isSignInWithEmailLink(String link) {
    // TODO: implement isSignInWithEmailLink
    throw UnimplementedError();
  }

  @override
  Stream<FirebaseUser> get onAuthStateChanged =>
      _userStorageManager.onCurrentUserChanged;

  @override
  Future<void> sendPasswordResetEmail({String email}) {
    return rpcHandler.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendSignInWithEmailLink(
      {String email,
      String url,
      bool handleCodeInApp = true,
      String iOSBundleID,
      String androidPackageName,
      bool androidInstallIfNotAvailable,
      String androidMinimumVersion}) async {
    if (url == null) {
      throw AuthException.missingContinueUri();
    }
    if (url.isEmpty) {
      throw AuthException.invalidContinueUri();
    }

    if (handleCodeInApp == false) {
      throw AuthException.argumentError(
          'handleCodeInApp true when sending sign in link to email.');
    }

    await rpcHandler.sendSignInLinkToEmail(
        email: email,
        continueUrl: url,
        canHandleCodeInApp: handleCodeInApp,
        iOSBundleId: iOSBundleID,
        androidPackageName: androidPackageName,
        androidInstallApp: androidInstallIfNotAvailable,
        androidMinimumVersion: androidMinimumVersion);
  }

  @override
  Future<void> setLanguageCode(String language) {
    // TODO: implement setLanguageCode
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signInWithCredential(credential) {
    // TODO: implement signInWithCredential
    throw UnimplementedError();
  }

  @override
  Future<AuthResult> signInWithCustomToken({String token}) async {
    // Wait for the redirect state to be determined before proceeding. If critical
    // errors like web storage unsupported are detected, fail before RPC, instead
    // of after.
    await _onReady;
    var r = await _rpcHandler.verifyCustomToken(token);
    var result =
        await _signInWithIdTokenProvider(openidCredential: r, isNewUser: false);

    return result;
  }

  @override
  Future<AuthResult> signInWithEmailAndLink({String email, String link}) {
    // TODO: implement signInWithEmailAndLink
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }

  @override
  Future<void> verifyPhoneNumber(
      {String phoneNumber,
      Duration timeout,
      int forceResendingToken,
      verificationCompleted,
      verificationFailed,
      codeSent,
      codeAutoRetrievalTimeout}) {
    // TODO: implement verifyPhoneNumber
    throw UnimplementedError();
  }
}

class AuthResultImpl extends AuthResult {
  static const operationTypeSignIn = 'signIn';

  @override
  final FirebaseUserImpl user;

  @override
  final AdditionalUserInfo additionalUserInfo;

  /// Returns the auth credential.
  final AuthCredential credential;

  /// Returns the operation type.
  final String operationType;

  AuthResultImpl(
      {this.user,
      this.additionalUserInfo,
      this.credential,
      this.operationType});
}
