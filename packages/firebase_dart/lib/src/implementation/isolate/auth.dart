import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/subjects.dart';

import '../../auth/auth_mixin.dart';
import '../isolate.dart';
import 'util.dart';

extension UserCredentialX on UserCredential {
  static UserCredential fromJson(
      IsolateFirebaseAuth auth, Map<String, dynamic> json) {
    return UserCredentialImpl(
      user: auth.setUser(json['user']),
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
      operationType: json['operationType'],
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user!.toJson(),
        'additionalUserInfo': {
          'providerId': additionalUserInfo!.providerId,
          'isNewUser': additionalUserInfo!.isNewUser,
          'profile': additionalUserInfo!.profile,
          'username': additionalUserInfo!.username,
        },
        if (credential != null)
          'credential': {
            'providerId': credential!.providerId,
            'signInMethod': credential!.signInMethod,
          },
        'operationType': (this as UserCredentialImpl).operationType
      };
}

class UserBase implements UserInfo {
  Map<String, dynamic> _json;

  UserBase.fromJson(Map<String, dynamic> json) : _json = json;

  @override
  Map<String, dynamic> toJson() => _json;

  @override
  int get hashCode => const DeepCollectionEquality.unordered().hash(_json);

  @override
  bool operator ==(other) =>
      other is IsolateUser &&
      const DeepCollectionEquality.unordered().equals(_json, other._json);

  bool get emailVerified => _json['emailVerified'];

  bool get isAnonymous => _json['isAnonymous'];

  UserMetadata get metadata => UserMetadata(
        creationTime: DateTime.fromMillisecondsSinceEpoch(_json['createdAt']),
        lastSignInTime:
            DateTime.fromMillisecondsSinceEpoch(_json['lastLoginAt']),
      );

  List<UserInfo> get providerData =>
      (_json['providerData'] as List).map((v) => UserInfo.fromJson(v)).toList();

  String? get refreshToken => (_json['token'] ?? {})['refreshToken'];

  String? get tenantId => _json['tenantId'];

  @override
  String? get displayName => _json['displayName'];

  @override
  String? get email => _json['email'];

  @override
  String? get phoneNumber => _json['phoneNumber'];

  @override
  String? get photoURL => _json['photoUrl'];

  @override
  String get providerId => _json['providerId'] ?? 'firebase';

  @override
  String get uid => _json['uid'];
}

class IsolateUser extends UserBase implements User {
  final IsolateFirebaseAuth _auth;

  IsolateUser.fromJson(this._auth, Map<String, dynamic> json)
      : super.fromJson(json);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) {
    return _auth.app.commander.execute(CurrentUserFunctionCall<FutureOr<T>>(
        method, _auth.app.name, uid, positionalArguments, namedArguments));
  }

