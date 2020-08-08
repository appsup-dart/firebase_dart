import 'dart:convert';

import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/authcredential.dart';
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

  /// Verifies a custom token
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> verifyCustomToken(String token) async {
    if (token == null) {
      throw AuthException.invalidCustomToken();
    }
    var response = await relyingparty
        .verifyCustomToken(IdentitytoolkitRelyingpartyVerifyCustomTokenRequest()
          ..token = token
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return _handleIdTokenResponse(response);
  }

  /// Verifies an email link OTP for sign-in
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> emailLinkSignIn(
      String email, String oobCode) async {
    _validateEmail(email);
    if (oobCode == null || oobCode.isEmpty) {
      throw AuthException.internalError();
    }
    var response = await relyingparty
        .emailLinkSignin(IdentitytoolkitRelyingpartyEmailLinkSigninRequest()
          ..email = email
          ..oobCode = oobCode
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return _handleIdTokenResponse(response);
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

    return _handleIdTokenResponse(response);
  }

  /// Creates an email/password account.
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> createAccount(String email, String password) async {
    _validateEmail(email);
    _validateStrongPassword(password);
    var response = await relyingparty
        .signupNewUser(IdentitytoolkitRelyingpartySignupNewUserRequest()
          ..email = email
          ..password = password
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return _handleIdTokenResponse(response);
  }

  /// Deletes the user's account corresponding to the idToken given.
  Future<void> deleteAccount(String idToken) async {
    if (idToken == null) {
      throw AuthException.internalError();
    }
    await relyingparty.deleteAccount(
        IdentitytoolkitRelyingpartyDeleteAccountRequest()..idToken = idToken);
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

  /// Requests verifyAssertion endpoint
  Future<VerifyAssertionResponse> verifyAssertion(
      {String sessionId,
      String requestUri,
      String postBody,
      String pendingIdToken}) async {
    return _verifyAssertion(IdentitytoolkitRelyingpartyVerifyAssertionRequest()
      ..postBody = postBody
      ..sessionId = sessionId
      ..requestUri = requestUri
      ..pendingIdToken = pendingIdToken);
  }

  /// Requests verifyAssertion endpoint for federated account linking
  Future<VerifyAssertionResponse> verifyAssertionForLinking(
      {String idToken,
      String sessionId,
      String requestUri,
      String postBody,
      String pendingToken}) async {
    if (idToken == null) {
      throw AuthException.internalError();
    }
    return _verifyAssertion(IdentitytoolkitRelyingpartyVerifyAssertionRequest()
      ..postBody = postBody
      ..pendingIdToken = pendingToken
      ..idToken = idToken
      ..sessionId = sessionId
      ..requestUri = requestUri);
  }

  /// Requests verifyAssertion endpoint for an existing federated account
  Future<VerifyAssertionResponse> verifyAssertionForExisting(
      {String sessionId,
      String requestUri,
      String postBody,
      String pendingToken}) async {
    return _verifyAssertion(IdentitytoolkitRelyingpartyVerifyAssertionRequest()
      ..returnIdpCredential = true
      ..autoCreate = false
      ..postBody = postBody
      ..pendingIdToken = pendingToken
      ..requestUri = requestUri
      ..sessionId = sessionId);
  }

  Future<VerifyAssertionResponse> _verifyAssertion(
      IdentitytoolkitRelyingpartyVerifyAssertionRequest request) async {
    // Force Auth credential to be returned on the following errors:
    // FEDERATED_USER_ID_ALREADY_LINKED
    // EMAIL_EXISTS
    _validateVerifyAssertionRequest(request);
    var response = await relyingparty.verifyAssertion(request
      ..returnIdpCredential = true
      ..returnSecureToken = true);
    if (response.errorMessage == 'USER_NOT_FOUND') {
      throw AuthException.userDeleted();
    }
    response = _processVerifyAssertionResponse(request, response);
    _validateVerifyAssertionResponse(response);
    return response;
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

  Future<openid.Credential> _handleIdTokenResponse(IdTokenResponse response) {
    _validateIdTokenResponse(response);

    return _credentialFromIdToken(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  /// Requests getOobCode endpoint for passwordless email sign-in.
  ///
  /// Returns future that resolves with user's email.
  Future<String> sendSignInLinkToEmail(
      {String email,
      String continueUrl,
      String iOSBundleId,
      String androidPackageName,
      bool androidInstallApp,
      String androidMinimumVersion,
      bool canHandleCodeInApp,
      String dynamicLinkDomain}) async {
    _validateEmail(email);
    var response = await relyingparty.getOobConfirmationCode(Relyingparty()
      ..requestType = 'EMAIL_SIGNIN'
      ..email = email
      ..continueUrl = continueUrl
      ..iOSBundleId = iOSBundleId
      ..androidPackageName = androidPackageName
      ..androidInstallApp = androidInstallApp
      ..androidMinimumVersion = androidMinimumVersion
      ..canHandleCodeInApp = canHandleCodeInApp
      ..dynamicLinkDomain = dynamicLinkDomain);

    if (response.email == null) {
      throw AuthException.internalError();
    }
    return response.email;
  }

  /// Updates the custom locale header.
  void updateCustomLocaleHeader(String languageCode) {
    identitytoolkitApi.updateCustomLocaleHeader(languageCode);
  }

  AuthException _errorFromVerifyAssertionResponse(
      VerifyAssertionResponse response) {
    if (response.needConfirmation ?? false) {
      // Account linking required, previously logged in to another account
      // with same email. User must authenticate they are owners of the
      // first account.
      // If enough info for Auth linking error, throw an instance of Auth linking
      // error. This will be used by developer after reauthenticating with email
      // provided by error to link using the credentials in Auth linking error.
      // If missing information, return regular Auth error.
      return AuthException.needConfirmation();
    } else {
      switch (response.errorMessage) {
        case 'FEDERATED_USER_ID_ALREADY_LINKED':
          // When FEDERATED_USER_ID_ALREADY_LINKED returned in error message, auth
          // credential and email will also be returned, throw relevant error in that
          // case.
          // In this case the developer needs to signInWithCredential to the returned
          // credentials.
          return AuthException.credentialAlreadyInUse();
        case 'EMAIL_EXISTS':
          // When EMAIL_EXISTS returned in error message, Auth credential and email
          // will also be returned, throw relevant error in that case.
          // In this case, the developers needs to sign in the user to the original
          // owner of the account and then link to the returned credential here.
          return AuthException.emailExists();
      }
      if (response.errorMessage != null) {
        // Construct developer facing error message from server code in errorMessage
        // field.
        return _getDeveloperErrorFromCode(response.errorMessage);
      }
    }
    // If no error found and ID token is missing, throw an internal error.
    if (response.idToken == null) {
      return AuthException.internalError();
    }
    return null;
  }

  /// Validates a response from verifyAssertion.
  void _validateVerifyAssertionResponse(VerifyAssertionResponse response) {
    var error = _errorInfoFromResponse(
        _errorFromVerifyAssertionResponse(response), response);
    if (error != null) {
      throw error;
    }
  }

  AuthException _errorInfoFromResponse(
      AuthException error, VerifyAssertionResponse response) {
    return error?.replace(
//TODO      message: response.message,
      email: response.email,
//TODO      phoneNumber: response.phoneNumber,
      credential: _getCredentialFromResponse(response),
    );
  }

  /// Constructs an Auth credential from a backend response.
  AuthCredential _getCredentialFromResponse(dynamic response) {
    // Handle phone Auth credential responses, as they have a different format
    // from other backend responses (i.e. no providerId).
    if (response is IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse) {
      return PhoneAuthCredential.temporaryProof(
          temporaryProof: response.temporaryProof,
          phoneNumber: response.phoneNumber);
    }

    if (response is VerifyAssertionResponse) {
      // Get all OAuth response parameters from response.
      var providerId = response.providerId;

      // Email and password is not supported as there is no situation where the
      // server would return the password to the client.
      if (providerId == null || providerId == EmailAuthProvider.providerId) {
        return null;
      }

      try {
        switch (providerId) {
          case GoogleAuthProvider.providerId:
            return GoogleAuthProvider.getCredential(
                idToken: response.oauthIdToken,
                accessToken: response.oauthAccessToken);

          case FacebookAuthProvider.providerId:
            return FacebookAuthProvider.getCredential(
                accessToken: response.oauthAccessToken);

          case GithubAuthProvider.providerId:
            return GithubAuthProvider.getCredential(
                token: response.oauthAccessToken);

          case TwitterAuthProvider.providerId:
            return TwitterAuthProvider.getCredential(
                authToken: response.oauthAccessToken,
                authTokenSecret: response.oauthTokenSecret);

          default: // TODO: is this still VerifyAssertionResponse?
            if (response.oauthAccessToken == null &&
                response.oauthTokenSecret == null &&
                response.oauthIdToken == null &&
                response.pendingToken == null) {
              return null;
            }
            if (response.pendingToken != null) {
              if (SAMLAuthProvider.isSaml(providerId)) {
                return SAMLAuthCredential(providerId, response.pendingToken);
              } else {
                // OIDC and non-default providers excluding Twitter.
                return OAuthCredential({
                  'providerId': providerId,
                  'pendingToken': response.pendingToken,
                  'idToken': response.oauthIdToken,
                  'accessToken': response.oauthAccessToken
                });
              }
            }
            return OAuthProvider(providerId: providerId).getCredential(
                idToken: response.oauthIdToken,
                accessToken: response.oauthAccessToken,
                rawNonce: response.nonce);
        }
      } catch (e) {
        return null;
      }
    }

    // Note this is not actually returned by the backend. It is introduced in
    // rpcHandler.
    var rawNonce = response && response['nonce'];
    // Google Id Token returned when no additional scopes provided.
    var idToken = response && response['oauthIdToken'];
    // Pending token for SAML and OAuth/OIDC providers.
    var pendingToken = response && response['pendingToken'];
  }

  /// Returns the developer facing error corresponding to the server code provided
  AuthException _getDeveloperErrorFromCode(String serverErrorCode) {
    // Encapsulate the server error code in a typical server error response with
    // the code populated within. This will convert the response to a developer
    // facing one.
    return authErrorFromResponse({
      'error': {
        'errors': [
          {'message': serverErrorCode}
        ],
        'code': 400,
        'message': serverErrorCode
      }
    });
  }

  /// Processes the verifyAssertion response and injects the same raw nonce
  /// if available in request.
  VerifyAssertionResponse _processVerifyAssertionResponse(
      IdentitytoolkitRelyingpartyVerifyAssertionRequest request,
      VerifyAssertionResponse response) {
    // This makes it possible for OIDC providers to:
    // 1. Initialize an OIDC Auth credential on successful response.
    // 2. Initialize an OIDC Auth credential within the recovery error.

    // When request has sessionId and response has OIDC ID token and no pending
    // token, a credential with raw nonce and OIDC ID token needs to be returned.
    if (response.oauthIdToken != null &&
        response.providerId != null &&
        response.providerId.startsWith('oidc.') &&
        // Use pendingToken instead of idToken and rawNonce when available.
        response.pendingToken == null) {
      if (request.sessionId != null) {
        // For full OAuth flow, the nonce is in the session ID.
        response.nonce = request.sessionId;
      } else if (request.postBody != null) {
        // For credential flow, the nonce is in the postBody nonce field.
        var queryData = Uri(query: request.postBody).queryParameters;
        if (queryData.containsKey('nonce')) {
          response.nonce = queryData['nonce'];
        }
      }
    }

    return response;
  }

  /// Validates a verifyAssertion request.
  void _validateVerifyAssertionRequest(
      IdentitytoolkitRelyingpartyVerifyAssertionRequest request) {
    // Either (requestUri and sessionId), (requestUri and postBody) or
    // (requestUri and pendingToken) are required.
    if (request.requestUri == null ||
        (request.sessionId == null &&
            request.postBody == null &&
            request.pendingIdToken == null)) {
      throw AuthException.internalError();
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

  /// Validates a password
  void _validateStrongPassword(String password) {
    if (password == null || password.isEmpty) {
      throw AuthException.weakPassword();
    }
  }
}
