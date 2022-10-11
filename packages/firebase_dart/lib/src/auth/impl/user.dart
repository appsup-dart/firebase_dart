import 'dart:async';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/rpc/error.dart';
import 'package:firebase_dart/src/auth/rpc/rpc_handler.dart';
import 'package:firebaseapis/identitytoolkit/v1.dart';
import 'package:openid_client/openid_client.dart' as openid;
import 'package:rxdart/rxdart.dart';

import '../auth.dart';
import '../authhandlers.dart';
import '../multi_factor.dart';

part 'multi_factor.dart';

class FirebaseUserImpl extends User with DelegatingUserInfo {
  final FirebaseAuthImpl _auth;

  RpcHandler get _rpcHandler => _auth.rpcHandler;

  openid.Credential _credential;

  final String? _authDomain;

  @override
  late AccountInfo _accountInfo;

  final List<MultiFactorInfo> _enrolledFactors = [];

  String? _lastAccessToken;

  bool _destroyed = false;

  bool get isDestroyed => _destroyed;

  final BehaviorSubject<String?> _tokenUpdates = BehaviorSubject(sync: true);

  late final BehaviorSubject<User> _updates =
      BehaviorSubject.seeded(this, sync: true);

  FirebaseUserImpl(this._auth, this._credential, [this._authDomain]);

  factory FirebaseUserImpl.fromJson(Map<String, dynamic> user,
      {required FirebaseAuthImpl auth}) {
    if (user['apiKey'] == null) {
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
    firebaseUser.setAccountInfo(AccountInfo.fromJson(user));
    if (user['providerData'] is List) {
      for (var userInfo in user['providerData']) {
        if (userInfo != null) {
          firebaseUser._providerData
              .add(UserInfo.fromJson((userInfo as Map).cast()));
        }
      }
    }
    if (user['mfaInfo'] is List) {
      for (var mfaInfo in user['mfaInfo']) {
        if (mfaInfo != null) {
          firebaseUser._enrolledFactors
              .add(PhoneMultiFactorInfo.fromJson((mfaInfo as Map).cast()));
        }
      }
    }
    firebaseUser._lastAccessToken = credential.response!['accessToken'];
    firebaseUser._tokenUpdates.add(credential.response!['accessToken']);

    return firebaseUser;
  }

  static Future<User> initializeFromOpenidCredential(
      FirebaseAuth auth, openid.Credential credential) async {
    // Initialize the Firebase Auth user.
    var user = FirebaseUserImpl(auth as FirebaseAuthImpl, credential);

    // Updates the user info and data and resolves with a user instance.
    await user.reload();
    return user;
  }

  Stream<String?> get accessTokenChanged => _tokenUpdates.distinct();

  Stream<User> get userChanged => _updates.stream;

  String? get lastAccessToken => _lastAccessToken;

  @override
  Future<void> reload() async {
    _checkDestroyed();
    await _reloadWithoutSaving();
    _updates.add(this);
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async =>
      (await getIdTokenResult(forceRefresh)).token!;

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    _checkDestroyed();

    try {
      var response = await _credential.getTokenResponse(forceRefresh);
      // Only if the access token is refreshed, notify Auth listeners.
      if (response.accessToken != _lastAccessToken) {
        _lastAccessToken = response.accessToken;
        // Auth state change, notify listeners.
        _tokenUpdates.add(response.accessToken);
      }
      return IdTokenResultImpl(response.accessToken!);
    } on openid.OpenIdException {
      await _auth.signOut();
      rethrow;
    } on openid.HttpRequestException catch (e) {
      await _auth.signOut();
      if (e.body is Map && e.body['error'] is Map) {
        var error = authErrorFromServerErrorCode(e.body['error']['message']);
        if (error != null) throw error;
      }
      rethrow;
    }
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
    try {
      var user = await _rpcHandler.getAccountInfoByIdToken(idToken.token!);

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
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(user.lastLoginAt!)),
          createdAt: user.createdAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(user.createdAt!)));
      setAccountInfo(accountInfo);
      _enrolledFactors.addAll([
        if (user.mfaInfo != null)
          for (var info in user.mfaInfo!)
            PhoneMultiFactorInfo(
                displayName: info.displayName,
                enrollmentTimestamp:
                    DateTime.parse(info.enrolledAt!).millisecondsSinceEpoch /
                        1000,
                uid: info.mfaEnrollmentId!,
                phoneNumber: info.phoneInfo!),
      ]);