  @visibleForTesting
  Future<void> setAccountInfo(AccountInfo accountInfo) async {
    await invoke(#setAccountInfo, [accountInfo]);
  }

  @override
  Future<void> delete() async {
    await invoke(#delete, []);
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) {
    return invoke(#getIdToken, [forceRefresh]);
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    return invoke(#getIdTokenResult, [forceRefresh]);
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    return invoke(#linkWithCredential, [credential]);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential) {
    return invoke(#reauthenticateWithCredential, [credential]);
  }

  @override
  Future<void> reload() {
    return invoke(#reload, []);
  }

  @override
  Future<void> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    await invoke(#sendEmailVerification, [actionCodeSettings]);
  }

  @override
  Future<User> unlink(String providerId) async {
    await invoke(#unlink, [providerId]);
    await reload(); // reload to make sure, updated values have arrived in this isolate, can be replaced with other synchronization
    return this;
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    await invoke(#updateEmail, [newEmail]);
    await reload();
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await invoke(#updatePassword, [newPassword]);
    await reload();
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    return invoke(#updatePhoneNumber, [phoneCredential]);
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    await invoke(
        #updateProfile, [], {#displayName: displayName, #photoURL: photoURL});
    await reload();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]) {
    return invoke(#verifyBeforeUpdateEmail, [newEmail, actionCodeSettings]);
  }

  @override
  late final MultiFactor multiFactor = IsolateMultiFactor(this);
}

class IsolateMultiFactor extends MultiFactor {
  final IsolateUser _user;

  IsolateMultiFactor(this._user);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) {
    return _user._auth.app.commander.execute(
        CurrentUserFunctionCall<FutureOr<T>>(method, _user._auth.app.name,
            _user.uid, positionalArguments, namedArguments));
  }

  @override
  Future<void> enroll(MultiFactorAssertion assertion, {String? displayName}) {
    return invoke(
        #multiFactor_enroll, [assertion], {#displayName: displayName});
  }

  @override
  Future<List<MultiFactorInfo>> getEnrolledFactors() async => enrolledFactors;

  @override
  Future<MultiFactorSession> getSession() {
    return invoke(#multiFactor_getSession, []);
  }

  @override
  Future<void> unenroll({String? factorUid, MultiFactorInfo? multiFactorInfo}) {
    return invoke(#multiFactor_unenroll, [],
        {#factorUid: factorUid, #multiFactorInfo: multiFactorInfo});
  }

  @override
  List<MultiFactorInfo> get enrolledFactors => (_user._json['mfaInfo'] as List)
      .map((v) => MultiFactorInfo.fromJson(v))
      .toList();
}

class EncodeCall<T> extends BaseFunctionCall<Future> {
  EncodeCall(FunctionCall<FutureOr<T>?> baseCall) : super([baseCall], {});

  @override
  Function get function {
    return (FunctionCall<FutureOr<T>> baseCall) async {
      try {
        var v = await baseCall.run();
        return encode(v);
      } catch (e, tr) {
        Error.throwWithStackTrace(encodeException(e), tr);
      }
    };
  }

  dynamic encode(T value) {
    if (value is UserCredential) return value.toJson();
    return value;
  }

  T decode(dynamic value, FirebaseAuth auth) {
    if (T == UserCredential) {
      return UserCredentialX.fromJson(auth as IsolateFirebaseAuth, value) as T;
    }
    return value;
  }

  Object encodeException(Object error) {
    if (error is FirebaseAuthMultiFactorException) {
      var resolver = error.resolver as MultiFactorResolverImpl;
      return FirebaseAuthMultiFactorException(IsolateMultiFactorResolver(
          resolver.firebaseAuth.app.name,
          hints: resolver.hints,
          session: resolver.session));
    }
    return error;
  }
}

class IsolateFirebaseAuth extends IsolateFirebaseService
    with FirebaseAuthMixin {
  final BehaviorSubject<User?> _subject = BehaviorSubject(sync: true);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) async {
    var call = EncodeCall(FirebaseAuthFunctionCall<FutureOr<T>>(
        method, app.name, positionalArguments, namedArguments));
    return call.decode(await app.commander.execute(call), this);
  }

  IsolateFirebaseAuth(IsolateFirebaseApp app) : super(app) {
    app.commander
        .subscribe<Map<String, dynamic>?>(FirebaseAuthFunctionCall(
          #userChanges,
          app.name,
        ))
        .forEach((v) => setUser(v));
  }

  @override
  Future<void> applyActionCode(String code) async {
    await invoke(#applyActionCode, [code]);
  }

  @override
  Stream<User?> authStateChanges() =>
      _subject.stream.distinct((a, b) => a?.uid == b?.uid);

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    return await invoke(#checkActionCode, [code]);
  }

  @override
  Future<void> confirmPasswordReset(String oobCode, String newPassword) async {
    await invoke(#confirmPasswordReset, [oobCode, newPassword]);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {String? email, String? password}) async {
    return await invoke(#createUserWithEmailAndPassword, [],
        {#email: email, #password: password});
  }

  @override
  User? get currentUser => _subject.valueOrNull;

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await invoke(#fetchSignInMethodsForEmail, [email]);
  }

  @override
  Future<UserCredential> getRedirectResult() {
    return invoke(#getRedirectResult, []);
  }

  @override
  Stream<User?> idTokenChanges() => _subject
      .cast<IsolateUser?>()
      .map((v) => v?._json['credential']['token'])
      .distinct(const DeepCollectionEquality().equals)
      .map((_) => currentUser);

  @override
  bool isSignInWithEmailLink(String link) {
    return getActionCodeUrlFromSignInEmailLink(link) != null;
  }

  String? _languageCode;

  @override
  String? get languageCode => _languageCode;

  @override
  Future<void> sendPasswordResetEmail(
      {String? email, ActionCodeSettings? actionCodeSettings}) async {
    await invoke(#sendPasswordResetEmail, [],
        {#email: email, #actionCodeSettings: actionCodeSettings});
  }

  @override
  Future<void> sendSignInLinkToEmail(
      {String? email, ActionCodeSettings? actionCodeSettings}) async {
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
    return invoke(#signInWithCredential, [credential]);
  }

  @override
  Future<UserCredential> signInWithCustomToken(String token) {
    return invoke(#signInWithCustomToken, [token]);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {String? email, String? password}) {
    return invoke(
        #signInWithEmailAndPassword, [], {#email: email, #password: password});
  }

  @override
  Future<UserCredential> signInWithEmailLink(
      {String? email, String? emailLink}) {
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
  Stream<User?> userChanges() => _subject.stream;

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    return await invoke(#verifyPasswordResetCode, [code]);
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
    PhoneMultiFactorInfo? multiFactorInfo,
    RecaptchaVerifier? verifier,
  }) async {
    var worker = IsolateWorker()
      ..registerFunction(#verificationCompleted, verificationCompleted)
      ..registerFunction(#verificationFailed, verificationFailed)
      ..registerFunction(#codeSent, codeSent)
      ..registerFunction(#codeAutoRetrievalTimeout, codeAutoRetrievalTimeout);

    await invoke(#verifyPhoneNumber, [
      worker.commander
    ], {
      #phoneNumber: phoneNumber,
      #timeout: timeout,
      #forceResendingToken: forceResendingToken,
      #multiFactorSession: multiFactorSession,
      #multiFactorInfo: multiFactorInfo,
    });
  }

  IsolateUser? setUser(Map<String, dynamic>? json) {
    var last = currentUser as IsolateUser?;

    var uid = json == null ? null : json['uid'];
    if (last?.uid != uid) {
      last = uid == null ? null : IsolateUser.fromJson(this, json!);
    } else if (_subject.hasValue &&
        const DeepCollectionEquality().equals(last?._json, json)) {
      return last;
    }
    if (json != null) {
      last?._json = json;
    }
    _subject.add(last);
    return last;
  }

  @override
  Future<UserCredential?> trySignInWithEmailLink(
      {Future<String?> Function()? askUserForEmail}) {
    var worker = askUserForEmail == null
        ? null
        : (IsolateWorker()
          ..registerFunction(#askUserForEmail, askUserForEmail));

    return invoke(#trySignInWithEmailLink, [worker?.commander]);
  }

  @override
  Future<UserCredential> signInWithAuthProvider(AuthProvider provider) {
    // TODO: implement signInWithAuthProvider
    throw UnimplementedError();
  }
}

class CurrentUserFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;

  final String uid;

  final Symbol functionName;

  CurrentUserFunctionCall(this.functionName, this.appName, this.uid,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  User get user {
    var user = FirebaseAuth.instanceFor(app: Firebase.app(appName)).currentUser;
    if (user?.uid != uid) {
      throw FirebaseAuthException.moduleDestroyed();
    }
    return user!;
  }

  @override
  Function? get function {
    switch (functionName) {
      case #getIdToken:
        return user.getIdToken;
      case #getIdTokenResult:
        return user.getIdTokenResult;
      case #delete:
        return user.delete;
      case #linkWithCredential:
        return user.linkWithCredential;
      case #reauthenticateWithCredential:
        return user.reauthenticateWithCredential;
      case #reload:
        return user.reload;
      case #sendEmailVerification:
        return user.sendEmailVerification;
      case #unlink:
        return (providerId) async => (await user.unlink(providerId)).toJson();
      case #updateEmail:
        return user.updateEmail;
      case #updatePassword:
        return user.updatePassword;
      case #updatePhoneNumber:
        return user.updatePhoneNumber;
      case #updateProfile:
        return user.updateProfile;
      case #verifyBeforeUpdateEmail:
        return user.verifyBeforeUpdateEmail;
      case #setAccountInfo:
        return (user as FirebaseUserImpl).setAccountInfo;
      case #multiFactor_getSession:
        return user.multiFactor.getSession;
      case #multiFactor_enroll:
        return user.multiFactor.enroll;
      case #multiFactor_unenroll:
        return user.multiFactor.unenroll;
    }
    return null;
  }
}

class FirebaseAuthFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final Symbol functionName;

  FirebaseAuthFunctionCall(this.functionName, this.appName,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
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
        return (
          IsolateCommander commander, {
          String? phoneNumber,
          Duration timeout = const Duration(seconds: 30),
          int? forceResendingToken,
          PhoneMultiFactorInfo? multiFactorInfo,
          MultiFactorSession? multiFactorSession,
        }) {
          return auth.verifyPhoneNumber(
              phoneNumber: phoneNumber,
              multiFactorInfo: multiFactorInfo,
              multiFactorSession: multiFactorSession,
              timeout: timeout,
              forceResendingToken: forceResendingToken,
              codeAutoRetrievalTimeout: (verificationId) => commander.execute(
                  RegisteredFunctionCall(
                      #codeAutoRetrievalTimeout, [verificationId])),
              verificationCompleted: (phoneAuthCredential) => commander.execute(
                  RegisteredFunctionCall(
                      #verificationCompleted, [phoneAuthCredential])),
              verificationFailed: (exception) => commander.execute(
                  RegisteredFunctionCall(#verificationFailed, [exception])),
              codeSent: (verificationId, forceResendingToken) => commander.execute(
                  RegisteredFunctionCall(#codeSent, [verificationId, forceResendingToken])));
        };
      case #verifyIosClient:
        return (auth as FirebaseAuthImpl).rpcHandler.verifyIosClient;
      case #userChanges:
        return () =>
            auth.userChanges().map<Map<String, dynamic>?>((v) => v?.toJson());

      case #trySignInWithEmailLink:
        return (IsolateCommander? commander) {
          auth.trySignInWithEmailLink(
              askUserForEmail: commander == null
                  ? null
                  : () {
                      return commander
                          .execute(RegisteredFunctionCall(#askUserForEmail));
                    });
        };
      case #signInWithMultiFactorAssertion:
        return (auth as FirebaseAuthImpl).signInWithMultiFactorAssertion;
    }
    throw UnsupportedError(
        'FirebaseAuthFunctionCall with reference $functionName not supported');
  }
}

class IsolateMultiFactorResolver extends MultiFactorResolver {
  final String appName;

  @override
  final List<MultiFactorInfo> hints;

  @override
  final MultiFactorSession session;

  IsolateMultiFactorResolver(this.appName,
      {required this.hints, required this.session});

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: Firebase.app(appName));

  @override
  Future<UserCredential> resolveSignIn(MultiFactorAssertion assertion) {
    return (auth as IsolateFirebaseAuth)
        .invoke(#signInWithMultiFactorAssertion, [assertion, session]);
  }
}
