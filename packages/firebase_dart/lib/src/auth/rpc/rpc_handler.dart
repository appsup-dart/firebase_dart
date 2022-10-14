import 'dart:convert';

import 'package:firebase_dart/src/auth/providers/saml.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:firebaseapis/identitytoolkit/v2.dart' hide IdentityToolkitApi;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:openid_client/openid_client.dart' as openid;
import 'identitytoolkit.dart';

import '../action_code.dart';
import '../auth_credential.dart';
import '../auth_provider.dart';
import '../error.dart';
import '../multi_factor.dart';
import 'error.dart';
import 'http_util.dart';

class RpcHandler {
  final IdentityToolkitApi identitytoolkitApi;

  final http.Client httpClient;

  final String apiKey;

  /// The tenant ID.
  String? tenantId;

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
                headers: {'Content-Type': 'application/json'},
                request: request);
          }),
          RegExp('.*'): httpClient ?? http.Client(),
        }),
        identitytoolkitApi = IdentityToolkitApi(
            ApiKeyClient(httpClient ?? http.Client(), apiKey: apiKey));

  /// Gets the list of authorized domains for the specified project.
  Future<List<String>?> getAuthorizedDomains() async {
    var response = await identitytoolkitApi.v1.getProjects();
    return response.authorizedDomains;
  }

  /// reCAPTCHA.
  Future<String> getRecaptchaParam() async {
    var response = await identitytoolkitApi.v1.getRecaptchaParams();

    if (response.recaptchaSiteKey == null) {
      throw FirebaseAuthException.internalError();
    }

    return response.recaptchaSiteKey!;
  }

  /// Gets the list of authorized domains for the specified project.
  Future<String?> getDynamicLinkDomain() async {
    var response = await identitytoolkitApi.v1
        .getProjects($fields: _toQueryString({'returnDynamicLink': 'true'}));

    if (response.dynamicLinksDomain == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.dynamicLinksDomain;
  }

  /// Checks if the provided iOS bundle ID belongs to the project.
  Future<void> isIosBundleIdValid(String iosBundleId) async {
    // This will either resolve if the identifier is valid or throw
    // INVALID_APP_ID if not.
    await identitytoolkitApi.v1
        .getProjects($fields: _toQueryString({'iosBundleId': iosBundleId}));
  }

  /// Checks if the provided Android package name belongs to the project.
  Future<void> isAndroidPackageNameValid(String androidPackageName,
      [String? sha1Cert]) async {
    // When no sha1Cert is passed, this will either resolve if the identifier is
    // valid or throw INVALID_APP_ID if not.
    // When sha1Cert is also passed, this will either resolve or fail with an
    // INVALID_CERT_HASH error.
    await identitytoolkitApi.v1.getProjects(
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
    await identitytoolkitApi.v1
        .getProjects($fields: _toQueryString({'clientId': clientId}));
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
  Future<GoogleCloudIdentitytoolkitV1UserInfo> getAccountInfoByIdToken(
      String idToken) async {
    var response = await _handle(() => identitytoolkitApi.accounts.lookup(
        GoogleCloudIdentitytoolkitV1GetAccountInfoRequest()
          ..idToken = idToken));

    if (response.users!.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    return response.users!.first;
  }

  /// Sign in with a custom token
  ///
  /// Returns a future that resolves with the ID token.
  Future<SignInResult> signInWithCustomToken(String token) async {
    var response = await identitytoolkitApi.accounts.signInWithCustomToken(
        GoogleCloudIdentitytoolkitV1SignInWithCustomTokenRequest()
          ..token = token
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  /// Sign in with an an email link OTP
  ///
  /// Returns a future that resolves with the ID token.
  Future<SignInResult> signInWithEmailLink(String email, String oobCode) async {
    _validateEmail(email);
    if (oobCode.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    return _signInWithEmailLink(
        GoogleCloudIdentitytoolkitV1SignInWithEmailLinkRequest()
          ..email = email
          ..oobCode = oobCode
          ..tenantId = tenantId);
  }

  /// Verifies an email link OTP for linking and returns a Promise that resolves
  /// with the ID token.
  Future<SignInResult> signInWithEmailLinkForLinking(
      String idToken, String email, String oobCode) async {
    if (idToken.isEmpty || oobCode.isEmpty) {
      throw FirebaseAuthException.internalError();
    }
    _validateEmail(email);
    return _signInWithEmailLink(
        GoogleCloudIdentitytoolkitV1SignInWithEmailLinkRequest()
          ..idToken = idToken
          ..email = email
          ..oobCode = oobCode);
  }

  Future<SignInResult> _signInWithEmailLink(
      GoogleCloudIdentitytoolkitV1SignInWithEmailLinkRequest request) async {
    var response =
        await identitytoolkitApi.accounts.signInWithEmailLink(request);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: response.mfaPendingCredential,
      mfaInfo: response.mfaInfo,
    );
  }

  /// Sign in with a password
  ///
  /// Returns a future that resolves with the ID token.
  Future<SignInResult> signInWithPassword(
      String email, String? password) async {
    _validateEmail(email);
    _validatePassword(password);

    var response = await identitytoolkitApi.accounts.signInWithPassword(
        GoogleCloudIdentitytoolkitV1SignInWithPasswordRequest()
          ..email = email
          ..password = password
          ..returnSecureToken = true
          ..tenantId = tenantId);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: response.mfaPendingCredential,
      mfaInfo: response.mfaInfo,
    );
  }

  /// Creates an email/password account.
  ///
  /// Returns a future that resolves with the ID token.
  Future<SignInResult> signUp(String email, String? password) async {
    _validateEmail(email);
    _validateStrongPassword(password);
    var response = await identitytoolkitApi.accounts
        .signUp(GoogleCloudIdentitytoolkitV1SignUpRequest()
          ..email = email
          ..password = password
          ..tenantId = tenantId);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  /// Deletes the user's account corresponding to the idToken given.
  Future<void> deleteAccount(String? idToken) async {
    if (idToken == null) {
      throw FirebaseAuthException.internalError();
    }
    try {
      await identitytoolkitApi.accounts.delete(
          GoogleCloudIdentitytoolkitV1DeleteAccountRequest()
            ..idToken = idToken);
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
  Future<SignInResult> signInAnonymously() async {
    var response = await identitytoolkitApi.accounts.signUp(
        GoogleCloudIdentitytoolkitV1SignUpRequest()..tenantId = tenantId);

    if (response.idToken == null) {
      throw FirebaseAuthException.internalError();
    }

    return SignInResult.success(await _credentialFromIdToken(
        idToken: response.idToken!,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn));
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

  /// Sign in with Identity Provider
  Future<SignInResult> signInWithIdp(
      {String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingIdToken}) async {
    var request = GoogleCloudIdentitytoolkitV1SignInWithIdpRequest()
      ..postBody = postBody
      ..sessionId = sessionId
      ..requestUri = requestUri
      ..returnSecureToken = true
      ..pendingIdToken = pendingIdToken;

    return await _signInWithIdp(request);
  }

  /// Sign in with Identity Provider for federated account linking
  Future<SignInResult> signInWithIdpForLinking(
      {required String idToken,
      String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingToken}) async {
    return await _signInWithIdp(
        GoogleCloudIdentitytoolkitV1SignInWithIdpRequest()
          ..postBody = postBody
          ..pendingIdToken = pendingToken
          ..idToken = idToken
          ..sessionId = sessionId
          ..requestUri = requestUri);
  }

  /// Sign in with Identity Platform for an existing federated account
  Future<SignInResult> signInWithIdpForExisting(
      {String? sessionId,
      String? requestUri,
      String? postBody,
      String? pendingToken}) async {
    return await _signInWithIdp(
        GoogleCloudIdentitytoolkitV1SignInWithIdpRequest()
          ..returnIdpCredential = true
          ..autoCreate = false
          ..postBody = postBody
          ..pendingIdToken = pendingToken
          ..requestUri = requestUri
          ..sessionId = sessionId);
  }

  Future<SignInResult> _signInWithIdp(
      GoogleCloudIdentitytoolkitV1SignInWithIdpRequest request) async {
    // Force Auth credential to be returned on the following errors:
    // FEDERATED_USER_ID_ALREADY_LINKED
    // EMAIL_EXISTS
    _validateSignInWithIdpRequest(request);
    var response = await identitytoolkitApi.accounts.signInWithIdp(request
      ..returnIdpCredential = true
      ..returnSecureToken = true);
    if (response.errorMessage == 'USER_NOT_FOUND') {
      throw FirebaseAuthException.userDeleted();
    }
    response = _processSignInWithIdpResponse(request, response);
    _validateSignInWithIdpResponse(response);

    return SignInResult.success(await _credentialFromIdToken(
        idToken: response.idToken!,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn));
  }

  static String _toQueryString(Map<String, String> queryParameters) =>
      Uri(queryParameters: queryParameters).query;

  Future<GoogleCloudIdentitytoolkitV1CreateAuthUriResponse> _createAuthUri(
      String identifier) async {
    // createAuthUri returns an error if continue URI is not http or https.
    // For environments like Cordova, Chrome extensions, native frameworks, file
    // systems, etc, use http://localhost as continue URL.
    var continueUri = Platform.current is WebPlatform
        ? (Platform.current as WebPlatform).currentUrl
        : 'http://localhost';
    if (!['http', 'https'].contains(Uri.parse(continueUri).scheme)) {
      continueUri = 'http://localhost';
    }
    var response = await identitytoolkitApi.accounts
        .createAuthUri(GoogleCloudIdentitytoolkitV1CreateAuthUriRequest()
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

  Future<SignInResult> handleIdTokenResponse(
      {required String? idToken,
      required String? refreshToken,
      required String? expiresIn,
      required String? mfaPendingCredential,
      required List<GoogleCloudIdentitytoolkitV1MfaEnrollment>?
          mfaInfo}) async {
    if (idToken == null) {
      // User could be a second factor user.
      // When second factor is required, a pending credential is returned.
      if (mfaPendingCredential != null) {
        return SignInResult.mfaRequired(mfaPendingCredential, [
          for (var i in mfaInfo!)
            PhoneMultiFactorInfo(
                displayName: i.displayName,
                enrollmentTimestamp:
                    DateTime.parse(i.enrolledAt!).millisecondsSinceEpoch / 1000,
                uid: i.mfaEnrollmentId!,
                phoneNumber: i.phoneInfo!)
        ]);
      }
      throw FirebaseAuthException.internalError();
    }

    return SignInResult.success(await _credentialFromIdToken(
        idToken: idToken, refreshToken: refreshToken, expiresIn: expiresIn));
  }

  /// Requests getOobCode endpoint for passwordless email sign-in.
  ///
  /// Returns future that resolves with user's email.
  Future<String?> sendSignInLinkToEmail(
      {required String email, ActionCodeSettings? actionCodeSettings}) async {
    _validateEmail(email);
    var response = await identitytoolkitApi.accounts
        .sendOobCode(_createGetOobCodeRequest(actionCodeSettings)
          ..requestType = 'EMAIL_SIGNIN'
          ..email = email);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  GoogleCloudIdentitytoolkitV1GetOobCodeRequest _createGetOobCodeRequest(
      ActionCodeSettings? actionCodeSettings) {
    if (actionCodeSettings == null) {
      return GoogleCloudIdentitytoolkitV1GetOobCodeRequest();
    }
    return GoogleCloudIdentitytoolkitV1GetOobCodeRequest()
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
    var response = await identitytoolkitApi.accounts
        .sendOobCode(_createGetOobCodeRequest(actionCodeSettings)
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
    var response = await identitytoolkitApi.accounts
        .sendOobCode(_createGetOobCodeRequest(actionCodeSettings)
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
    var response = await identitytoolkitApi.accounts
        .resetPassword(GoogleCloudIdentitytoolkitV1ResetPasswordRequest()
          ..oobCode = code
          ..newPassword = newPassword);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Checks the validity of an email action code and returns the response
  /// received.
  Future<GoogleCloudIdentitytoolkitV1ResetPasswordResponse> checkActionCode(
      String code) async {
    _validateApplyActionCode(code);
    var response = await identitytoolkitApi.accounts.resetPassword(
        GoogleCloudIdentitytoolkitV1ResetPasswordRequest()..oobCode = code);

    _validateCheckActionCodeResponse(response);
    return response;
  }

  /// Applies an out-of-band email action code, such as an email verification
  /// code.
  Future<String?> applyActionCode(String code) async {
    _validateApplyActionCode(code);
    var response = await identitytoolkitApi.accounts.update(
        GoogleCloudIdentitytoolkitV1SetAccountInfoRequest()..oobCode = code);

    if (response.email == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.email;
  }

  /// Updates the providers for the account associated with the idToken.
  Future<GoogleCloudIdentitytoolkitV1SetAccountInfoResponse>
      deleteLinkedAccounts(
          String idToken, List<String>? providersToDelete) async {
    if (providersToDelete == null) {
      throw FirebaseAuthException.internalError();
    }
    try {
      return await identitytoolkitApi.accounts
          .update(GoogleCloudIdentitytoolkitV1SetAccountInfoRequest()
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
  Future<GoogleCloudIdentitytoolkitV1SetAccountInfoResponse> updateProfile(
      String idToken, Map<String, dynamic> profileData) async {
    var request = GoogleCloudIdentitytoolkitV1SetAccountInfoRequest()
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
    var response = await identitytoolkitApi.accounts.update(request);

    return response;
  }

  /// Requests setAccountInfo endpoint for updateEmail operation.
  Future<SignInResult> updateEmail(String idToken, String newEmail) async {
    _validateEmail(newEmail);
    var response = await identitytoolkitApi.accounts
        .update(GoogleCloudIdentitytoolkitV1SetAccountInfoRequest()
          ..idToken = idToken
          ..email = newEmail
          ..returnSecureToken = true);

    return handleIdTokenResponse(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        mfaPendingCredential: null,
        mfaInfo: null);
  }

  /// Requests setAccountInfo endpoint for updatePassword operation.
  Future<SignInResult> updatePassword(
      String idToken, String newPassword) async {
    _validateStrongPassword(newPassword);
    var response = await identitytoolkitApi.accounts
        .update(GoogleCloudIdentitytoolkitV1SetAccountInfoRequest()
          ..idToken = idToken
          ..password = newPassword
          ..returnSecureToken = true);

    return handleIdTokenResponse(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn,
        mfaPendingCredential: null,
        mfaInfo: null);
  }

  /// Requests createAuthUri endpoint to retrieve the authUri and session ID for
  /// the start of an OAuth handshake.
  Future<GoogleCloudIdentitytoolkitV1CreateAuthUriResponse> getAuthUri(
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
    var request = GoogleCloudIdentitytoolkitV1CreateAuthUriRequest()
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
    var response = await identitytoolkitApi.accounts.createAuthUri(request);
    _validateGetAuthResponse(response);
    return response;
  }

  /// Requests sendVerificationCode endpoint for verifying the user's ownership of
  /// a phone number. It resolves with a sessionInfo (verificationId).
  Future<String> sendVerificationCode({
    String? phoneNumber,
    String? appSignatureHash,
    String? recaptchaToken,
    String? safetyNetToken,
    String? iosReceipt,
    String? iosSecret,
  }) async {
    // In the future, we could support other types of assertions so for now,
    // we are keeping the request an object.

    if (phoneNumber == null ||
        (recaptchaToken == null &&
            safetyNetToken == null &&
            (iosReceipt == null || iosSecret == null))) {
      throw FirebaseAuthException.internalError();
    }

    var request = GoogleCloudIdentitytoolkitV1SendVerificationCodeRequest()
      ..phoneNumber = phoneNumber
      ..autoRetrievalInfo = appSignatureHash == null
          ? null
          : (GoogleCloudIdentitytoolkitV1AutoRetrievalInfo()
            ..appSignatureHash = appSignatureHash)
      ..recaptchaToken = recaptchaToken
      ..safetyNetToken = safetyNetToken
      ..iosReceipt = iosReceipt
      ..iosSecret = iosSecret;

    var response =
        await identitytoolkitApi.accounts.sendVerificationCode(request);
    if (response.sessionInfo == null) {
      throw FirebaseAuthException.internalError();
    }
    return response.sessionInfo!;
  }

  /// Sign in with phone number
  Future<SignInResult> signInWithPhoneNumber(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber}) async {
    var request = GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber;

    _validateSignInWithPhoneNumberRequest(request);

    var response =
        await identitytoolkitApi.accounts.signInWithPhoneNumber(request);
    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  /// Sign in with phone number for linking
  Future<SignInResult> signInWithPhoneNumberForLinking(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber,
      String? idToken}) async {
    // idToken should be required here.
    if (idToken == null) {
      throw FirebaseAuthException.internalError();
    }
    var request = GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber
      ..idToken = idToken;
    _validateSignInWithPhoneNumberRequest(request);

    var response =
        await identitytoolkitApi.accounts.signInWithPhoneNumber(request);

    if (response.temporaryProof != null) {
      throw _errorInfoFromResponse(
          FirebaseAuthException.credentialAlreadyInUse(), response)!;
    }
    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  /// Sign in with phone number for reauthentication
  Future<SignInResult> signInWithPhoneNumberForExisting(
      {String? sessionInfo,
      String? code,
      String? temporaryProof,
      String? phoneNumber}) async {
    var request = GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest()
      ..sessionInfo = sessionInfo
      ..code = code
      ..temporaryProof = temporaryProof
      ..phoneNumber = phoneNumber
      ..operation = 'REAUTH';
    _validateSignInWithPhoneNumberRequest(request);

    var response =
        await identitytoolkitApi.accounts.signInWithPhoneNumber(request);

    if (response.temporaryProof != null) {
      throw _errorInfoFromResponse(
          FirebaseAuthException.credentialAlreadyInUse(), response)!;
    }
    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  Future<String> startMultiFactorEnrollment(
      {required String idToken,
      String? phoneNumber,
      String? appSignatureHash,
      String? recaptchaToken,
      String? safetyNetToken,
      String? iosReceipt,
      String? iosSecret}) async {
    if (phoneNumber == null ||
        (recaptchaToken == null && safetyNetToken == null)) {
      throw FirebaseAuthException.internalError();
    }
    var info = GoogleCloudIdentitytoolkitV2StartMfaPhoneRequestInfo()
      ..phoneNumber = phoneNumber
      ..autoRetrievalInfo = appSignatureHash == null
          ? null
          : (GoogleCloudIdentitytoolkitV2AutoRetrievalInfo()
            ..appSignatureHash = appSignatureHash)
      ..recaptchaToken = recaptchaToken
      ..safetyNetToken = safetyNetToken
      ..iosReceipt = iosReceipt
      ..iosSecret = iosSecret;

    var request = GoogleCloudIdentitytoolkitV2StartMfaEnrollmentRequest()
      ..idToken = idToken
      ..phoneEnrollmentInfo = info;

    var response = await identitytoolkitApi.mfaEnrollment.start(request);

    return response.phoneSessionInfo!.sessionInfo!;
  }

  Future<SignInResult> finalizeMultiFactorEnrollment(
      {required String idToken,
      String? displayName,
      String? sessionInfo,
      String? code,
      String? phoneNumber}) async {
    var info = GoogleCloudIdentitytoolkitV2FinalizeMfaPhoneRequestInfo()
      ..sessionInfo = sessionInfo
      ..code = code
      ..phoneNumber = phoneNumber;

    var request = GoogleCloudIdentitytoolkitV2FinalizeMfaEnrollmentRequest()
      ..idToken = idToken
      ..displayName = displayName
      ..phoneVerificationInfo = info;

    var response = await identitytoolkitApi.mfaEnrollment.finalize(request);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: null,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  Future<SignInResult> withdrawMultiFactorEnrollment({
    required String idToken,
    required String mfaEnrollmentId,
    String? tenantId,
  }) async {
    var request = GoogleCloudIdentitytoolkitV2WithdrawMfaRequest()
      ..idToken = idToken
      ..mfaEnrollmentId = mfaEnrollmentId
      ..tenantId = tenantId;

    var response = await identitytoolkitApi.mfaEnrollment.withdraw(request);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: null,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  Future<String> startMultiFactorSignIn(
      {required String mfaPendingCredential,
      required String mfaEnrollmentId,
      String? appSignatureHash,
      String? recaptchaToken,
      String? safetyNetToken,
      String? iosReceipt,
      String? iosSecret}) async {
    var info = GoogleCloudIdentitytoolkitV2StartMfaPhoneRequestInfo()
      ..autoRetrievalInfo = appSignatureHash == null
          ? null
          : (GoogleCloudIdentitytoolkitV2AutoRetrievalInfo()
            ..appSignatureHash = appSignatureHash)
      ..recaptchaToken = recaptchaToken
      ..safetyNetToken = safetyNetToken
      ..iosReceipt = iosReceipt
      ..iosSecret = iosSecret;

    var request = GoogleCloudIdentitytoolkitV2StartMfaSignInRequest()
      ..mfaPendingCredential = mfaPendingCredential
      ..mfaEnrollmentId = mfaEnrollmentId
      ..phoneSignInInfo = info;
    var response = await identitytoolkitApi.mfaSignIn.start(request);

    return response.phoneResponseInfo!.sessionInfo!;
  }

  Future<SignInResult> finalizeMultiFactorSignIn(
      {required String mfaPendingCredential,
      String? sessionInfo,
      String? code,
      String? phoneNumber}) async {
    var info = GoogleCloudIdentitytoolkitV2FinalizeMfaPhoneRequestInfo()
      ..sessionInfo = sessionInfo
      ..code = code
      ..phoneNumber = phoneNumber;

    var request = GoogleCloudIdentitytoolkitV2FinalizeMfaSignInRequest()
      ..mfaPendingCredential = mfaPendingCredential
      ..phoneVerificationInfo = info;
    var response = await identitytoolkitApi.mfaSignIn.finalize(request);

    return handleIdTokenResponse(
      idToken: response.idToken,
      refreshToken: response.refreshToken,
      expiresIn: null,
      mfaPendingCredential: null,
      mfaInfo: null,
    );
  }

  Future<Duration> verifyIosClient(
      {required String appToken, required bool isSandbox}) async {
    var response = await identitytoolkitApi.accounts.verifyIosClient(
        GoogleCloudIdentitytoolkitV1VerifyIosClientRequest(
            appToken: appToken, isSandbox: isSandbox));

    var suggestedTimeout = response.suggestedTimeout;
    return Duration(
        seconds: (suggestedTimeout == null
                ? null
                : int.tryParse(suggestedTimeout)) ??
            5);
  }

  /// Validates a request that sends the verification ID and code for a sign in/up
  /// phone Auth flow.
  void _validateSignInWithPhoneNumberRequest(
      GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberRequest request) {
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
  void _validateGetAuthResponse(
      GoogleCloudIdentitytoolkitV1CreateAuthUriResponse response) {
    if (response.authUri == null) {
      throw FirebaseAuthException.internalError().replace(
          message:
              'Unable to determine the authorization endpoint for the specified '
              'provider. This may be an issue in the provider configuration.');
    } else if (response.sessionId == null) {
      throw FirebaseAuthException.internalError();
    }
  }

  FirebaseAuthException? _errorFromSignInWithIdpResponse(
      GoogleCloudIdentitytoolkitV1SignInWithIdpResponse response) {
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

  /// Validates a response from signInWithIdp.
  void _validateSignInWithIdpResponse(
      GoogleCloudIdentitytoolkitV1SignInWithIdpResponse response) {
    var error = _errorInfoFromResponse(
        _errorFromSignInWithIdpResponse(response), response);
    if (error != null) {
      throw error;
    }
  }

  FirebaseAuthException? _errorInfoFromResponse(
      FirebaseAuthException? error, Object response) {
    String? message, email, phoneNumber;
    if (response is GoogleCloudIdentitytoolkitV1SignInWithIdpResponse) {
      email = response.email;
    } else if (response
        is GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberResponse) {
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
    if (response is GoogleCloudIdentitytoolkitV1SignInWithPhoneNumberResponse) {
      return PhoneAuthProvider.credentialFromTemporaryProof(
          temporaryProof: response.temporaryProof!,
          phoneNumber: response.phoneNumber!);
    }

    if (response is GoogleCloudIdentitytoolkitV1SignInWithIdpResponse) {
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
                rawNonce: (response
                        as GoogleCloudIdentitytoolkitV1SignInWithIdpResponseWithNonce)
                    .nonce);
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

  /// Processes the signInWithIdp response and injects the same raw nonce
  /// if available in request.
  GoogleCloudIdentitytoolkitV1SignInWithIdpResponse
      _processSignInWithIdpResponse(
          GoogleCloudIdentitytoolkitV1SignInWithIdpRequest request,
          GoogleCloudIdentitytoolkitV1SignInWithIdpResponse response) {
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
        response =
            GoogleCloudIdentitytoolkitV1SignInWithIdpResponseWithNonce.from(
                response, request.sessionId!);
      } else if (request.postBody != null) {
        // For credential flow, the nonce is in the postBody nonce field.
        var queryData = Uri(query: request.postBody).queryParameters;
        if (queryData.containsKey('nonce')) {
          response =
              GoogleCloudIdentitytoolkitV1SignInWithIdpResponseWithNonce.from(
                  response, queryData['nonce']!);
        }
      }
    }

    return response;
  }

  /// Validates a signInWithIdp request.
  void _validateSignInWithIdpRequest(
      GoogleCloudIdentitytoolkitV1SignInWithIdpRequest request) {
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
  void _validateCheckActionCodeResponse(
      GoogleCloudIdentitytoolkitV1ResetPasswordResponse response) {
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

  /// Validates a password
  void _validateStrongPassword(String? password) {
    if (password == null || password.isEmpty) {
      throw FirebaseAuthException.weakPassword();
    }
  }
}

class GoogleCloudIdentitytoolkitV1SignInWithIdpResponseWithNonce
    extends GoogleCloudIdentitytoolkitV1SignInWithIdpResponse {
  final String nonce;

  GoogleCloudIdentitytoolkitV1SignInWithIdpResponseWithNonce.from(
      GoogleCloudIdentitytoolkitV1SignInWithIdpResponse other, this.nonce)
      : super.fromJson(other.toJson());

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'nonce': nonce,
      };
}

class SignInResult {
  final openid.Credential? _credential;

  final String? mfaPendingCredential;

  final List<MultiFactorInfo>? mfaInfo;

  SignInResult.success(openid.Credential credential)
      : _credential = credential,
        mfaPendingCredential = null,
        mfaInfo = null;

  SignInResult.mfaRequired(this.mfaPendingCredential, this.mfaInfo)
      : _credential = null;

  openid.Credential get credential => _credential == null
      ? throw FirebaseAuthException.mfaRequired()
      : _credential!;
}
