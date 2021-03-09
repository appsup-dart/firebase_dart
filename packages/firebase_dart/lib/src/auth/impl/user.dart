import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart'
    show SetAccountInfoResponse;
import 'package:firebase_dart/src/auth/rpc/rpc_handler.dart';
import 'package:meta/meta.dart';
import 'package:openid_client/openid_client.dart' as openid;
import 'package:quiver/core.dart';
import 'package:rxdart/rxdart.dart';

import '../auth.dart';

class FirebaseUserImpl extends User with DelegatingUserInfo {
  final FirebaseAuthImpl _auth;

  RpcHandler get _rpcHandler => _auth.rpcHandler;

  openid.Credential _credential;

  final String _authDomain;

  @override
  AccountInfo _accountInfo;

  String _lastAccessToken;

  bool _destroyed = false;

  bool get isDestroyed => _destroyed;

  final BehaviorSubject<String> _tokenUpdates = BehaviorSubject();

  FirebaseUserImpl(this._auth, this._credential, [this._authDomain])
      : assert(_auth != null);

  factory FirebaseUserImpl.fromJson(Map<String, dynamic> user,
      {@required FirebaseAuthImpl auth}) {
    assert(auth != null);
    if (user == null || user['apiKey'] == null) {
      throw ArgumentError.value(
          user, 'user', 'does not contain an `apiKey` field');
    }

    // Convert to server response format. Constructor does not take
    // stsTokenManager toPlainObject as that format is different than the return
    // server response which is always used to initialize a user instance.
    var credential = openid.Credential.fromJson(
        (user['credential'] as Map).cast(),
        httpClient: auth.rpcHandler.httpClient);
    var firebaseUser = FirebaseUserImpl(auth, credential, user['authDomain']);
    firebaseUser._setAccountInfo(AccountInfo.fromJson(user));
    if (user['providerData'] is List) {
      for (var userInfo in user['providerData']) {
        if (userInfo != null) {
          firebaseUser._providerData
              .add(UserInfo.fromJson((userInfo as Map).cast()));
        }
      }
    }
    firebaseUser._lastAccessToken = credential.response['accessToken'];
    firebaseUser._tokenUpdates.add(credential.response['accessToken']);

    return firebaseUser;
  }

  static Future<User> initializeFromOpenidCredential(
      FirebaseAuth auth, openid.Credential credential) async {
    // Initialize the Firebase Auth user.
    var user = FirebaseUserImpl(auth, credential);

    // Updates the user info and data and resolves with a user instance.
    await user.reload();
    return user;
  }

  Stream<String> get accessTokenChanged => _tokenUpdates.stream.distinct();

  String get lastAccessToken => _lastAccessToken;

