import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/rpc/error.dart';
import 'package:firebase_dart/src/auth/rpc/identitytoolkit.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

class BackendConnection {
  final Backend backend;

  BackendConnection(this.backend);

  Future<GetAccountInfoResponse> getAccountInfo(
      IdentitytoolkitRelyingpartyGetAccountInfoRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    return GetAccountInfoResponse()
      ..kind = 'identitytoolkit#GetAccountInfoResponse'
      ..users = [user];
  }

  Future<SignupNewUserResponse> signupNewUser(
      IdentitytoolkitRelyingpartySignupNewUserRequest request) async {
    var user = await backend.createUser(
      email: request.email,
      password: request.password,
    );

    var provider = request.email == null ? 'anonymous' : 'password';

    var idToken =
        await backend.generateIdToken(uid: user.localId, providerId: provider);
    var refreshToken = await backend.generateRefreshToken(user.localId);

    return SignupNewUserResponse()
      ..expiresIn = '3600'
      ..kind = 'identitytoolkit#SignupNewUserResponse'
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<VerifyPasswordResponse> verifyPassword(
      IdentitytoolkitRelyingpartyVerifyPasswordRequest request) async {
    var email = request.email;
    if (email == null) {
      throw ArgumentError('Invalid request: missing email');
    }
    var user = await backend.getUserByEmail(email);

    if (user.rawPassword == request.password) {
      var refreshToken = await backend.generateRefreshToken(user.localId);
      return VerifyPasswordResponse()
        ..kind = 'identitytoolkit#VerifyPasswordResponse'
        ..localId = user.localId
        ..idToken = request.returnSecureToken == true
            ? await backend.generateIdToken(
                uid: user.localId, providerId: 'password')
            : null
        ..expiresIn = '3600'
        ..refreshToken = refreshToken;
    }

    throw FirebaseAuthException.invalidPassword();
  }

  Future<CreateAuthUriResponse> createAuthUri(
      IdentitytoolkitRelyingpartyCreateAuthUriRequest request) async {
    var email = request.identifier;
    if (email == null) {
      throw ArgumentError('Invalid request: missing identifier');
    }
    var user = await backend.getUserByEmail(email);

    return CreateAuthUriResponse()
      ..kind = 'identitytoolkit#CreateAuthUriResponse'
      ..allProviders = [for (var p in user.providerUserInfo!) p.providerId!]
      ..signinMethods = [for (var p in user.providerUserInfo!) p.providerId!];
  }

  Future<VerifyCustomTokenResponse> verifyCustomToken(
      IdentitytoolkitRelyingpartyVerifyCustomTokenRequest request) async {
    var user = await _userFromIdToken(request.token!);

    var refreshToken = await backend.generateRefreshToken(user.localId);
    return VerifyCustomTokenResponse()
      ..idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'custom')
          : null
      ..expiresIn = '3600'
      ..refreshToken = refreshToken;
  }

  Future<DeleteAccountResponse> deleteAccount(
      IdentitytoolkitRelyingpartyDeleteAccountRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    await backend.deleteUser(user.localId);
    return DeleteAccountResponse()
      ..kind = 'identitytoolkit#DeleteAccountResponse';
  }

  Future<BackendUser> _userFromIdToken(String idToken) async {
    var jwt = JsonWebToken.unverified(idToken); // TODO verify
    var uid = jwt.claims['uid'] ?? jwt.claims.subject;
    if (uid == null) {
      throw ArgumentError('Invalid id token (${jwt.claims}): no subject');
    }
    var user = await backend.getUserById(uid);

    return user;
  }

  Future<GetOobConfirmationCodeResponse> getOobConfirmationCode(
      Relyingparty request) async {
    var idToken = request.idToken;
    var email = request.email;
    var user = idToken != null
        ? await _userFromIdToken(idToken)
        : email != null
            ? await backend.getUserByEmail(email)
            : throw ArgumentError('Invalid request: missing idToken or email');
    return GetOobConfirmationCodeResponse()
      ..kind = 'identitytoolkit#GetOobConfirmationCodeResponse'
      ..email = user.email;
  }

