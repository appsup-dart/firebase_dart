import 'dart:convert';

import 'package:firebase_dart/src/auth/providers/saml.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:googleapis_auth/auth_browser.dart'
    if (dart.library.io) 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:openid_client/openid_client.dart' as openid;

import '../action_code.dart';
import '../auth_credential.dart';
import '../auth_provider.dart';
import '../error.dart';
import 'error.dart';
import 'identitytoolkit.dart';

class RpcHandler {
  final IdentitytoolkitApi identitytoolkitApi;

  final http.Client httpClient;

  final String apiKey;

  /// The tenant ID.
  String? tenantId;

  RelyingpartyResource get relyingparty => identitytoolkitApi.relyingparty;

  RpcHandler(this.apiKey, {required http.Client? httpClient})
      : httpClient = ProxyClient({
          RegExp('https://securetoken.google.com/.*/.well-known/openid-configuration'):
              http.MockClient((request) async {
            var projectId = request.url.pathSegments.first;
            return http.Response(
                json.encode({
                  'issuer': 'https://securetoken.google.com/$projectId',
                  'jwks_uri':
                      'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
                  'token_endpoint':
                      'https://securetoken.googleapis.com/v1/token?key=$apiKey',
                  'response_types_supported': ['id_token'],
                  'subject_types_supported': ['public'],
                  'id_token_signing_alg_values_supported': ['RS256']
                }),
                200,
                headers: {'Content-Type': 'application/json'});
          }),
          RegExp('.*'): httpClient ?? http.Client(),
        }),
        identitytoolkitApi =
            IdentitytoolkitApi(clientViaApiKey(apiKey, baseClient: httpClient));

  /// Gets the list of authorized domains for the specified project.
  Future<List<String>?> getAuthorizedDomains() async {
    var response = await relyingparty.getProjectConfig();
    return response.authorizedDomains;
  }

  /// reCAPTCHA.
  Future<GetRecaptchaParamResponse> getRecaptchaParam() async {
    var response = await relyingparty.getRecaptchaParam();

    if (response.recaptchaSiteKey == null) {
      throw FirebaseAuthException.internalError();
    }

    return response;
  }