      _providerData.addAll((user.providerUserInfo ?? []).map((v) => UserInfo(
          providerId: v.providerId!,
          displayName: v.displayName,
          photoURL: v.photoUrl,
          phoneNumber: v.phoneNumber,
          email: v.email,
          uid: v.rawId ?? '')));
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.tokenExpired().code) {
        await _auth.signOut();
      }
      rethrow;
    }
  }

  final List<UserInfo> _providerData = [];

  @override
  List<UserInfo> get providerData => List.from(_providerData);

  @override
  UserMetadata get metadata => UserMetadata(
      creationTime: _accountInfo.createdAt,
      lastSignInTime: _accountInfo.lastLoginAt);

  /// Sets the user account info.
  void setAccountInfo(AccountInfo accountInfo) {
    _accountInfo = accountInfo;
    _providerData.clear();
    _enrolledFactors.clear();
    _updates.add(this);
  }

  /// Ensures the user is still logged
  void _checkDestroyed() {
    if (_destroyed) throw FirebaseAuthException.moduleDestroyed();
  }

  void copy(FirebaseUserImpl? other) {
    // Copy to self.
    if (this == other) {
      return;
    }
    setAccountInfo(other!._accountInfo);
    for (var mfaInfo in other._enrolledFactors) {
      _enrolledFactors.add(mfaInfo);
    }

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
        'providerData': [...providerData.map((v) => v.toJson())],
        'mfaInfo': [..._enrolledFactors.map((v) => v.toJson())],
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

  Future<SignInResult> _signInForExisting(AuthCredential credential) async {
    if (credential is PhoneAuthCredential) {
      return await _auth.rpcHandler.signInWithPhoneNumberForExisting(
          sessionInfo: credential.verificationId,
          code: credential.smsCode,
          phoneNumber: credential.phoneNumber,
          temporaryProof: credential.temporaryProof);
    }

    if (credential is OAuthCredential) {
      return await _auth.rpcHandler.signInWithIdpForExisting(
        postBody: Uri(queryParameters: {
          if (credential.idToken != null) 'id_token': credential.idToken,
          if (credential.accessToken != null)
            'access_token': credential.accessToken,
          if (credential.secret != null)
            'oauth_token_secret': credential.secret,
          'providerId': credential.providerId,
          if (credential.rawNonce != null) 'nonce': credential.rawNonce
        }).query,
        requestUri: 'http://localhost',
      );
    }

    if (credential is EmailAuthCredential) {
      if (credential.password != null) {
        return await _auth.rpcHandler
            .signInWithPassword(credential.email, credential.password);
      } else {
        var actionCodeUrl =
            getActionCodeUrlFromSignInEmailLink(credential.emailLink!);
        if (actionCodeUrl == null) {
          throw FirebaseAuthException.argumentError('Invalid email link!');
        }
        return await _auth.rpcHandler
            .signInWithEmailLink(email!, actionCodeUrl.code);
      }
    }

    if (credential is FirebaseAppAuthCredential) {
      return await _auth.rpcHandler.signInWithIdpForExisting(
          sessionId: credential.sessionId, requestUri: credential.link);
    }

    throw UnimplementedError();
  }

  Future<void> _updateCredential(openid.Credential credential) async {
    if (uid != credential.idToken.claims.subject) {
      throw FirebaseAuthException.userMismatch();
    }

    _credential = credential;

    _lastAccessToken = _credential.idToken.toCompactSerialization();
    _tokenUpdates.add(_lastAccessToken);

    await reload();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) async {
    openid.Credential c;
    try {
      var r = await _signInForExisting(credential);
      c = r.credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.userDeleted().code) {
        throw FirebaseAuthException.userMismatch();
      }
      rethrow;
    }

    await _updateCredential(c);

    return UserCredentialImpl(
        user: this,
        credential: credential,
        additionalUserInfo: createAdditionalUserInfo(
          credential: _credential,
          providerId: credential.providerId,
          isNewUser: false,
        ),
        operationType: UserCredentialImpl.operationTypeReauthenticate);
  }

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    var idToken = await getIdToken();
    var email = await _rpcHandler.sendEmailVerification(idToken: idToken);
    if (email != this.email) {
      // Our local copy does not have an email. If the email changed,
      // reload the user.
      return reload();
    }
  }

  @override
  Future<User> unlink(String providerId) async {
    await _reloadWithoutSaving();
    // Provider already unlinked.
    if (providerData.every((element) => element.providerId != providerId)) {
      throw FirebaseAuthException.noSuchProvider();
    }
    // We delete the providerId given.
    var idToken = await getIdToken();
    var resp = await _rpcHandler.deleteLinkedAccounts(idToken, [providerId]);

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
    if (!remainingProviderIds.contains(PhoneAuthProvider.id)) {
      _accountInfo =
          AccountInfo.fromJson(_accountInfo.toJson()..remove('phoneNumber'));
    }
    _updates.add(this);

    return this;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    var idToken = await getIdToken();
    var result = await _rpcHandler.updateEmail(idToken, newEmail);
    // Calls to SetAccountInfo may invalidate old tokens.
    await _updateTokens(result);
    // Reloads the user to update emailVerified.
    return reload();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    var idToken = await getIdToken();
    var result = await _rpcHandler.updatePassword(idToken, newPassword);
    // Calls to SetAccountInfo may invalidate old tokens.
    await _updateTokens(result);
    // Reloads the user in case email has also been updated and the user
    // was anonymous.
    return reload();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (displayName == null && photoURL == null) {
      // No change, directly return.
      return _checkDestroyed();
    }
    var idToken = await getIdToken();
    var response = await _rpcHandler.updateProfile(idToken, {
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoUrl': photoURL
    });

    // Calls to SetAccountInfo may invalidate old tokens.
    await _updateTokensIfPresent(response);

    // Update properties.
    _accountInfo = AccountInfo.fromJson({
      ..._accountInfo.toJson(),
      'displayName': response.displayName,
      'photoUrl': response.photoUrl
    });

    for (var userInfo in providerData) {
      // Check if password provider is linked.
      if (userInfo.providerId == EmailAuthProvider.id) {
        // If so, update both fields in that provider.
        _providerData[_providerData.indexOf(userInfo)] = UserInfo.fromJson({
          ...userInfo.toJson(),
          'displayName': displayName,
          'photoUrl': photoURL
        });
      }
    }

    _updates.add(this);
  }

  /// Updates the current tokens using a server response, if new tokens are
  /// present and are different from the current ones, and notify the Auth
  /// listeners.
  Future<void> _updateTokensIfPresent(
      GoogleCloudIdentitytoolkitV1SetAccountInfoResponse response) async {
    if (response.idToken != null && _lastAccessToken != response.idToken) {
      var result = await _rpcHandler.handleIdTokenResponse(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        mfaPendingCredential: null,
        mfaInfo: null,
      );

      await _updateTokens(result);
    }
  }

  Future<void> _updateTokens(SignInResult result) async {
    _credential = result.credential;

    _lastAccessToken = _credential.idToken.toCompactSerialization();

    _tokenUpdates.add(_lastAccessToken);

    await Future.microtask(() => null);
  }

  @override
  String get providerId => 'firebase';

  @override
  String? get refreshToken => _credential.refreshToken;

  @override
  // TODO: implement tenantId
  String? get tenantId => null;

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) {
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
            c.expiresAt!.subtract(Duration(minutes: 5)).difference(clock.now());
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
    late Function() callback;

    // When a device goes in stand by for x minutes, a regular timer will fire x
    // minutes later than foreseen. Therefore, we check every 5 seconds if time
    // to fire has passed instead.
    var timeToFire = clock.now().add(duration);
    var timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (clock.now().isAfter(timeToFire)) {
        callback();
      }
    });
    _timers.add(timer);
    callback = () {
      timer.cancel();
      _timers.remove(timer);
      completer.complete();
    };
    return completer.future;
  }

  @override
  late final MultiFactor multiFactor = MultiFactorImpl(this);
}