  @override
  Future<void> reload() async {
    _checkDestroyed();
    await _reloadWithoutSaving();
    // TODO notify auth listeners
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async =>
      (await getIdTokenResult(forceRefresh)).token;

  @override
  Future<IdTokenResult> getIdTokenResult([bool refresh = false]) async {
    _checkDestroyed();

    var response = await _credential.getTokenResponse(refresh);

    if (response == null) {
      // If the user exists, the token manager should be initialized.
      throw FirebaseAuthException.internalError();
    }
    // Only if the access token is refreshed, notify Auth listeners.
    if (response.accessToken != _lastAccessToken) {
      _lastAccessToken = response.accessToken;
      // Auth state change, notify listeners.
      _tokenUpdates.add(response.accessToken);
    }
    return IdTokenResultImpl(response.accessToken);
  }

  void destroy() {
    _destroyed = true;
    _timers
      ..forEach((t) => t.cancel())
      ..clear();
  }

  /// Refreshes the current user, if signed in.
  Future<void> _reloadWithoutSaving() async {
    // ID token is required to refresh the user's data.
    // If this is called after invalidation, getToken will throw the cached error.
    var idToken = await getIdTokenResult();

    await _setUserAccountInfoFromToken(idToken);
  }

  /// Queries the backend using the provided ID token for all linked accounts to
  /// build the Firebase user object.
  Future<void> _setUserAccountInfoFromToken(IdTokenResult idToken) async {
    var resp = await _rpcHandler.getAccountInfoByIdToken(idToken.token);

    if (resp.users.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    var user = resp.users.first;
    var accountInfo = AccountInfo(
        uid: user.localId,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        email: user.email,
        emailVerified: user.emailVerified ?? false,
        phoneNumber: user.phoneNumber,
        isAnonymous: _credential.idToken.claims['provider_id'] == 'anonymous',
        lastLoginAt: user.lastLoginAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(int.parse(user.lastLoginAt)),
        createdAt: user.createdAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(int.parse(user.createdAt)));
    _setAccountInfo(accountInfo);

    _providerData.addAll((user.providerUserInfo ?? []).map((v) => UserInfo(
        providerId: v.providerId,
        displayName: v.displayName,
        photoURL: v.photoUrl,
        phoneNumber: v.phoneNumber,
        email: v.email,
        uid: v.rawId)));
  }

  final List<UserInfo> _providerData = [];

  @override
  List<UserInfo> get providerData => List.from(_providerData);

  @override
  UserMetadata get metadata => UserMetadata(
      creationTime: _accountInfo.createdAt,
      lastSignInTime: _accountInfo.lastLoginAt);

  /// Sets the user account info.
  void _setAccountInfo(AccountInfo accountInfo) {
    _accountInfo = accountInfo;
    _providerData.clear();
  }

  /// Ensures the user is still logged
  void _checkDestroyed() {
    if (_destroyed) throw FirebaseAuthException.moduleDestroyed();
  }

  void copy(FirebaseUserImpl other) {
    // Copy to self.
    if (this == other) {
      return;
    }
    _setAccountInfo(other._accountInfo);

    for (var userInfo in other.providerData) {
      _providerData.add(userInfo);
    }
    _credential = other._credential;
  }

  @override
  Map<String, dynamic> toJson() => {
        'apiKey': _rpcHandler.apiKey,
        if (_authDomain != null) 'authDomain': _authDomain,
        ..._accountInfo.toJson(),
        'credential': _credential.toJson(),
        'providerData': [...providerData.map((v) => v.toJson())]
      };

  @override
  Future<void> delete() async {
    var idToken = await getIdToken();
    try {
      await _rpcHandler.deleteAccount(idToken);
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.tokenExpired().code) {
        // user already deleted
      } else {
        rethrow;
      }
    }

    // A deleted user will be treated like a sign out event.
    await _auth.signOut();
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    // TODO: implement linkWithCredential
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) {
    // TODO: implement reauthenticateWithCredential
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings actionCodeSettings]) async {
    var idToken = await getIdToken();
    var email = await _rpcHandler.sendEmailVerification(idToken: idToken);
    if (email != this.email) {
      // Our local copy does not have an email. If the email changed,
      // reload the user.
      return reload();
    }
  }

  @override
  Future<User> unlink(String provider) async {
    await _reloadWithoutSaving();
    // Provider already unlinked.
    if (providerData.every((element) => element.providerId != provider)) {
      throw FirebaseAuthException.noSuchProvider();
    }
    // We delete the providerId given.
    var idToken = await getIdToken();
    var resp = await _rpcHandler.deleteLinkedAccounts(idToken, [provider]);

    // Construct the set of provider IDs returned by server.
    var userInfo = resp.providerUserInfo ?? [];
    var remainingProviderIds = userInfo.map((v) => v.providerId).toSet();

    // Remove all provider data objects where the provider ID no
    // longer exists in this user.
    for (var d in providerData) {
      if (remainingProviderIds.contains(d.providerId)) continue;
      // This provider no longer linked, remove it from user.
      _providerData.remove(d);
    }

    // Remove the phone number if the phone provider was unlinked.
    if (!remainingProviderIds.contains(PhoneAuthProvider.PROVIDER_ID)) {
      _accountInfo =
          AccountInfo.fromJson(_accountInfo.toJson()..remove('phoneNumber'));
    }

    return this;
  }