  Future<ResetPasswordResponse> resetPassword(
      IdentitytoolkitRelyingpartyResetPasswordRequest request) async {
    BackendUser user;
    try {
      user = await _userFromIdToken(request.oobCode!);
    } on ArgumentError {
      throw FirebaseAuthException.invalidOobCode();
    }
    await backend.updateUser(user..rawPassword = request.newPassword);
    return ResetPasswordResponse()
      ..kind = 'identitytoolkit#ResetPasswordResponse'
      ..email = user.email;
  }

  Future<SetAccountInfoResponse> setAccountInfo(
      IdentitytoolkitRelyingpartySetAccountInfoRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    if (request.deleteProvider != null) {
      user.providerUserInfo!.removeWhere(
          (element) => request.deleteProvider!.contains(element.providerId));
      if (request.deleteProvider!.contains('phone')) {
        user.phoneNumber = null;
      }
    }
    if (request.displayName != null) {
      user.displayName = request.displayName;
    }
    if (request.photoUrl != null) {
      user.photoUrl = request.photoUrl;
    }
    if (request.deleteAttribute != null) {
      for (var a in request.deleteAttribute!) {
        switch (a) {
          case 'displayName':
            user.displayName = null;
            break;
          case 'photoUrl':
            user.photoUrl = null;
            break;
        }
      }
    }
    if (request.email != null) {
      user.email = request.email;
      user.emailVerified = false;
    }

    await backend.updateUser(user);

    return SetAccountInfoResponse()
      ..kind = 'identitytoolkit#SetAccountInfoResponse'
      ..displayName = user.displayName
      ..photoUrl = user.photoUrl
      ..idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'password')
          : null
      ..providerUserInfo = [
        for (var u in user.providerUserInfo!)
          SetAccountInfoResponseProviderUserInfo()
            ..providerId = u.providerId
            ..photoUrl = u.photoUrl
            ..displayName = u.displayName
      ];
  }

  Future<IdentitytoolkitRelyingpartySendVerificationCodeResponse>
      sendVerificationCode(
          IdentitytoolkitRelyingpartySendVerificationCodeRequest
              request) async {
    var phoneNumber = request.phoneNumber;
    if (phoneNumber == null) {
      throw ArgumentError('Invalid request: missing phoneNumber');
    }
    var token = await backend.sendVerificationCode(phoneNumber);
    return IdentitytoolkitRelyingpartySendVerificationCodeResponse()
      ..sessionInfo = token;
  }

  Future<IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse>
      verifyPhoneNumber(
          IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest request) async {
    var sessionInfo = request.sessionInfo;
    if (sessionInfo == null) {
      throw ArgumentError('Invalid request: missing sessionInfo');
    }
    var code = request.code;
    if (code == null) {
      throw ArgumentError('Invalid request: missing code');
    }
    var user = await backend.verifyPhoneNumber(sessionInfo, code);

    return IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse()
      ..localId = user.localId
      ..idToken = await backend.generateIdToken(
          uid: user.localId, providerId: 'password')
      ..expiresIn = '3600'
      ..refreshToken = await backend.generateRefreshToken(user.localId);
  }

  Future<dynamic> _handle(String method, dynamic body) async {
    switch (method) {
      case 'signupNewUser':
        var request =
            IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(body);
        return signupNewUser(request);
      case 'getAccountInfo':
        var request =
            IdentitytoolkitRelyingpartyGetAccountInfoRequest.fromJson(body);
        return getAccountInfo(request);
      case 'verifyPassword':
        var request =
            IdentitytoolkitRelyingpartyVerifyPasswordRequest.fromJson(body);
        return verifyPassword(request);
      case 'createAuthUri':
        var request =
            IdentitytoolkitRelyingpartyCreateAuthUriRequest.fromJson(body);
        return createAuthUri(request);
      case 'verifyCustomToken':
        var request =
            IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(body);
        return verifyCustomToken(request);
      case 'deleteAccount':
        var request =
            IdentitytoolkitRelyingpartyDeleteAccountRequest.fromJson(body);
        return deleteAccount(request);
      case 'getOobConfirmationCode':
        var request = Relyingparty.fromJson(body);
        return getOobConfirmationCode(request);
      case 'resetPassword':
        var request =
            IdentitytoolkitRelyingpartyResetPasswordRequest.fromJson(body);
        return resetPassword(request);
      case 'setAccountInfo':
        var request =
            IdentitytoolkitRelyingpartySetAccountInfoRequest.fromJson(body);
        return setAccountInfo(request);
      case 'sendVerificationCode':
        var request =
            IdentitytoolkitRelyingpartySendVerificationCodeRequest.fromJson(
                body);
        return sendVerificationCode(request);
      case 'verifyPhoneNumber':
        var request =
            IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest.fromJson(body);
        return verifyPhoneNumber(request);
      default:
        throw UnsupportedError('Unsupported method $method');
    }
  }

  Future<http.Response> handleRequest(http.Request request) async {
    var method = request.url.pathSegments.last;

    var body = json.decode(request.body);

    try {
      return http.Response(json.encode(await _handle(method, body)), 200,
          headers: {'content-type': 'application/json'});
    } on FirebaseAuthException catch (e) {
      return http.Response(json.encode(errorToServerResponse(e)), 400,
          headers: {'content-type': 'application/json'});
    }
  }
}

