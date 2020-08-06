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

  final UserManager _userStorageManager;

  /// Completes when latest logged in user is loaded from storage
  Future<void> _onReady;

  FirebaseAuthImpl(String apiKey, {Client httpClient})
      : _rpcHandler = RpcHandler(apiKey, httpClient: httpClient),
        _userStorageManager = UserManager(apiKey) {
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

  @override
  Future<FirebaseUser> currentUser() async {
    await _onReady;
    return _currentUser;
  }

  @override
  Stream<FirebaseUser> get onAuthStateChanged =>
      _userStorageManager.onCurrentUserChanged;

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
    var user = await FirebaseUserImpl.initializeFromOpenidCredential(
        _rpcHandler, credential);

    // Check if the same user is already signed in.
    if (_currentUser != null && user.uid == _currentUser.uid) {
      // Same user signed in. Update user data and notify Auth listeners.
      // No need to resubscribe to user events.
      user = _currentUser..copy(user);
      return _handleUserStateChange(_currentUser);
    }

    await _handleUserStateChange(user);
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