  /// Gets the list of authorized domains for the specified project.
  Future<String?> getDynamicLinkDomain() async {
    var response = await relyingparty.getProjectConfig(
        $fields: _toQueryString({'returnDynamicLink': 'true'}));

    if (response.dynamicLinksDomain == null) {
      throw FirebaseAuthException.internalError();
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
      [String? sha1Cert]) async {
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
        if (sha1Cert != null) 'sha1Cert': sha1Cert
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
  Future<List<String>?> fetchProvidersForIdentifier(String identifier) async {
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
    var response = await relyingparty
        .verifyCustomToken(IdentitytoolkitRelyingpartyVerifyCustomTokenRequest()
          ..token = token
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(response);
  }

  /// Verifies an email link OTP for sign-in
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> emailLinkSignIn(
      String email, String oobCode) async {
    _validateEmail(email);
    if (oobCode.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    var response = await relyingparty
        .emailLinkSignin(IdentitytoolkitRelyingpartyEmailLinkSigninRequest()
          ..email = email
          ..oobCode = oobCode
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(response);
  }

  /// Verifies a password
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> verifyPassword(
      String email, String? password) async {
    _validateEmail(email);
    _validatePassword(password);

    var response = await relyingparty
        .verifyPassword(IdentitytoolkitRelyingpartyVerifyPasswordRequest()
          ..email = email
          ..password = password
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(response);
  }

  /// Creates an email/password account.
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> createAccount(
      String email, String? password) async {
    _validateEmail(email);
    _validateStrongPassword(password);
    var response = await relyingparty
        .signupNewUser(IdentitytoolkitRelyingpartySignupNewUserRequest()
          ..email = email
          ..password = password
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(response);
  }

  /// Deletes the user's account corresponding to the idToken given.
  Future<void> deleteAccount(String? idToken) async {
    if (idToken == null) {
      throw FirebaseAuthException.internalError();
    }
    try {
      await relyingparty.deleteAccount(
          IdentitytoolkitRelyingpartyDeleteAccountRequest()..idToken = idToken);
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.userDeleted().code) {
        throw FirebaseAuthException.tokenExpired();
      }
      rethrow;
    }
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
      throw FirebaseAuthException.internalError();
    }

    return _credentialFromIdToken(
        idToken: response.idToken!,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  Future<openid.Credential> _credentialFromIdToken(
      {required String idToken,
      String? refreshToken,
      String? expiresIn}) async {
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
  Future<openid.Credential> verifyAssertion(
      {String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingIdToken}) async {
    var response = await _verifyAssertion(
        IdentitytoolkitRelyingpartyVerifyAssertionRequest()
          ..postBody = postBody
          ..sessionId = sessionId
          ..requestUri = requestUri
          ..pendingIdToken = pendingIdToken);

    return _credentialFromIdToken(
        idToken: response.idToken!,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  /// Requests verifyAssertion endpoint for federated account linking
  Future<VerifyAssertionResponse> verifyAssertionForLinking(
      {String? idToken,
      String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingToken}) async {
    if (idToken == null) {
      throw FirebaseAuthException.internalError();
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
      {String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingToken}) async {
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
      throw FirebaseAuthException.userDeleted();
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
    var continueUri = Platform.current is WebPlatform
        ? (Platform.current as WebPlatform).currentUrl
        : 'http://localhost';
    if (!['http', 'https'].contains(Uri.parse(continueUri).scheme)) {
      continueUri = 'http://localhost';
    }
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
      var errorCode = e.message!;
      String? errorMessage;
      // Get detailed message if available.
      var match = RegExp(r'^([^\s]+)\s*:\s*(.*)$').firstMatch(errorCode);
      if (match != null) {
        errorCode = match.group(1)!;
        errorMessage = match.group(2);
      }

      var error = authErrorFromServerErrorCode(errorCode);
      if (error == null) {
        error = FirebaseAuthException.internalError();
        errorMessage ??= json.encode(e.jsonResponse);
      }
      throw error.replace(message: errorMessage);
    }
  }

  Future<openid.Credential> handleIdTokenResponse(IdTokenResponse response) {
    _validateIdTokenResponse(response);

    return _credentialFromIdToken(
        idToken: response.idToken!,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  /// Requests getOobCode endpoint for passwordless email sign-in.
  ///
  /// Returns future that resolves with user's email.
  Future<String?> sendSignInLinkToEmail(
      {required String email, ActionCodeSettings? actionCodeSettings}) async {
    _validateEmail(email);
    var response = await relyingparty
        .getOobConfirmationCode(_createRelyingparty(actionCodeSettings)
          ..requestType = 'EMAIL_SIGNIN'
          ..email = email);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  Relyingparty _createRelyingparty(ActionCodeSettings? actionCodeSettings) {
    if (actionCodeSettings == null) return Relyingparty();
    return Relyingparty()
      ..continueUrl = actionCodeSettings.url
      ..iOSBundleId = actionCodeSettings.iOSBundleId
      ..androidPackageName = actionCodeSettings.androidPackageName
      ..androidInstallApp = actionCodeSettings.androidInstallApp
      ..androidMinimumVersion = actionCodeSettings.androidMinimumVersion
      ..canHandleCodeInApp = actionCodeSettings.handleCodeInApp
      ..dynamicLinkDomain = actionCodeSettings.dynamicLinkDomain;
  }

  /// Requests getOobCode endpoint for password reset.
  ///
  /// Returns future that resolves with user's email.
  Future<String?> sendPasswordResetEmail(
      {required String email, ActionCodeSettings? actionCodeSettings}) async {
    _validateEmail(email);
    var response = await relyingparty
        .getOobConfirmationCode(_createRelyingparty(actionCodeSettings)
          ..requestType = 'PASSWORD_RESET'
          ..email = email);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Requests getOobCode endpoint for email verification.
  ///
  /// Returns future that resolves with user's email.
  Future<String?> sendEmailVerification(
      {required String idToken, ActionCodeSettings? actionCodeSettings}) async {
    var response = await relyingparty
        .getOobConfirmationCode(_createRelyingparty(actionCodeSettings)
          ..requestType = 'VERIFY_EMAIL'
          ..idToken = idToken);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Requests resetPassword endpoint for password reset.
  ///
  /// Returns future that resolves with user's email.
  Future<String?> confirmPasswordReset(String code, String newPassword) async {
    _validateApplyActionCode(code);
    var response = await relyingparty
        .resetPassword(IdentitytoolkitRelyingpartyResetPasswordRequest()
          ..oobCode = code
          ..newPassword = newPassword);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Checks the validity of an email action code and returns the response
  /// received.
  Future<ResetPasswordResponse> checkActionCode(String code) async {
    _validateApplyActionCode(code);
    var response = await relyingparty.resetPassword(
        IdentitytoolkitRelyingpartyResetPasswordRequest()..oobCode = code);

    _validateCheckActionCodeResponse(response);
    return response;
  }

  /// Applies an out-of-band email action code, such as an email verification
  /// code.
  Future<String?> applyActionCode(String code) async {
    _validateApplyActionCode(code);
    var response = await relyingparty.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest()..oobCode = code);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Updates the providers for the account associated with the idToken.
  Future<SetAccountInfoResponse> deleteLinkedAccounts(
      String idToken, List<String>? providersToDelete) async {
    if (providersToDelete == null) {
      throw FirebaseAuthException.internalError();
    }
    try {
      return await relyingparty
          .setAccountInfo(IdentitytoolkitRelyingpartySetAccountInfoRequest()
            ..idToken = idToken
            ..deleteProvider = providersToDelete);
    } on FirebaseAuthException catch (e) {
      if (e.code == FirebaseAuthException.userDeleted().code) {
        throw FirebaseAuthException.tokenExpired();
      }
      rethrow;
    }
  }

  /// Updates the profile of the user. When resolved, promise returns a response
  /// similar to that of getAccountInfo.
  Future<SetAccountInfoResponse> updateProfile(
      String idToken, Map<String, dynamic> profileData) async {
    var request = IdentitytoolkitRelyingpartySetAccountInfoRequest()
      ..idToken = idToken
      ..returnSecureToken = true;
    var fieldsToDelete = <String?>[];

    // Copy over the relevant fields from profileData, or explicitly flag a field
    // for deletion if null is passed as the value. Note that this currently only
    // checks profileData to the first level.
    for (var fieldName in ['displayName', 'photoUrl']) {
      var fieldValue = profileData[fieldName];
      if (profileData.containsKey(fieldName) && fieldValue == null) {
        // If null is explicitly provided, delete the field.
        fieldsToDelete.add({
          'displayName': 'DISPLAY_NAME',
          'photoUrl': 'PHOTO_URL'
        }[fieldName]);
      } else if (profileData.containsKey(fieldName)) {
        // If the field is explicitly set, send it to the backend.
        switch (fieldName) {
          case 'displayName':
            request.displayName = fieldValue;
            break;
          case 'photoUrl':
            request.photoUrl = fieldValue;
            break;
        }
      }
    }

    if (fieldsToDelete.isNotEmpty) {
      request.deleteAttribute = fieldsToDelete.whereType<String>().toList();
    }
    var response = await relyingparty.setAccountInfo(request);

    return response;
  }

  /// Requests setAccountInfo endpoint for updateEmail operation.
  Future<SetAccountInfoResponse> updateEmail(
      String idToken, String newEmail) async {
    _validateEmail(newEmail);
    var response = await relyingparty
        .setAccountInfo(IdentitytoolkitRelyingpartySetAccountInfoRequest()
          ..idToken = idToken
          ..email = newEmail
          ..returnSecureToken = true);
    return response;
  }

  /// Requests setAccountInfo endpoint for updatePassword operation.
  Future<SetAccountInfoResponse> updatePassword(
      String idToken, String newPassword) async {
    _validateStrongPassword(newPassword);
    var response = await relyingparty
        .setAccountInfo(IdentitytoolkitRelyingpartySetAccountInfoRequest()
          ..idToken = idToken
          ..password = newPassword
          ..returnSecureToken = true);
    _validateIdTokenResponse(response);
    return response;
  }

  /// Requests setAccountInfo endpoint to set the email and password. This can be
  /// used to link an existing account to a email and password account.
  Future<SetAccountInfoResponse> updateEmailAndPassword(
      String idToken, String newEmail, String newPassword) async {
    _validateEmail(newEmail);
    _validateStrongPassword(newPassword);
    var response = await relyingparty
        .setAccountInfo(IdentitytoolkitRelyingpartySetAccountInfoRequest()
          ..idToken = idToken
          ..email = newEmail
          ..password = newPassword
          ..returnSecureToken = true);
    _validateIdTokenResponse(response);
    return response;
  }

  /// Verifies an email link OTP for linking and returns a Promise that resolves
  /// with the ID token.
  Future<EmailLinkSigninResponse> emailLinkSignInForLinking(
      String idToken, String email, String oobCode) async {
    if (idToken.isEmpty || oobCode.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    _validateEmail(email);
    var response = await relyingparty
        .emailLinkSignin(IdentitytoolkitRelyingpartyEmailLinkSigninRequest()
          ..idToken = idToken
          ..email = email
          ..oobCode = oobCode
          ..returnSecureToken = true);
    _validateIdTokenResponse(response);
    return response;
  }

  /// Requests createAuthUri endpoint to retrieve the authUri and session ID for
  /// the start of an OAuth handshake.
  Future<CreateAuthUriResponse> getAuthUri(
      String? providerId, String? continueUri,
      [Map<String, dynamic>? customParameters,
      List<String>? additionalScopes,
      String? email,
      String? sessionId]) async {
    if (continueUri == null) {
      throw FirebaseAuthException.missingContinueUri();
    }
    // Either a SAML or non SAML providerId must be provided.
    if (providerId == null) {
      throw FirebaseAuthException.internalError()
          .replace(message: 'A provider ID must be provided in the request.');
    }

    var scopes = _getAdditionalScopes(providerId, additionalScopes);
    // SAML provider request is constructed differently than OAuth requests.
    var request = IdentitytoolkitRelyingpartyCreateAuthUriRequest()
      ..providerId = providerId
      ..continueUri = continueUri
      ..customParameter = customParameters as Map<String, String>? ?? {};
    if (email != null) request.identifier = email;
    if (scopes != null) request.oauthScope = scopes;
    if (sessionId != null) request.sessionId = sessionId;

    // Custom parameters and OAuth scopes should be ignored.
    if (isSaml(providerId)) {
      request
        ..customParameter = null
        ..oauthScope = null;
    }
    // When sessionId is provided, mobile flow (Cordova) is being used, force
    // code flow and not implicit flow. All other providers use code flow by
    // default.
    if (sessionId != null && providerId == GoogleAuthProvider.id) {
      request.authFlowType = 'CODE_FLOW';
    }
    var response = await relyingparty.createAuthUri(request);
    _validateGetAuthResponse(response);
    return response;
  }

  /// Requests sendVerificationCode endpoint for verifying the user's ownership of
  /// a phone number. It resolves with a sessionInfo (verificationId).
  Future<String> sendVerificationCode(
      {String? phoneNumber, String? recaptchaToken}) async {
    // In the future, we could support other types of assertions so for now,
    // we are keeping the request an object.

    if (phoneNumber == null || recaptchaToken == null) {
      throw FirebaseAuthException.internalError();
    }
    var request = IdentitytoolkitRelyingpartySendVerificationCodeRequest()
      ..phoneNumber = phoneNumber
      ..recaptchaToken = recaptchaToken;
    var response = await relyingparty.sendVerificationCode(request);
    if (response.sessionInfo == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.sessionInfo!;
  }

  /// Requests verifyPhoneNumber endpoint for sign in/sign up phone number
  /// authentication flow and resolves with the STS token response.
  Future<openid.Credential> verifyPhoneNumber(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber}) async {
    var request = IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber;
    _validateVerifyPhoneNumberRequest(request);

    var response = await relyingparty.verifyPhoneNumber(request);
    return handleIdTokenResponse(response);
  }

  /// Requests verifyPhoneNumber endpoint for link/update phone number
  /// authentication flow and resolves with the STS token response.
  Future<openid.Credential> verifyPhoneNumberForLinking(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber,
      String? idToken}) async {
    // idToken should be required here.
    if (idToken == null) {
      throw FirebaseAuthException.internalError();
    }
    var request = IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber
      ..idToken = idToken;
    _validateVerifyPhoneNumberRequest(request);

    var response = await relyingparty.verifyPhoneNumber(request);

    if (response.temporaryProof != null) {
      throw _errorInfoFromResponse(
          FirebaseAuthException.credentialAlreadyInUse(), response)!;
    }

    return handleIdTokenResponse(response);
  }

  /// Requests verifyPhoneNumber endpoint for reauthenticating with a phone number
  /// and resolves with the STS token response.
  Future<openid.Credential> verifyPhoneNumberForExisting(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber}) async {
    var request = IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber
      ..operation = 'REAUTH';
    _validateVerifyPhoneNumberRequest(request);

    var response = await relyingparty.verifyPhoneNumber(request);

    if (response.temporaryProof != null) {
      throw _errorInfoFromResponse(
          FirebaseAuthException.credentialAlreadyInUse(), response)!;
    }

    return handleIdTokenResponse(response);
  }

  /// Updates the custom locale header.
  void updateCustomLocaleHeader(String? languageCode) {
    identitytoolkitApi.updateCustomLocaleHeader(languageCode);
  }

  /// Validates a request that sends the verification ID and code for a sign in/up
  /// phone Auth flow.
  void _validateVerifyPhoneNumberRequest(
      IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest request) {
    // There are 2 cases here:
    // case 1: sessionInfo and code
    // case 2: phoneNumber and temporaryProof
    if (request.phoneNumber != null || request.temporaryProof != null) {
      // Case 2. Both phoneNumber and temporaryProof should be set.
      if (request.phoneNumber == null || request.temporaryProof == null) {
        throw FirebaseAuthException.internalError();
      }
    } else {
      // Otherwise it's case 1, so we expect sessionInfo and code.
      if (request.sessionInfo == null) {
        throw FirebaseAuthException.missingSessionInfo();
      }
      if (request.code == null) {
        throw FirebaseAuthException.missingCode();
      }
    }
  }

  /// Returns the IDP and its comma separated scope strings serialized.
  String? _getAdditionalScopes(String providerId,
      [List<String>? additionalScopes]) {
    if (additionalScopes != null && additionalScopes.isNotEmpty) {
      // Return stringified scopes.
      return json.encode({providerId: additionalScopes.join(',')});
    }
    return null;
  }

  /// Validates a response from getAuthUri.
  void _validateGetAuthResponse(CreateAuthUriResponse response) {
    if (response.authUri == null) {
      throw FirebaseAuthException.internalError().replace(
          message:
              'Unable to determine the authorization endpoint for the specified '
              'provider. This may be an issue in the provider configuration.');
    } else if (response.sessionId == null) {
      throw FirebaseAuthException.internalError();
    }
  }

  FirebaseAuthException? _errorFromVerifyAssertionResponse(
      VerifyAssertionResponse response) {
    if (response.needConfirmation ?? false) {
      // Account linking required, previously logged in to another account
      // with same email. User must authenticate they are owners of the
      // first account.
      // If enough info for Auth linking error, throw an instance of Auth linking
      // error. This will be used by developer after reauthenticating with email
      // provided by error to link using the credentials in Auth linking error.
      // If missing information, return regular Auth error.
      return FirebaseAuthException.needConfirmation();
    } else {
      switch (response.errorMessage) {
        case 'FEDERATED_USER_ID_ALREADY_LINKED':
          // When FEDERATED_USER_ID_ALREADY_LINKED returned in error message, auth
          // credential and email will also be returned, throw relevant error in that
          // case.
          // In this case the developer needs to signInWithCredential to the returned
          // credentials.
          return FirebaseAuthException.credentialAlreadyInUse();
        case 'EMAIL_EXISTS':
          // When EMAIL_EXISTS returned in error message, Auth credential and email
          // will also be returned, throw relevant error in that case.
          // In this case, the developers needs to sign in the user to the original
          // owner of the account and then link to the returned credential here.
          return FirebaseAuthException.emailExists();
      }
      if (response.errorMessage != null) {
        // Construct developer facing error message from server code in errorMessage
        // field.
        return _getDeveloperErrorFromCode(response.errorMessage);
      }
    }
    // If no error found and ID token is missing, throw an internal error.
    if (response.idToken == null) {
      return FirebaseAuthException.internalError();
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

  FirebaseAuthException? _errorInfoFromResponse(
      FirebaseAuthException? error, IdTokenResponse response) {
    String? message, email, phoneNumber;
    if (response is VerifyAssertionResponse) {
      email = response.email;
    } else if (response
        is IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse) {
      phoneNumber = response.phoneNumber;
    } else {
      // TODO check callers
      throw UnimplementedError();
    }
    return error?.replace(
      message: message,
      email: email,
      phoneNumber: phoneNumber,
      credential: _getCredentialFromResponse(response),
    );
  }

  /// Constructs an Auth credential from a backend response.
  AuthCredential? _getCredentialFromResponse(dynamic response) {
    // Handle phone Auth credential responses, as they have a different format
    // from other backend responses (i.e. no providerId).
    if (response is IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse) {
      return PhoneAuthProvider.credentialFromTemporaryProof(
          temporaryProof: response.temporaryProof!,
          phoneNumber: response.phoneNumber!);
    }

    if (response is VerifyAssertionResponse) {
      // Get all OAuth response parameters from response.
      var providerId = response.providerId;

      // Email and password is not supported as there is no situation where the
      // server would return the password to the client.
      if (providerId == null || providerId == EmailAuthProvider.id) {
        return null;
      }

      try {
        switch (providerId) {
          case GoogleAuthProvider.id:
            return GoogleAuthProvider.credential(
                idToken: response.oauthIdToken,
                accessToken: response.oauthAccessToken);

          case FacebookAuthProvider.id:
            return FacebookAuthProvider.credential(response.oauthAccessToken!);

          case GithubAuthProvider.id:
            return GithubAuthProvider.credential(response.oauthAccessToken!);

          case TwitterAuthProvider.id:
            return TwitterAuthProvider.credential(
                accessToken: response.oauthAccessToken!,
                secret: response.oauthTokenSecret!);

          default: // TODO: is this still VerifyAssertionResponse?
            if (response.oauthAccessToken == null &&
                response.oauthTokenSecret == null &&
                response.oauthIdToken == null &&
                response.pendingToken == null) {
              return null;
            }
            if (response.pendingToken != null) {
              if (isSaml(providerId)) {
                return SAMLAuthCredential(providerId, response.pendingToken!);
              } else {
                // OIDC and non-default providers excluding Twitter.
                return OAuthCredential(
                    providerId: providerId,
                    signInMethod: 'oauth',
                    secret: response.pendingToken,
                    idToken: response.oauthIdToken,
                    accessToken: response.oauthAccessToken);
              }
            }
            return OAuthProvider.credential(
                providerId: providerId,
                idToken: response.oauthIdToken,
                accessToken: response.oauthAccessToken,
                rawNonce: response.nonce);
        }
      } catch (e) {
        return null;
      }
    }

    throw UnsupportedError('Cannot handle response $response');
  }

  /// Returns the developer facing error corresponding to the server code provided
  FirebaseAuthException _getDeveloperErrorFromCode(String? serverErrorCode) {
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
        response.providerId!.startsWith('oidc.') &&
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
      throw FirebaseAuthException.internalError();
    }
  }

  /// Validates that a checkActionCode response contains the email and requestType
  /// fields.
  void _validateCheckActionCodeResponse(ResetPasswordResponse response) {
    // If the code is invalid, usually a clear error would be returned.
    // In this case, something unexpected happened.
    // Email could be empty only if the request type is EMAIL_SIGNIN.
    var operation = response.requestType;
    if (operation == null ||
        (response.email == null && operation != 'EMAIL_SIGNIN')) {
      throw FirebaseAuthException.internalError();
    }
  }

  /// Validates an action code.
  void _validateApplyActionCode(String oobCode) {
    if (oobCode.isEmpty) {
      throw FirebaseAuthException.invalidOobCode();
    }
  }

  /// Validates an email
  void _validateEmail(String email) {
    if (!isValidEmailAddress(email)) {
      throw FirebaseAuthException.invalidEmail();
    }
  }

  /// Validates a password
  void _validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      throw FirebaseAuthException.invalidPassword();
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
        throw FirebaseAuthException.mfaRequired();
      }
      throw FirebaseAuthException.internalError();
    }
  }

  /// Validates a password
  void _validateStrongPassword(String? password) {
    if (password == null || password.isEmpty) {
      throw FirebaseAuthException.weakPassword();
    }
  }
}