abstract class Backend {
  Future<BackendUser> getUserById(String uid);

  Future<BackendUser> getUserByEmail(String email);

  Future<BackendUser> getUserByPhoneNumber(String phoneNumber);

  Future<BackendUser> createUser(
      {required String? email, required String? password});

  Future<BackendUser> updateUser(BackendUser user);

  Future<void> deleteUser(String uid);

  Future<String> generateIdToken(
      {required String uid, required String providerId});

  Future<String> generateRefreshToken(String uid);

  Future<String> verifyRefreshToken(String token);

  Future<String> sendVerificationCode(String phoneNumber);

  Future<BackendUser> verifyPhoneNumber(String sessionInfo, String code);
}

abstract class BaseBackend extends Backend {
  final JsonWebKey tokenSigningKey;

  final String? projectId;

  BaseBackend({required this.tokenSigningKey, required this.projectId});

  Future<BackendUser> storeUser(BackendUser user);

  @override
  Future<BackendUser> createUser(
      {required String? email, required String? password}) async {
    var uid = _generateRandomString(24);
    var now = (clock.now().millisecondsSinceEpoch ~/ 1000).toString();
    return storeUser(BackendUser(uid)
      ..createdAt = now
      ..lastLoginAt = now
      ..email = email
      ..rawPassword = password
      ..providerUserInfo = [
        if (password != null)
          UserInfoProviderUserInfo()
            ..providerId = 'password'
            ..email = email
      ]);
  }

  @override
  Future<BackendUser> updateUser(BackendUser user) {
    return storeUser(user);
  }

  @override
  Future<String> generateIdToken(
      {required String uid, required String providerId}) async {
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = _jwtPayloadFor(uid, providerId)
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> generateRefreshToken(String uid) async {
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = uid
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> verifyRefreshToken(String token) async {
    var store = JsonWebKeyStore()..addKey(tokenSigningKey);
    var jws = JsonWebSignature.fromCompactSerialization(token);
    var payload = await jws.getPayload(store);
    return payload.jsonContent!;
  }

  static final _random = Random(DateTime.now().millisecondsSinceEpoch);

  static String _generateRandomString(int length) {
    var chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return Iterable.generate(
        length, (i) => chars[_random.nextInt(chars.length)]).join();
  }

  Map<String, dynamic> _jwtPayloadFor(String uid, String providerId) {
    var now = clock.now().millisecondsSinceEpoch ~/ 1000;
    return {
      'iss': 'https://securetoken.google.com/$projectId',
      'provider_id': providerId,
      'aud': '$projectId',
      'auth_time': now,
      'sub': uid,
      'iat': now,
      'exp': now + 3600,
      if (providerId == 'anonymous')
        'firebase': {'identities': {}, 'sign_in_provider': 'anonymous'}
    };
  }
}

class BackendUser extends UserInfo {
  BackendUser(String localId) {
    this.localId = localId;
  }

  @override
  String get localId => super.localId!;
}
