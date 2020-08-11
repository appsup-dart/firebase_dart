import 'dart:convert';

import 'package:firebase_dart/src/auth/error.dart';

final _serverErrors = {
  // Custom token errors.
  'INVALID_CUSTOM_TOKEN': AuthException.invalidCustomToken(),
  'CREDENTIAL_MISMATCH': AuthException.credentialMismatch(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_CUSTOM_TOKEN': AuthException.internalError(),

  // Create Auth URI errors.
  'INVALID_IDENTIFIER': AuthException.invalidEmail(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_CONTINUE_URI': AuthException.internalError(),

  // Sign in with email and password errors (some apply to sign up too).
  'INVALID_EMAIL': AuthException.invalidEmail(),
  'INVALID_PASSWORD': AuthException.invalidPassword(),
  'USER_DISABLED': AuthException.userDisabled(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_PASSWORD': AuthException.internalError(),

  // Sign up with email and password errors.
  'EMAIL_EXISTS': AuthException.emailExists(),
  'PASSWORD_LOGIN_DISABLED': AuthException.operationNotAllowed(),

  // Verify assertion for sign in with credential errors:
  'INVALID_IDP_RESPONSE': AuthException.invalidIdpResponse(),
  'INVALID_PENDING_TOKEN': AuthException.invalidIdpResponse(),
  'FEDERATED_USER_ID_ALREADY_LINKED': AuthException.credentialAlreadyInUse(),
  'MISSING_OR_INVALID_NONCE': AuthException.missingOrInvalidNonce(),

  // Email template errors while sending emails:
  'INVALID_MESSAGE_PAYLOAD': AuthException.invalidMessagePayload(),
  'INVALID_RECIPIENT_EMAIL': AuthException.invalidRecipientEmail(),
  'INVALID_SENDER': AuthException.invalidSender(),

  // Send Password reset email errors:
  'EMAIL_NOT_FOUND': AuthException.userDeleted(),
  'RESET_PASSWORD_EXCEED_LIMIT': AuthException.tooManyAttemptsTryLater(),

  // Reset password errors:
  'EXPIRED_OOB_CODE': AuthException.expiredOobCode(),
  'INVALID_OOB_CODE': AuthException.invalidOobCode(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_OOB_CODE': AuthException.internalError(),

  // Get Auth URI errors:
  'INVALID_PROVIDER_ID': AuthException.invalidProviderId(),

  // Operations that require ID token in request:
  'CREDENTIAL_TOO_OLD_LOGIN_AGAIN': AuthException.credentialTooOldLoginAgain(),
  'INVALID_ID_TOKEN': AuthException.invalidAuth(),
  'TOKEN_EXPIRED': AuthException.tokenExpired(),
  'USER_NOT_FOUND': AuthException.userDeleted(),

  // CORS issues.
  'CORS_UNSUPPORTED': AuthException.corsUnsupported(),

  // Dynamic link not activated.
  'DYNAMIC_LINK_NOT_ACTIVATED': AuthException.dynamicLinkNotActivated(),

  // iosBundleId or androidPackageName not valid error.
  'INVALID_APP_ID': AuthException.invalidAppId(),

  // Other errors.
  'TOO_MANY_ATTEMPTS_TRY_LATER': AuthException.tooManyAttemptsTryLater(),
  'WEAK_PASSWORD': AuthException.weakPassword(),
  'OPERATION_NOT_ALLOWED': AuthException.operationNotAllowed(),
  'USER_CANCELLED': AuthException.userCancelled(),

  // Phone Auth related errors.
  'CAPTCHA_CHECK_FAILED': AuthException.captchaCheckFailed(),
  'INVALID_APP_CREDENTIAL': AuthException.invalidAppCredential(),
  'INVALID_CODE': AuthException.invalidCode(),
  'INVALID_PHONE_NUMBER': AuthException.invalidPhoneNumber(),
  'INVALID_SESSION_INFO': AuthException.invalidSessionInfo(),
  'INVALID_TEMPORARY_PROOF': AuthException.invalidIdpResponse(),
  'MISSING_APP_CREDENTIAL': AuthException.missingAppCredential(),
  'MISSING_CODE': AuthException.missingCode(),
  'MISSING_PHONE_NUMBER': AuthException.missingPhoneNumber(),
  'MISSING_SESSION_INFO': AuthException.missingSessionInfo(),
  'QUOTA_EXCEEDED': AuthException.quotaExceeded(),
  'SESSION_EXPIRED': AuthException.codeExpired(),
  'REJECTED_CREDENTIAL': AuthException.rejectedCredential(),

  // Other action code errors when additional settings passed.
  'INVALID_CONTINUE_URI': AuthException.invalidContinueUri(),

  // MISSING_CONTINUE_URI is getting mapped to INTERNAL_ERROR above.
  // This is OK as this error will be caught by client side validation.
  'MISSING_ANDROID_PACKAGE_NAME': AuthException.missingAndroidPackageName(),
  'MISSING_IOS_BUNDLE_ID': AuthException.missingIosBundleId(),
  'UNAUTHORIZED_DOMAIN': AuthException.unauthorizedDomain(),
  'INVALID_DYNAMIC_LINK_DOMAIN': AuthException.invalidDynamicLinkDomain(),

  // getProjectConfig errors when clientId is passed.
  'INVALID_OAUTH_CLIENT_ID': AuthException.invalidOAuthClientId(),

  // getProjectConfig errors when sha1Cert is passed.
  'INVALID_CERT_HASH': AuthException.invalidCertHash(),

  // Multi-tenant related errors.
  'UNSUPPORTED_TENANT_OPERATION': AuthException.unsupportedTenantOperation(),
  'INVALID_TENANT_ID': AuthException.invalidTenantId(),
  'TENANT_ID_MISMATCH': AuthException.tenantIdMismatch(),

  // User actions (sign-up or deletion) disabled errors.
  'ADMIN_ONLY_OPERATION': AuthException.adminOnlyOperation(),

  // Multi-factor related errors.
  'INVALID_MFA_PENDING_CREDENTIAL': AuthException.invalidMfaPendingCredential(),
  'MFA_ENROLLMENT_NOT_FOUND': AuthException.mfaEnrollmentNotFound(),
  'MISSING_MFA_PENDING_CREDENTIAL': AuthException.missingMfaPendingCredential(),
  'MISSING_MFA_ENROLLMENT_ID': AuthException.missingMfaEnrollmentId(),
  'EMAIL_CHANGE_NEEDS_VERIFICATION':
      AuthException.emailChangeNeedsVerification(),
  'SECOND_FACTOR_EXISTS': AuthException.secondFactorExists(),
  'SECOND_FACTOR_LIMIT_EXCEEDED': AuthException.secondFactorLimitExceeded(),
  'UNSUPPORTED_FIRST_FACTOR': AuthException.unsupportedFirstFactor(),
  'UNVERIFIED_EMAIL': AuthException.unverifiedEmail(),
};

AuthException authErrorFromServerErrorCode(String errorCode) {
  return _serverErrors[errorCode];
}

Map<String, dynamic> errorToServerResponse(AuthException error) {
  var code = _serverErrors.entries
      .firstWhere((element) => element.value.code == error.code)
      .key;

  return {
    'error': {'code': 400, 'message': '$code: ${error.message}'}
  };
}

AuthException authErrorFromResponse(Map<String, dynamic> data,
    [AuthException Function(String) errorMapper]) {
  var error = data['error'] is Map && data['error']['errors'] is List
      ? data['error']['errors'][0]
      : {};
  var reason = error['reason'] ?? '';

  switch (reason) {
    case 'keyInvalid':
      return AuthException.invalidApiKey();
    case 'ipRefererBlocked':
      return AuthException.appNotAuthorized();
  }
  var errorCode = data['error'] is Map
      ? data['error']['message']
      : data['error'] is String ? data['error'] : null;

  if (errorCode == null) {
    throw AuthException.internalError().replace(
      message: 'An internal error occurred while attempting to extract the '
          'errorcode from the error.',
    );
  }

  var errorMessage;

// Get detailed message if available.
  var match = RegExp(r'^[^\s]+\s*:\s*(.*)$').firstMatch(errorCode);
  if (match != null) {
    errorCode = match.group(1);
    errorMessage = match.group(2);
  }

  if (errorMapper != null) {
    var e = errorMapper(errorCode);
    if (e != null) throw e;
  }

  var e = authErrorFromServerErrorCode(errorCode);
  if (e != null) throw e.replace(message: errorMessage);

// No error message found, return the serialized response as the message.
// This is likely to be an Apiary error for unexpected cases like keyExpired,
// etc.
  if (errorMessage == null && data != null) {
    errorMessage = json.encode(data);
  }
// The backend returned some error we don't recognize; this is an error on
// our side.
  return AuthException.internalError().replace(message: errorMessage);
}
