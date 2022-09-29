import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/error.dart';
import 'package:firebase_dart/src/auth/rpc/error.dart';
import 'package:firebaseapis/identitytoolkit/v1.dart';
import 'package:firebaseapis/identitytoolkit/v2.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:uuid/uuid.dart';

class BackendConnection {
  final AuthBackend backend;

  BackendConnection(this.backend);

  Future<GoogleCloudIdentitytoolkitV1GetAccountInfoResponse> getAccountInfo(
      GoogleCloudIdentitytoolkitV1GetAccountInfoRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    return GoogleCloudIdentitytoolkitV1GetAccountInfoResponse()..users = [user];
  }

  Future<GoogleCloudIdentitytoolkitV1SignUpResponse> signupNewUser(
      GoogleCloudIdentitytoolkitV1SignUpRequest request) async {
    var user = await backend.createUser(
      email: request.email,
      password: request.password,
    );

    var provider = request.email == null ? 'anonymous' : 'password';

    var idToken =
        await backend.generateIdToken(uid: user.localId, providerId: provider);
    var refreshToken = await backend.generateRefreshToken(idToken);

    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return GoogleCloudIdentitytoolkitV1SignUpResponse()
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV1SignInWithPasswordResponse>
      signInWithPassword(
          GoogleCloudIdentitytoolkitV1SignInWithPasswordRequest request) async {
    var email = request.email;
    if (email == null) {
      throw ArgumentError('Invalid request: missing email');
    }
    var user = await backend.getUserByEmail(email);

    if (user.rawPassword == request.password) {
      if (user.mfaInfo != null && user.mfaInfo!.isNotEmpty) {
        return GoogleCloudIdentitytoolkitV1SignInWithPasswordResponse()
          ..localId = user.localId
          ..mfaPendingCredential = (JsonWebSignatureBuilder()
                ..jsonContent = {
                  'uid': user.localId,
                }
                ..addRecipient(await backend.getTokenSigningKey()))
              .build()
              .toCompactSerialization()
          ..mfaInfo = user.mfaInfo;
      }
      var idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'password')
          : null;
      var refreshToken =
          idToken == null ? null : await backend.generateRefreshToken(idToken);
      var tokenExpiresIn = await backend.getTokenExpiresIn();
      return GoogleCloudIdentitytoolkitV1SignInWithPasswordResponse()
        ..localId = user.localId
        ..idToken = idToken
        ..expiresIn = '${tokenExpiresIn.inSeconds}'
        ..refreshToken = refreshToken;
    }

    throw FirebaseAuthException.invalidPassword();
  }

  Future<GoogleCloudIdentitytoolkitV1CreateAuthUriResponse> createAuthUri(
      GoogleCloudIdentitytoolkitV1CreateAuthUriRequest request) async {
    var email = request.identifier;
    if (email == null) {
      throw ArgumentError('Invalid request: missing identifier');
    }
    var user = await backend.getUserByEmail(email);

    return GoogleCloudIdentitytoolkitV1CreateAuthUriResponse()
      ..allProviders = [for (var p in user.providerUserInfo!) p.providerId!]
      ..signinMethods = [for (var p in user.providerUserInfo!) p.providerId!];
  }

