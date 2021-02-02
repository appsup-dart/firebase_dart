import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/impl/user.dart';
import 'package:rxdart/subjects.dart';

import '../isolate.dart';

extension UserCredentialX on UserCredential {
  static UserCredential fromJson(Map<String, dynamic> json) {
    return UserCredentialImpl(
      user: IsolateUser.fromJson(json['user']),
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

  IsolateUser.fromJson(Map<String, dynamic> json)
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

  @override
  Future<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<String> getIdToken([bool forceRefresh = false]) {
    // TODO: implement getIdToken
    throw UnimplementedError();
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

extension ActionCodeInfoX on ActionCodeInfo {
  Map<String, dynamic> toJson() => {'data': data, 'operation': operation};
}

extension ActionCodeSettingsX on ActionCodeSettings {
  static ActionCodeSettings fromJson(Map<String, dynamic> json) =>
      ActionCodeSettings(
        androidPackageName: json['androidPackageName'],
        androidMinimumVersion: json['androidMinimumVersion'],
        androidInstallApp: json['androidInstallApp'],
        dynamicLinkDomain: json['dynamicLinkDomain'],
        handleCodeInApp: json['handleCodeInApp'],
        iOSBundleId: json['iOSBundleId'],
        url: json['url'],
      );

  Map<String, dynamic> toJson() => {
        'androidPackageName': androidPackageName,
        'androidMinimumVersion': androidMinimumVersion,
        'androidInstallApp': androidInstallApp,
        'dynamicLinkDomain': dynamicLinkDomain,
        'handleCodeInApp': handleCodeInApp,
        'iOSBundleId': iOSBundleId,
        'url': url,
      };
}

class IsolateFirebaseAuth extends IsolateFirebaseService
    implements FirebaseAuth {
  final BehaviorSubject<User> _subject = BehaviorSubject();

  IsolateFirebaseAuth(IsolateFirebaseApp app) : super(app, 'auth') {
    _subject.addStream(createStream('authChanges', [], broadcast: true)
        .map((v) => v == null ? null : IsolateUser.fromJson(v)));
  }

  @override
  Future<void> applyActionCode(String code) async {
    await invoke('applyActionCode', [code]);
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
    await invoke('confirmPasswordReset', [oobCode, newPassword]);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(
      {String email, String password}) async {
    return UserCredentialX.fromJson(
        await invoke('createUserWithEmailAndPassword', [email, password]));
  }

  @override
  User get currentUser => _subject.value;

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    return await invoke('fetchSignInMethodsForEmail', [email]);
  }

  @override
  Future<UserCredential> getRedirectResult() async {
    return UserCredentialX.fromJson(await invoke('getRedirectResult', []));
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
    await invoke(
        'sendPasswordResetEmail', [email, actionCodeSettings.toJson()]);
  }

  @override
  Future<void> sendSignInLinkToEmail(
      {String email, ActionCodeSettings actionCodeSettings}) async {
    await invoke('sendSignInLinkToEmail', [email, actionCodeSettings.toJson()]);
  }

  @override
  Future<void> setLanguageCode(String language) async {
    await invoke('setLanguageCode', [language]);
    _languageCode = language;
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    await invoke('setPersistence', [persistence]);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    return UserCredentialX.fromJson(await invoke('signInAnonymously', []));
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return UserCredentialX.fromJson(
        await invoke('signInWithCredential', [credential.toJson()]));
  }

  @override
  Future<UserCredential> signInWithCustomToken(String token) async {
    return UserCredentialX.fromJson(
        await invoke('signInWithCustomToken', [token]));
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword(
      {String email, String password}) async {
    return UserCredentialX.fromJson(
        await invoke('signInWithEmailAndPassword', [email, password]));
  }

  @override
  Future<UserCredential> signInWithEmailLink(
      {String email, String emailLink}) async {
    return UserCredentialX.fromJson(
        await invoke('signInWithEmailLink', [email, emailLink]));
  }

  @override
  Future<UserCredential> signInWithPopup(AuthProvider provider) async {
    return UserCredentialX.fromJson(
        await invoke('signInWithPopup', [provider]));
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    await invoke('signInWithRedirect', [provider]);
  }

  @override
  Future<void> signOut() async {
    await invoke('signOut', []);
  }

  @override
  Stream<User> userChanges() {
    // TODO: implement userChanges
    throw UnimplementedError();
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    return await invoke('verifyPasswordResetCode', [code]);
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
}

class AuthPluginService extends PluginService {
  final FirebaseAuth auth;

  AuthPluginService(this.auth);

  @override
  dynamic invoke(String method, List<dynamic> arguments) {
    switch (method) {
      case 'applyActionCode':
        return auth.applyActionCode(arguments.first);
      case 'checkActionCode':
        return auth.checkActionCode(arguments.first).then((v) => v.toJson());
      case 'confirmPasswordReset':
        return auth.confirmPasswordReset(arguments[0], arguments[1]);
      case 'createUserWithEmailAndPassword':
        return auth
            .createUserWithEmailAndPassword(
                email: arguments[0], password: arguments[1])
            .then((v) => v.toJson());
      case 'fetchSignInMethodsForEmail':
        return auth.fetchSignInMethodsForEmail(arguments.first);
      case 'getRedirectResult':
        return auth.getRedirectResult().then((v) => v.toJson());
      case 'sendPasswordResetEmail':
        return auth.sendPasswordResetEmail(
            email: arguments[0],
            actionCodeSettings: ActionCodeSettingsX.fromJson(arguments[1]));
      case 'sendSignInLinkToEmail':
        return auth.sendSignInLinkToEmail(
            email: arguments[0],
            actionCodeSettings: ActionCodeSettingsX.fromJson(arguments[1]));
      case 'setLanguageCode':
        return auth.setLanguageCode(arguments.first);
      case 'setPersistence':
        return auth.setPersistence(arguments.first);
      case 'signInAnonymously':
        return auth.signInAnonymously().then((v) => v.toJson());
      case 'signInWithCredential':
        return auth
            .signInWithCredential(arguments.first)
            .then((v) => v.toJson());
      case 'signInWithCustomToken':
        return auth
            .signInWithCustomToken(arguments.first)
            .then((v) => v.toJson());
      case 'signInWithEmailAndPassword':
        return auth
            .signInWithEmailAndPassword(
                email: arguments[0], password: arguments[1])
            .then((v) => v.toJson());
      case 'signInWithEmailLink':
        return auth
            .signInWithEmailLink(email: arguments[0], emailLink: arguments[1])
            .then((v) => v.toJson());
      case 'signInWithPopup':
        return auth.signInWithPopup(arguments[0]).then((v) => v.toJson());
      case 'signInWithRedirect':
        return auth.signInWithRedirect(arguments[0]);
      case 'signOut':
        return auth.signOut();
      case 'verifyPasswordResetCode':
        return auth.verifyPasswordResetCode(arguments[0]);
      case 'verifyPhoneNumber':
        throw UnimplementedError(); // TODO
      case 'authChanges':
        return auth.authStateChanges().map((v) => v
            ?.toJson()); // TODO: handle id token changes and other user changes
    }
    throw ArgumentError.value(method, 'method');
  }
}