  @override
  Future<void> updateEmail(String email) async {
    var idToken = await getIdToken();
    var response = await _rpcHandler.updateEmail(idToken, email);
    // Calls to SetAccountInfo may invalidate old tokens.
    _updateTokensIfPresent(response);
    // Reloads the user to update emailVerified.
    return reload();
  }

  @override
  Future<void> updatePassword(String password) async {
    var idToken = await getIdToken();
    var response = await _rpcHandler.updatePassword(idToken, password);
    // Calls to SetAccountInfo may invalidate old tokens.
    _updateTokensIfPresent(response);
    // Reloads the user in case email has also been updated and the user
    // was anonymous.
    return reload();
  }

  @override
  Future<void> updateProfile({String displayName, String photoURL}) async {
    if (displayName == null && photoURL == null) {
      // No change, directly return.
      return _checkDestroyed();
    }
    var idToken = await getIdToken();
    var response = await _rpcHandler.updateProfile(
        idToken, {'displayName': displayName, 'photoUrl': photoURL});

    // Calls to SetAccountInfo may invalidate old tokens.
    _updateTokensIfPresent(response);

    // Update properties.
    _accountInfo = AccountInfo.fromJson({
      ..._accountInfo.toJson(),
      'displayName': response.displayName,
      'photoUrl': response.photoUrl
    });

    for (var userInfo in providerData) {
      // Check if password provider is linked.
      if (userInfo.providerId == EmailAuthProvider.PROVIDER_ID) {
        // If so, update both fields in that provider.
        _providerData[_providerData.indexOf(userInfo)] = UserInfo.fromJson({
          ...userInfo.toJson(),
          'displayName': displayName,
          'photoUrl': photoURL
        });
      }
    }
  }

  /// Updates the current tokens using a server response, if new tokens are
  /// present and are different from the current ones, and notify the Auth
  /// listeners.
  void _updateTokensIfPresent(SetAccountInfoResponse response) async {
    if (response.idToken != null && _lastAccessToken != response.idToken) {
      _credential = await _rpcHandler.handleIdTokenResponse(response);

      _lastAccessToken = response.idToken;

      _tokenUpdates.add(response.idToken);
    }
  }

  @override
  String get providerId => 'firebase';

  @override
  String get refreshToken => _credential.refreshToken;

  @override
  // TODO: implement tenantId
  String get tenantId => null;

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings actionCodeSettings]) {
    // TODO: implement verifyBeforeUpdateEmail
    throw UnimplementedError();
  }

  void initializeProactiveRefresh() async {
    var nextMinDuration = Duration();
    var forceRefresh = false;

    while (!_destroyed) {
      try {
        await getIdTokenResult(forceRefresh);
        var c = await _credential.getTokenResponse();
        nextMinDuration = Duration();
        var t =
            c.expiresAt.subtract(Duration(minutes: 5)).difference(clock.now());
        forceRefresh = true;
        if (t.isNegative) t = Duration();
        await _wait(t);
      } catch (e) {
        if (nextMinDuration.inSeconds == 0) {
          nextMinDuration = Duration(seconds: 30);
        } else {
          nextMinDuration *= 2;
        }
        if (nextMinDuration > Duration(minutes: 16)) {
          nextMinDuration = Duration(minutes: 16);
        }
        await _wait(nextMinDuration);
      }
    }
  }

  final List<Timer> _timers = [];
  Future<void> _wait(Duration duration) {
    if (duration == Duration()) return Future.microtask(() => null);
    var completer = Completer<void>();
    Function() callback;
    var timer = Timer(duration, () async {
      callback();
    });
    _timers.add(timer);
    callback = () {
      _timers.remove(timer);
      completer.complete();
    };
    return completer.future;
  }
}

abstract class DelegatingUserInfo implements UserInfo {
  AccountInfo get _accountInfo;

  @override
  String get uid => _accountInfo.uid;

  @override
  String get displayName => _accountInfo.displayName;

  @override
  String get photoURL => _accountInfo.photoUrl;

  @override
  String get email => _accountInfo.email;

  @override
  String get phoneNumber => _accountInfo.phoneNumber;

  bool get isAnonymous => _accountInfo.isAnonymous;

  bool get emailVerified => _accountInfo.emailVerified;
}