  Future<GoogleCloudIdentitytoolkitV1SignInWithCustomTokenResponse>
      signInWithCustomToken(
          GoogleCloudIdentitytoolkitV1SignInWithCustomTokenRequest
              request) async {
    var user = await _userFromIdToken(request.token!);

    var idToken = request.returnSecureToken == true
        ? await backend.generateIdToken(uid: user.localId, providerId: 'custom')
        : null;
    var refreshToken =
        idToken == null ? null : await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return GoogleCloudIdentitytoolkitV1SignInWithCustomTokenResponse()
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV1DeleteAccountResponse> deleteAccount(
      GoogleCloudIdentitytoolkitV1DeleteAccountRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    await backend.deleteUser(user.localId);
    return GoogleCloudIdentitytoolkitV1DeleteAccountResponse();
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

  Future<GoogleCloudIdentitytoolkitV1GetOobCodeResponse> getOobConfirmationCode(
      GoogleCloudIdentitytoolkitV1GetOobCodeRequest request) async {
    var idToken = request.idToken;
    var email = request.email;
    var user = idToken != null
        ? await _userFromIdToken(idToken)
        : email != null
            ? await backend.getUserByEmail(email)
            : throw ArgumentError('Invalid request: missing idToken or email');
    return GoogleCloudIdentitytoolkitV1GetOobCodeResponse()..email = user.email;
  }

  Future<GoogleCloudIdentitytoolkitV1ResetPasswordResponse> resetPassword(
      GoogleCloudIdentitytoolkitV1ResetPasswordRequest request) async {
    try {
      var jwt = JsonWebToken.unverified(request.oobCode!);
      var user = await backend.getUserById(jwt.claims['sub']);
      await backend.updateUser(user..rawPassword = request.newPassword);
      return GoogleCloudIdentitytoolkitV1ResetPasswordResponse()
        ..requestType = jwt.claims['operation']
        ..email = user.email;
    } on ArgumentError {
      throw FirebaseAuthException.invalidOobCode();
    }
  }

  Future<GoogleCloudIdentitytoolkitV1SetAccountInfoResponse> setAccountInfo(
      GoogleCloudIdentitytoolkitV1SetAccountInfoRequest request) async {
    BackendUser user;
    try {
      user = await _userFromIdToken(request.idToken ?? request.oobCode!);
    } on ArgumentError {
      if (request.oobCode != null) {
        throw FirebaseAuthException.invalidOobCode();
      }
      rethrow;
    }
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

    return GoogleCloudIdentitytoolkitV1SetAccountInfoResponse()
      ..displayName = user.displayName
      ..photoUrl = user.photoUrl
      ..email = user.email
      ..idToken = request.returnSecureToken == true
          ? await backend.generateIdToken(
              uid: user.localId, providerId: 'password')
          : null
      ..providerUserInfo = [
        for (var u in user.providerUserInfo!)
          GoogleCloudIdentitytoolkitV1ProviderUserInfo()
            ..providerId = u.providerId
            ..photoUrl = u.photoUrl
            ..displayName = u.displayName
      ];
  }

  Future<GoogleCloudIdentitytoolkitV1SendVerificationCodeResponse>
      sendVerificationCode(
          GoogleCloudIdentitytoolkitV1SendVerificationCodeRequest
              request) async {
    var phoneNumber = request.phoneNumber;
    if (phoneNumber == null) {
      throw ArgumentError('Invalid request: missing phoneNumber');
    }
    var token = await backend.sendVerificationCode(phoneNumber);
    return GoogleCloudIdentitytoolkitV1SendVerificationCodeResponse()
      ..sessionInfo = token;
  }

  Future<GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberResponse>
      signInWithPhoneNumber(
          GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest
              request) async {
    var sessionInfo = request.sessionInfo;
    if (sessionInfo == null) {
      throw ArgumentError('Invalid request: missing sessionInfo');
    }
    var code = request.code;
    if (code == null) {
      throw ArgumentError('Invalid request: missing code');
    }
    var phoneNumber = await backend.signInWithPhoneNumber(sessionInfo, code);
    var user = await backend.getUserByPhoneNumber(phoneNumber);

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberResponse()
      ..localId = user.localId
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV1SignInWithIdpResponse> signInWithIdp(
      GoogleCloudIdentitytoolkitV1SignInWithIdpRequest request) async {
    var args = Uri.parse('?${request.postBody}').queryParameters;
    try {
      var user =
          await backend.signInWithIdp(args['providerId']!, args['id_token']!);
      var idToken = await backend.generateIdToken(
          uid: user.localId, providerId: 'password');
      var refreshToken = await backend.generateRefreshToken(idToken);
      var tokenExpiresIn = await backend.getTokenExpiresIn();
      return GoogleCloudIdentitytoolkitV1SignInWithIdpResponse()
        ..localId = user.localId
        ..idToken = idToken
        ..expiresIn = '${tokenExpiresIn.inSeconds}'
        ..refreshToken = refreshToken;
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.needConfirmation().code) {
        return GoogleCloudIdentitytoolkitV1SignInWithIdpResponse()
          ..needConfirmation = true;
      }
      rethrow;
    }
  }

  Future<GoogleCloudIdentitytoolkitV1SignInWithEmailLinkResponse>
      emailLinkSignin(
          GoogleCloudIdentitytoolkitV1SignInWithEmailLinkRequest
              request) async {
    var email = request.email;
    if (email == null) {
      throw ArgumentError('Invalid request: missing email');
    }

    var jwt = JsonWebToken.unverified(request.oobCode!);
    var user = await backend.getUserById(jwt.claims['sub']);

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    var tokenExpiresIn = await backend.getTokenExpiresIn();
    return GoogleCloudIdentitytoolkitV1SignInWithEmailLinkResponse()
      ..localId = user.localId
      ..idToken = idToken
      ..expiresIn = '${tokenExpiresIn.inSeconds}'
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV2StartMfaEnrollmentResponse>
      startMfaEnrollment(
          GoogleCloudIdentitytoolkitV2StartMfaEnrollmentRequest request) async {
    var user = await _userFromIdToken(request.idToken!);
    var token = await backend.sendVerificationCode(
        request.phoneEnrollmentInfo!.phoneNumber!,
        uid: user.localId);

    var info = GoogleCloudIdentitytoolkitV2StartMfaPhoneResponseInfo()
      ..sessionInfo = token;
    return GoogleCloudIdentitytoolkitV2StartMfaEnrollmentResponse()
      ..phoneSessionInfo = info;
  }

  Future<GoogleCloudIdentitytoolkitV2FinalizeMfaEnrollmentResponse>
      finalizeMfaEnrollment(
          GoogleCloudIdentitytoolkitV2FinalizeMfaEnrollmentRequest
              request) async {
    var sessionInfo = request.phoneVerificationInfo!.sessionInfo;
    if (sessionInfo == null) {
      throw ArgumentError('Invalid request: missing sessionInfo');
    }
    var code = request.phoneVerificationInfo!.code;
    if (code == null) {
      throw ArgumentError('Invalid request: missing code');
    }

    var userId = JsonWebSignature.fromCompactSerialization(sessionInfo)
        .unverifiedPayload
        .jsonContent['uid'];

    var user = await backend.getUserById(userId);

    var phoneNumber = await backend.signInWithPhoneNumber(sessionInfo, code);
    user.phoneNumber = phoneNumber;
    user.mfaInfo = [
      ...?user.mfaInfo,
      GoogleCloudIdentitytoolkitV1MfaEnrollment()
        ..displayName = request.displayName
        ..phoneInfo = phoneNumber
        ..unobfuscatedPhoneInfo = phoneNumber
        ..enrolledAt = DateTime.now().toIso8601String()
        ..mfaEnrollmentId = Uuid().v4()
    ];

    await backend.updateUser(user);

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    return GoogleCloudIdentitytoolkitV2FinalizeMfaEnrollmentResponse()
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV2WithdrawMfaResponse> withdrawMfa(
      GoogleCloudIdentitytoolkitV2WithdrawMfaRequest request) async {
    var user = await _userFromIdToken(request.idToken!);

    var info = user.mfaInfo!.firstWhere(
        (element) => element.mfaEnrollmentId == request.mfaEnrollmentId);

    user.mfaInfo!.remove(info);

    await backend.updateUser(user);

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    return GoogleCloudIdentitytoolkitV2WithdrawMfaResponse()
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<GoogleCloudIdentitytoolkitV2StartMfaSignInResponse> startMfaSignIn(
      GoogleCloudIdentitytoolkitV2StartMfaSignInRequest request) async {
    var uid =
        JsonWebSignature.fromCompactSerialization(request.mfaPendingCredential!)
            .unverifiedPayload
            .jsonContent['uid'];
    var user = await backend.getUserById(uid);

    var info = user.mfaInfo!
        .firstWhere((v) => v.mfaEnrollmentId == request.mfaEnrollmentId);

    var token = await backend.sendVerificationCode(info.phoneInfo!,
        uid: request.mfaEnrollmentId);

    var phoneResponseInfo =
        GoogleCloudIdentitytoolkitV2StartMfaPhoneResponseInfo()
          ..sessionInfo = token;
    return GoogleCloudIdentitytoolkitV2StartMfaSignInResponse()
      ..phoneResponseInfo = phoneResponseInfo;
  }

  Future<GoogleCloudIdentitytoolkitV2FinalizeMfaSignInResponse>
      finalizeMfaSignIn(
          GoogleCloudIdentitytoolkitV2FinalizeMfaSignInRequest request) async {
    var sessionInfo = request.phoneVerificationInfo!.sessionInfo;
    if (sessionInfo == null) {
      throw ArgumentError('Invalid request: missing sessionInfo');
    }
    var code = request.phoneVerificationInfo!.code;
    if (code == null) {
      throw ArgumentError('Invalid request: missing code');
    }
    var uid =
        JsonWebSignature.fromCompactSerialization(request.mfaPendingCredential!)
            .unverifiedPayload
            .jsonContent['uid'];
    var user = await backend.getUserById(uid);
    var phoneNumber = await backend.signInWithPhoneNumber(sessionInfo, code);

    var mfaEnrollmentId = JsonWebSignature.fromCompactSerialization(sessionInfo)
        .unverifiedPayload
        .jsonContent['uid'];

    var info =
        user.mfaInfo!.firstWhere((v) => v.mfaEnrollmentId == mfaEnrollmentId);

    if (info.phoneInfo != phoneNumber) {
      throw ArgumentError('Invalid request: mismatching phone number');
    }

    var idToken = await backend.generateIdToken(
        uid: user.localId, providerId: 'password');
    var refreshToken = await backend.generateRefreshToken(idToken);
    return GoogleCloudIdentitytoolkitV2FinalizeMfaSignInResponse()
      ..idToken = idToken
      ..refreshToken = refreshToken;
  }

  Future<dynamic> _handle(String method, dynamic body) async {
    switch (method) {
      case 'accounts:signUp':
        var request = GoogleCloudIdentitytoolkitV1SignUpRequest.fromJson(body);
        return signupNewUser(request);
      case 'accounts:lookup':
        var request =
            GoogleCloudIdentitytoolkitV1GetAccountInfoRequest.fromJson(body);
        return getAccountInfo(request);
      case 'accounts:signInWithPassword':
        var request =
            GoogleCloudIdentitytoolkitV1SignInWithPasswordRequest.fromJson(
                body);
        return signInWithPassword(request);
      case 'accounts:createAuthUri':
        var request =
            GoogleCloudIdentitytoolkitV1CreateAuthUriRequest.fromJson(body);
        return createAuthUri(request);
      case 'accounts:signInWithCustomToken':
        var request =
            GoogleCloudIdentitytoolkitV1SignInWithCustomTokenRequest.fromJson(
                body);
        return signInWithCustomToken(request);
      case 'accounts:delete':
        var request =
            GoogleCloudIdentitytoolkitV1DeleteAccountRequest.fromJson(body);
        return deleteAccount(request);
      case 'accounts:sendOobCode':
        var request =
            GoogleCloudIdentitytoolkitV1GetOobCodeRequest.fromJson(body);
        return getOobConfirmationCode(request);
      case 'accounts:resetPassword':
        var request =
            GoogleCloudIdentitytoolkitV1ResetPasswordRequest.fromJson(body);
        return resetPassword(request);
      case 'accounts:update':
        var request =
            GoogleCloudIdentitytoolkitV1SetAccountInfoRequest.fromJson(body);
        return setAccountInfo(request);
      case 'accounts:sendVerificationCode':
        var request =
            GoogleCloudIdentitytoolkitV1SendVerificationCodeRequest.fromJson(
                body);
        return sendVerificationCode(request);
      case 'accounts:signInWithPhoneNumber':
        var request =
            GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest.fromJson(
                body);
        return signInWithPhoneNumber(request);
      case 'accounts:signInWithIdp':
        var request =
            GoogleCloudIdentitytoolkitV1SignInWithIdpRequest.fromJson(body);
        return signInWithIdp(request);
      case 'accounts:signInWithEmailLink':
        var request =
            GoogleCloudIdentitytoolkitV1SignInWithEmailLinkRequest.fromJson(
                body);
        return emailLinkSignin(request);
      case 'mfaEnrollment:start':
        var request =
            GoogleCloudIdentitytoolkitV2StartMfaEnrollmentRequest.fromJson(
                body);
        return startMfaEnrollment(request);
      case 'mfaEnrollment:finalize':
        var request =
            GoogleCloudIdentitytoolkitV2FinalizeMfaEnrollmentRequest.fromJson(
                body);
        return finalizeMfaEnrollment(request);
      case 'mfaEnrollment:withdraw':
        var request =
            GoogleCloudIdentitytoolkitV2WithdrawMfaRequest.fromJson(body);
        return withdrawMfa(request);
      case 'mfaSignIn:start':
        var request =
            GoogleCloudIdentitytoolkitV2StartMfaSignInRequest.fromJson(body);
        return startMfaSignIn(request);
      case 'mfaSignIn:finalize':
        var request =
            GoogleCloudIdentitytoolkitV2FinalizeMfaSignInRequest.fromJson(body);
        return finalizeMfaSignIn(request);
      default:
        throw UnsupportedError('Unsupported method $method');
    }
  }

  Future<http.Response> handleRequest(http.Request request) async {
    var method = request.url.pathSegments.last;

    var body = json.decode(request.body);

    try {
      return http.Response(json.encode(await _handle(method, body)), 200,
          headers: {'content-type': 'application/json'}, request: request);
    } on FirebaseAuthException catch (e) {
      return http.Response(json.encode(errorToServerResponse(e)), 400,
          headers: {'content-type': 'application/json'}, request: request);
    }
  }
}

abstract class AuthBackend {
  Future<BackendUser> getUserById(String uid);

  Future<BackendUser> getUserByEmail(String email);

  Future<BackendUser> getUserByPhoneNumber(String phoneNumber);

  Future<BackendUser> getUserByProvider(String providerId, String rawId);

  Future<BackendUser> createUser(
      {required String? email, required String? password});

  Future<BackendUser> updateUser(BackendUser user);

  Future<void> deleteUser(String uid);

  Future<String> generateIdToken(
      {required String uid, required String providerId});

  Future<String> generateRefreshToken(String idToken);

  Future<String> verifyRefreshToken(String token);

  Future<String> sendVerificationCode(String phoneNumber, {String? uid});

  Future<String> signInWithPhoneNumber(String sessionInfo, String code);

  Future<BackendUser> signInWithIdp(String providerId, String idToken);

  Future<BackendUser> storeUser(BackendUser user);

  Future<String?> receiveSmsCode(String phoneNumber);

  Future<void> setTokenGenerationSettings(
      {Duration? tokenExpiresIn, JsonWebKey? tokenSigningKey});

  Future<JsonWebKey> getTokenSigningKey();

  Future<Duration> getTokenExpiresIn();

  Future<String?> createActionCode(String operation, String email);
}

abstract class BaseBackend extends AuthBackend {
  final String projectId;

  BaseBackend({required this.projectId});

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
          GoogleCloudIdentitytoolkitV1ProviderUserInfo()
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
    var tokenSigningKey = await getTokenSigningKey();
    var user = await getUserById(uid);
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = await _jwtPayloadFor(user, providerId)
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> generateRefreshToken(String idToken) async {
    var tokenSigningKey = await getTokenSigningKey();
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = idToken
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  @override
  Future<String> verifyRefreshToken(String token) async {
    var tokenSigningKey = await getTokenSigningKey();
    var store = JsonWebKeyStore()..addKey(tokenSigningKey);
    var jws = JsonWebSignature.fromCompactSerialization(token);
    var payload = await jws.getPayload(store);
    return payload.jsonContent!;
  }

  @override
  Future<String?> createActionCode(String operation, String email) async {
    var user = await getUserByEmail(email);

    var tokenSigningKey = await getTokenSigningKey();
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = {'sub': user.localId, 'operation': operation}
      ..addRecipient(tokenSigningKey);
    return builder.build().toCompactSerialization();
  }

  static final _random = Random(DateTime.now().millisecondsSinceEpoch);

  static String _generateRandomString(int length) {
    var chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return Iterable.generate(
        length, (i) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> _jwtPayloadFor(
      BackendUser user, String providerId) async {
    var now = clock.now().millisecondsSinceEpoch ~/ 1000;
    var tokenExpiration = await getTokenExpiresIn();
    return {
      'iss': 'https://securetoken.google.com/$projectId',
      'provider_id': providerId,
      'aud': projectId,
      'auth_time': now,
      'sub': user.localId,
      'iat': now,
      'exp': now + tokenExpiration.inSeconds,
      'random': Random().nextDouble(),
      'email': user.email,
      if (providerId == 'anonymous')
        'firebase': {'identities': {}, 'sign_in_provider': 'anonymous'},
      if (providerId == 'password')
        'firebase': {
          'identities': {
            'email': [user.email]
          },
          'sign_in_provider': 'password'
        }
    };
  }
}

class BackendUser extends GoogleCloudIdentitytoolkitV1UserInfo {
  BackendUser(String localId) {
    this.localId = localId;
  }

  @override
  String get localId => super.localId!;
}