abstract class DelegatingUserInfo implements UserInfo {
  AccountInfo? get _accountInfo;

  @override
  String get uid => _accountInfo!.uid!;

  @override
  String? get displayName => _accountInfo!.displayName;

  @override
  String? get photoURL => _accountInfo!.photoUrl;

  @override
  String? get email => _accountInfo!.email;

  @override
  String? get phoneNumber => _accountInfo!.phoneNumber;

  bool get isAnonymous => _accountInfo!.isAnonymous!;

  bool get emailVerified => _accountInfo!.emailVerified!;
}

class AccountInfo {
  final String? uid;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final bool? emailVerified;
  final String? phoneNumber;
  final bool? isAnonymous;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  AccountInfo(
      {required this.uid,
      required this.displayName,
      required this.photoUrl,
      required this.email,
      required this.emailVerified,
      required this.phoneNumber,
      required this.isAnonymous,
      required this.createdAt,
      required this.lastLoginAt});

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
  DateTime? get authTime => _idToken.claims.authTime;

  @override
  Map<String, dynamic>? get claims => _idToken.claims.toJson();

  @override
  DateTime get expirationTime => _idToken.claims.expiry;

  @override
  DateTime get issuedAtTime => _idToken.claims.issuedAt;

  @override
  String? get signInProvider =>
      (_idToken.claims['firebase'] ?? {})['sign_in_provider'];