class AccountInfo {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String email;
  final bool emailVerified;
  final String phoneNumber;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  AccountInfo(
      {this.uid,
      this.displayName,
      this.photoUrl,
      this.email,
      this.emailVerified,
      this.phoneNumber,
      this.isAnonymous,
      this.createdAt,
      this.lastLoginAt});

  AccountInfo.fromJson(Map<String, dynamic> json)
      : this(
            uid: json['uid'],
            displayName: json['displayName'],
            photoUrl: json['photoUrl'],
            email: json['email'],
            emailVerified: json['emailVerified'],
            phoneNumber: json['phoneNumber'],
            isAnonymous: json['isAnonymous'],
            createdAt: json['createdAt'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
            lastLoginAt: json['lastLoginAt'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt']));

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'email': email,
        'emailVerified': emailVerified,
        'phoneNumber': phoneNumber,
        'isAnonymous': isAnonymous,
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      };
}

class IdTokenResultImpl extends IdTokenResult {
  @override
  final String token;

  final openid.IdToken _idToken;

  IdTokenResultImpl(this.token) : _idToken = openid.IdToken.unverified(token);

  @override
  DateTime get authTime => _idToken.claims.authTime;

  @override
  Map<String, dynamic> get claims => _idToken.claims.toJson();

  @override
  DateTime get expirationTime => _idToken.claims.expiry;

  @override
  DateTime get issuedAtTime => _idToken.claims.issuedAt;

  @override
  String get signInProvider =>
      (_idToken.claims['firebase'] ?? {})['sign_in_provider'];
}

AdditionalUserInfo createAdditionalUserInfo(
    {openid.Credential credential,
    String providerId,
    bool isNewUser,
    String kind}) {
  // Provider ID already present.
  if (providerId != null) {
    // TODO
  } else if (credential?.idToken != null) {
    // For all other ID token responses with no providerId, get the required
    // providerId from the ID token itself.
    return GenericAdditionalUserInfo(
        providerId: GenericAdditionalUserInfo._providerIdFromInfo(
            idToken: credential.idToken.toCompactSerialization()),
        isNewUser: GenericAdditionalUserInfo._isNewUserFromInfo(
            isNewUser: isNewUser, kind: kind));
  }
  return GenericAdditionalUserInfo(
      providerId: providerId, isNewUser: isNewUser);
}

class GenericAdditionalUserInfo implements AdditionalUserInfo {
  @override
  final String providerId;

  @override
  final bool isNewUser;

  @override
  final Map<String, dynamic> profile;

  @override
  final String username;

  GenericAdditionalUserInfo(
      {this.providerId, this.isNewUser, this.profile, this.username});

  @override
  int get hashCode => hash2(providerId, isNewUser);

  @override
  bool operator ==(other) =>
      other is GenericAdditionalUserInfo &&
      other.providerId == providerId &&
      other.isNewUser == isNewUser;

  static String _providerIdFromInfo({String providerId, String idToken}) {
    // Try to get providerId from the ID token if available.
    if (providerId == null && idToken != null) {
      // verifyPassword/setAccountInfo and verifyPhoneNumber return an ID token
      // but no providerId. Get providerId from the token itself.
      // isNewUser will be returned for verifyPhoneNumber.
      var token = openid.IdToken.unverified(idToken);
      providerId = token.claims.getTyped('provider_id') ??
          (token.claims['firebase'] ?? {})['sign_in_provider'];
    }
    if (providerId == null) {
      // This is internal only.
      throw Exception('Invalid additional user info!');
    }
    // For custom token and anonymous token, set provider ID to null.
    if (providerId == 'anonymous' || providerId == 'custom') {
      providerId = null;
    }

    return providerId;
  }

  static bool _isNewUserFromInfo({String kind, bool isNewUser}) {
    // Check whether user is new. Temporary Solution since backend does not return
    // isNewUser field for SignupNewUserResponse.
    if (isNewUser != null) return isNewUser;

    if (kind == 'identitytoolkit#SignupNewUserResponse') {
      //For SignupNewUserResponse, always set isNewUser to true.
      return true;
    }
    return false;
  }
}
