import 'dart:convert';

import 'package:firebase_dart/src/auth/utils.dart';

import 'error.dart';
import 'identitytoolkit.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../error.dart';
import 'package:openid_client/openid_client.dart' as openid;

class RpcHandler {
  final IdentitytoolkitApi identitytoolkitApi;

  final http.Client httpClient;

  final String apiKey;

  /// The tenant ID.
  String tenantId;

  RelyingpartyResourceApi get relyingparty => identitytoolkitApi.relyingparty;

  RpcHandler(this.apiKey, {this.httpClient})
      : identitytoolkitApi =
            IdentitytoolkitApi(clientViaApiKey(apiKey, baseClient: httpClient));

  /// Gets the list of authorized domains for the specified project.
  Future<List<String>> getAuthorizedDomains() async {
    var response = await relyingparty.getProjectConfig();
    return response.authorizedDomains;
  }

  /// reCAPTCHA.
  Future<GetRecaptchaParamResponse> getRecaptchaParam() async {
    var response = await relyingparty.getRecaptchaParam();

    if (response.recaptchaSiteKey == null) {
      throw AuthException.internalError();
    }

    return response;
  }

  /// Gets the list of authorized domains for the specified project.
  Future<String> getDynamicLinkDomain() async {
    var response = await relyingparty.getProjectConfig(
        $fields: _toQueryString({'returnDynamicLink': 'true'}));

    if (response.dynamicLinksDomain == null) {
      throw AuthException.internalError();
    }
    return response.dynamicLinksDomain;
  }

  /// Checks if the provided iOS bundle ID belongs to the project.
  Future<void> isIosBundleIdValid(String iosBundleId) async {
    // This will either resolve if the identifier is valid or throw
    // INVALID_APP_ID if not.
    await relyingparty.getProjectConfig(
        $fields: _toQueryString({'iosBundleId': iosBundleId}));
  }

  /// Checks if the provided Android package name belongs to the project.
  Future<void> isAndroidPackageNameValid(String androidPackageName,
      [String sha1Cert]) async {
    // When no sha1Cert is passed, this will either resolve if the identifier is
    // valid or throw INVALID_APP_ID if not.
    // When sha1Cert is also passed, this will either resolve or fail with an
    // INVALID_CERT_HASH error.
    await relyingparty.getProjectConfig(
      $fields: _toQueryString({
        'androidPackageName': androidPackageName,
        // This is relevant for the native Android SDK flow.
        // This will redirect to an FDL domain owned by GMScore instead of
        // the developer's FDL domain as is done for Cordova apps.
        if (sha1Cert != null)
          'sha1Cert': sha1Cert
      }),
    );
  }

  /// Checks if the provided OAuth client ID belongs to the project.
  Future<void> isOAuthClientIdValid(String clientId) async {
    // This will either resolve if the client ID is valid or throw
    // INVALID_OAUTH_CLIENT_ID if not.
    await relyingparty.getProjectConfig(
        $fields: _toQueryString({'clientId': clientId}));
  }

  /// Returns the list of sign in methods for the given identifier.
  Future<List<String>> fetchSignInMethodsForIdentifier(
      String identifier) async {
    var response = await _createAuthUri(identifier);
    return response.signinMethods ?? [];
  }

  /// Gets the list of IDPs that can be used to log in for the given identifier.
  Future<List<String>> fetchProvidersForIdentifier(String identifier) async {
    var response = await _createAuthUri(identifier);
    return response.allProviders;
  }

  /// Requests getAccountInfo endpoint using an ID token.
  Future<GetAccountInfoResponse> getAccountInfoByIdToken(String idToken) async {
    var response = await _handle(() => identitytoolkitApi.relyingparty
        .getAccountInfo(IdentitytoolkitRelyingpartyGetAccountInfoRequest()
          ..idToken = idToken));
    return response;
  }

  /// Verifies a password
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> verifyPassword(
      String email, String password) async {
    _validateEmail(email);
    _validatePassword(password);

    var response = await relyingparty
        .verifyPassword(IdentitytoolkitRelyingpartyVerifyPasswordRequest()
          ..email = email
          ..password = password
          ..returnSecureToken = true
          ..tenantId = tenantId);

    _validateIdTokenResponse(response);

    return _credentialFromIdToken(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  /// Signs in a user as anonymous.
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> signInAnonymously() async {
    var response = await relyingparty
        .signupNewUser(IdentitytoolkitRelyingpartySignupNewUserRequest()
          ..returnSecureToken = true
          ..tenantId = tenantId);

    if (response.idToken == null) {
      throw AuthException.internalError();
    }

    return _credentialFromIdToken(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  Future<openid.Credential> _credentialFromIdToken(
      {String idToken, String refreshToken, String expiresIn}) async {
    var client =
        await openid.Client.forIdToken(idToken, httpClient: httpClient);
    return client.createCredential(
      accessToken: idToken,
      idToken: idToken,
      expiresIn: Duration(seconds: int.parse(expiresIn ?? '3600')),
      refreshToken: refreshToken,
    );
  }

  static String _toQueryString(Map<String, String> queryParameters) =>
      Uri(queryParameters: queryParameters).query;

  Future<CreateAuthUriResponse> _createAuthUri(String identifier) async {
    // createAuthUri returns an error if continue URI is not http or https.
    // For environments like Cordova, Chrome extensions, native frameworks, file
    // systems, etc, use http://localhost as continue URL.
    var continueUri = isHttpOrHttps() ? getCurrentUrl() : 'http://localhost';
    var response = await identitytoolkitApi.relyingparty
        .createAuthUri(IdentitytoolkitRelyingpartyCreateAuthUriRequest()
          ..identifier = identifier
          ..continueUri = continueUri
          ..tenantId = tenantId);
    return response;
  }

  Future<T> _handle<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DetailedApiRequestError catch (e) {
      var errorCode = e.message;
      var errorMessage;
      // Get detailed message if available.
      var match = RegExp(r'^([^\s]+)\s*:\s*(.*)$').firstMatch(errorCode);
      if (match != null) {
        errorCode = match.group(1);
        errorMessage = match.group(2);
      }

      var error = authErrorFromServerErrorCode(errorCode);
      if (error == null) {
        error = AuthException.internalError();
        errorMessage ??= json.encode(e.jsonResponse);
      }
      throw error.replace(message: errorMessage);
    }
  }

  /// Validates an email
  void _validateEmail(String email) {
    if (!isValidEmailAddress(email)) {
      throw AuthException.invalidEmail();
    }
  }

  /// Validates a password
  void _validatePassword(String password) {
    if (password == null || password.isEmpty) {
      throw AuthException.invalidPassword();
    }
  }

  /// Validates a response that should contain an ID token.
  ///
  /// If no ID token is available, it checks if a multi-factor pending credential
  /// is available instead. In that case, it throws the MFA_REQUIRED error code.
  void _validateIdTokenResponse(IdTokenResponse response) {
    if (response.idToken == null) {
      // User could be a second factor user.
      // When second factor is required, a pending credential is returned.
      if (response.mfaPendingCredential != null) {
        throw AuthException.mfaRequired();
      }
      throw AuthException.internalError();
    }
  }
}
