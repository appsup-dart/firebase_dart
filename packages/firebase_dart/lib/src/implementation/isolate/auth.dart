import 'dart:async';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:rxdart/subjects.dart';

import '../isolate.dart';
import 'util.dart';

extension UserCredentialX on UserCredential {
  static UserCredential fromJson(
      IsolateFirebaseAuth auth, Map<String, dynamic> json) {
    return UserCredentialImpl(
      user: IsolateUser.fromJson(auth, json['user']),
      additionalUserInfo: GenericAdditionalUserInfo(
          providerId: json['additionalUserInfo']['providerId'],
          isNewUser: json['additionalUserInfo']['isNewUser'],
          profile: json['additionalUserInfo']['profile'],
          username: json['additionalUserInfo']['username']),
      credential: json.containsKey('credential')
          ? AuthCredential(
              providerId: json['credential']['providerId'],
              signInMethod: json['credential']['signInMethod'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'additionalUserInfo': {
          'providerId': additionalUserInfo.providerId,
          'isNewUser': additionalUserInfo.isNewUser,
          'profile': additionalUserInfo.profile,
          'username': additionalUserInfo.username,
        },
        if (credential != null)
          'credentail': {
            'providerId': credential.providerId,
            'signInMethod': credential.signInMethod,
          },
      };
}

class IsolateUser extends UserInfo implements User {
  @override
  final bool emailVerified;

  @override
  final bool isAnonymous;

  @override
  final UserMetadata metadata;

  @override
  final List<UserInfo> providerData;

  @override
  final String refreshToken;

  @override
  final String tenantId;

  final IsolateFirebaseAuth _auth;

  IsolateUser.fromJson(this._auth, Map<String, dynamic> json)
      : emailVerified = json['emailVerified'],
        isAnonymous = json['isAnonymous'],
        metadata = UserMetadata(
          creationTime: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
          lastSignInTime:
              DateTime.fromMillisecondsSinceEpoch(json['lastLoginAt']),
        ),
        providerData = (json['providerData'] as List)
            .map((v) => UserInfo.fromJson(v))
            .toList(),
        refreshToken = (json['token'] ?? {})['refreshToken'],
        tenantId = json['tenantId'],
        super.fromJson(json);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments]) {
    return _auth.app.commander.execute(CurrentUserFunctionCall<FutureOr<T>>(
        method, _auth.app.name, positionalArguments, namedArguments));
  }

  @override
  Future<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return await invoke(#getIdToken, [forceRefresh]);
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    // TODO: implement getIdTokenResult
    throw UnimplementedError();
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
  Future<void> reload() {
    // TODO: implement reload
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings actionCodeSettings]) {
    // TODO: implement sendEmailVerification
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'emailVerified': emailVerified,
        'isAnonymous': isAnonymous,
        'createdAt': metadata.creationTime.millisecondsSinceEpoch,
        'lastLoginAt': metadata.lastSignInTime.millisecondsSinceEpoch,
        'providerData': providerData.map((v) => v.toJson()).toList(),
        'token': {'refreshToken': refreshToken},
        'tenantId': tenantId,
      };

  @override
  Future<User> unlink(String providerId) {
    // TODO: implement unlink
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail(String newEmail) {
    // TODO: implement updateEmail
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword(String newPassword) {
    // TODO: implement updatePassword
    throw UnimplementedError();
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    // TODO: implement updatePhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({String displayName, String photoURL}) {
    // TODO: implement updateProfile
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings actionCodeSettings]) {
    // TODO: implement verifyBeforeUpdateEmail
    throw UnimplementedError();
  }
}

class EncodeCall<T> extends BaseFunctionCall<Future> {
  EncodeCall(FunctionCall<FutureOr<T>> baseCall) : super([baseCall], {});

  @override
  Function get function {
    return (FunctionCall<FutureOr<T>> baseCall) async {
      var v = await baseCall.run();
      return encode(v);
    };
  }

  dynamic encode(T value) {
    if (value is UserCredential) return value.toJson();
    return value;
  }

  T decode(dynamic value, FirebaseAuth auth) {
    if (T == UserCredential) {
      return UserCredentialX.fromJson(auth, value) as T;
    }
    return value;
  }
}

class IsolateFirebaseAuth extends IsolateFirebaseService
    implements FirebaseAuth {
  final BehaviorSubject<User> _subject = BehaviorSubject();

  Future<T> invoke<T>(Symbol method,
      [List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments]) async {
    var call = EncodeCall(FirebaseAuthFunctionCall<FutureOr<T>>(
        method, app.name, positionalArguments, namedArguments));
    return call.decode(await app.commander.execute(call), this);
  }

  IsolateFirebaseAuth(IsolateFirebaseApp app) : super(app) {
    _subject.addStream(app.commander
        .subscribe<Map<String, dynamic>>(FirebaseAuthFunctionCall(
          #authChanges,
          app.name,
        ))
        .map((v) => v == null ? null : IsolateUser.fromJson(this, v)));
  }

  @override
  Future<void> applyActionCode(String code) async {
    await invoke(#applyActionCode, [code]);
  }

  @override
  Stream<User> authStateChanges() =>
      _subject.stream.distinct((a, b) => a?.uid != b?.uid);

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    // TODO: implement checkActionCode
    throw UnimplementedError();
  }

  @override
  Future<void> confirmPasswordReset(String oobCode, String newPassword) async {
    await invoke(#confirmPasswordReset, [oobCode, newPassword]);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {String email, String password}) async {
    return await invoke(#createUserWithEmailAndPassword, [],
        {#email: email, #password: password});
  }

  @override
  User get currentUser => _subject.valueWrapper.value;

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await invoke(#fetchSignInMethodsForEmail, [email]);
  }

  @override
  Future<UserCredential> getRedirectResult() {
    return invoke(#getRedirectResult, []);
  }

  @override
  Stream<User> idTokenChanges() => _subject.stream;

  @override
  bool isSignInWithEmailLink(String link) {
    // TODO: implement isSignInWithEmailLink
    throw UnimplementedError();
  }

  String _languageCode;

  @override
  String get languageCode => _languageCode;

  @override
  Future<void> sendPasswordResetEmail(
      {String email, ActionCodeSettings actionCodeSettings}) async {
    await invoke(#sendPasswordResetEmail, [],
        {#email: email, #actionCodeSettings: actionCodeSettings});
  }

  @override
  Future<void> sendSignInLinkToEmail(
      {String email, ActionCodeSettings actionCodeSettings}) async {
    await invoke(#sendSignInLinkToEmail, [],
        {#email: email, #actionCodeSettings: actionCodeSettings});
  }

  @override
  Future<void> setLanguageCode(String language) async {
    await invoke(#setLanguageCode, [language]);
    _languageCode = language;
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    await invoke(#setPersistence, [persistence]);
  }

  @override
  Future<UserCredential> signInAnonymously() {
    return invoke(#signInAnonymously, []);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    return invoke(#signInWithCredential, [credential.toJson()]);
  }

  @override
  Future<UserCredential> signInWithCustomToken(String token) {
    return invoke(#signInWithCustomToken, [token]);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {String email, String password}) {
    return invoke(
        #signInWithEmailAndPassword, [], {#email: email, #password: password});
  }

  @override
  Future<UserCredential> signInWithEmailLink({String email, String emailLink}) {
    return invoke(
        #signInWithEmailLink, [], {#email: email, #emailLink: emailLink});
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) {
    return invoke(#signInWithPopup, [provider]);
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    await invoke(#signInWithRedirect, [provider]);
  }

  @override
  Future<void> signOut() async {
    await invoke(#signOut, []);
  }

  @override
  Stream<User> userChanges() {
    // TODO: implement userChanges
    throw UnimplementedError();
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    return await invoke(#verifyPasswordResetCode, [code]);
  }

  @override
  Future<void> verifyPhoneNumber(
      {String phoneNumber,
      verificationCompleted,
      verificationFailed,
      codeSent,
      codeAutoRetrievalTimeout,
      String autoRetrievedSmsCodeForTesting,
      Duration timeout = const Duration(seconds: 30),
      int forceResendingToken}) {
    // TODO: implement verifyPhoneNumber
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithOAuthProvider(String providerId) {
    return invoke(#signInWithOAuthProvider, [providerId]);
  }
}

class CurrentUserFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;

  final Symbol functionName;

  CurrentUserFunctionCall(this.functionName, this.appName,
      [List<dynamic> positionalArguments, Map<Symbol, dynamic> namedArguments])
      : super(positionalArguments, namedArguments);

  User get user =>
      FirebaseAuth.instanceFor(app: Firebase.app(appName)).currentUser;
  @override
  Function get function {
    switch (functionName) {
      case #getIdToken:
        return user.getIdToken;
    }
    return null;
  }
}

class FirebaseAuthFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final Symbol functionName;

  FirebaseAuthFunctionCall(this.functionName, this.appName,
      [List<dynamic> positionalArguments, Map<Symbol, dynamic> namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: Firebase.app(appName));

  @override
  Function get function {
    switch (functionName) {
      case #applyActionCode:
        return auth.applyActionCode;
      case #checkActionCode:
        return auth.checkActionCode;
      case #confirmPasswordReset:
        return auth.confirmPasswordReset;
      case #createUserWithEmailAndPassword:
        return auth.createUserWithEmailAndPassword;
      case #fetchSignInMethodsForEmail:
        return auth.fetchSignInMethodsForEmail;
      case #getRedirectResult:
        return auth.getRedirectResult;
      case #sendPasswordResetEmail:
        return auth.sendPasswordResetEmail;
      case #sendSignInLinkToEmail:
        return auth.sendSignInLinkToEmail;
      case #setLanguageCode:
        return auth.setLanguageCode;
      case #setPersistence:
        return auth.setPersistence;
      case #signInAnonymously:
        return auth.signInAnonymously;
      case #signInWithCredential:
        return auth.signInWithCredential;
      case #signInWithOAuthProvider:
        return auth.signInWithOAuthProvider;
      case #signInWithCustomToken:
        return auth.signInWithCustomToken;
      case #signInWithEmailAndPassword:
        return auth.signInWithEmailAndPassword;
      case #signInWithEmailLink:
        return auth.signInWithEmailLink;
      case #signInWithPopup:
        return auth.signInWithPopup;
      case #signInWithRedirect:
        return auth.signInWithRedirect;
      case #signOut:
        return auth.signOut;
      case #verifyPasswordResetCode:
        return auth.verifyPasswordResetCode;
      case #verifyPhoneNumber:
        return auth.verifyPhoneNumber;
      case #authChanges:
        return () => auth
            .authStateChanges()
            .map<Map<String, dynamic>>((v) => v?.toJson());
    }
    throw UnsupportedError(
        'FirebaseAuthFunctionCall with reference $functionName not supported');
  }
}