  @override
  int get hashCode => token.hashCode;

  @override
  bool operator ==(other) => other is IdTokenResultImpl && other.token == token;

  @override
  String? get signInSecondFactor =>
      (_idToken.claims['firebase'] ?? {})['sign_in_second_factor'];
}

AdditionalUserInfo createAdditionalUserInfo(
    {openid.Credential? credential,
    String? providerId,
    required bool? isNewUser}) {
  // Provider ID already present.
  if (providerId != null) {
    // TODO
  } else if (credential?.idToken != null) {
    // For all other ID token responses with no providerId, get the required
    // providerId from the ID token itself.
    return GenericAdditionalUserInfo(
      providerId: GenericAdditionalUserInfo._providerIdFromInfo(
          idToken: credential!.idToken.toCompactSerialization()),
      isNewUser: isNewUser ?? false,
    );
  }
  return GenericAdditionalUserInfo(
      providerId: providerId, isNewUser: isNewUser!);
}

class GenericAdditionalUserInfo implements AdditionalUserInfo {
  @override
  final String? providerId;

  @override
  final bool isNewUser;

  @override
  final Map<String, dynamic>? profile;

  @override
  final String? username;

  GenericAdditionalUserInfo(
      {required this.providerId,
      required this.isNewUser,
      this.profile,
      this.username});

  @override
  int get hashCode => Object.hash(providerId, isNewUser);

  @override
  bool operator ==(other) =>
      other is GenericAdditionalUserInfo &&
      other.providerId == providerId &&
      other.isNewUser == isNewUser;

  static String? _providerIdFromInfo(
      {String? providerId, required String idToken}) {
    // Try to get providerId from the ID token if available.
    if (providerId == null) {
      // signInWithPassword/setAccountInfo and signInWithPhoneNumber return an ID token
      // but no providerId. Get providerId from the token itself.
      // isNewUser will be returned for signInWithPhoneNumber.
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
}
