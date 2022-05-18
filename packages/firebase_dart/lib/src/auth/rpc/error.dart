import 'dart:convert';

import 'package:firebase_dart/src/auth/error.dart';

final _serverErrors = {
  // Custom token errors.
  'INVALID_CUSTOM_TOKEN': FirebaseAuthException.invalidCustomToken(),
  'CREDENTIAL_MISMATCH': FirebaseAuthException.credentialMismatch(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_CUSTOM_TOKEN': FirebaseAuthException.internalError(),

  // Create Auth URI errors.
  'INVALID_IDENTIFIER': FirebaseAuthException.invalidEmail(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_CONTINUE_URI': FirebaseAuthException.internalError(),

  // Sign in with email and password errors (some apply to sign up too).
  'INVALID_EMAIL': FirebaseAuthException.invalidEmail(),
  'INVALID_PASSWORD': FirebaseAuthException.invalidPassword(),
  'USER_DISABLED': FirebaseAuthException.userDisabled(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_PASSWORD': FirebaseAuthException.internalError(),

  // Sign up with email and password errors.
  'EMAIL_EXISTS': FirebaseAuthException.emailExists(),
  'PASSWORD_LOGIN_DISABLED': FirebaseAuthException.operationNotAllowed(),

  // Verify assertion for sign in with credential errors:
  'INVALID_IDP_RESPONSE': FirebaseAuthException.invalidIdpResponse(),
  'INVALID_PENDING_TOKEN': FirebaseAuthException.invalidIdpResponse(),
  'FEDERATED_USER_ID_ALREADY_LINKED':
      FirebaseAuthException.credentialAlreadyInUse(),
  'MISSING_OR_INVALID_NONCE': FirebaseAuthException.missingOrInvalidNonce(),

  // Email template errors while sending emails:
  'INVALID_MESSAGE_PAYLOAD': FirebaseAuthException.invalidMessagePayload(),
  'INVALID_RECIPIENT_EMAIL': FirebaseAuthException.invalidRecipientEmail(),
  'INVALID_SENDER': FirebaseAuthException.invalidSender(),

  // Send Password reset email errors:
  'EMAIL_NOT_FOUND': FirebaseAuthException.userDeleted(),
  'RESET_PASSWORD_EXCEED_LIMIT':
      FirebaseAuthException.tooManyAttemptsTryLater(),

  // Reset password errors:
  'EXPIRED_OOB_CODE': FirebaseAuthException.expiredOobCode(),
  'INVALID_OOB_CODE': FirebaseAuthException.invalidOobCode(),

  // This can only happen if the SDK sends a bad request.
  'MISSING_OOB_CODE': FirebaseAuthException.internalError(),

  // Get Auth URI errors:
  'INVALID_PROVIDER_ID': FirebaseAuthException.invalidProviderId(),

  // Operations that require ID token in request:
  'CREDENTIAL_TOO_OLD_LOGIN_AGAIN':
      FirebaseAuthException.credentialTooOldLoginAgain(),
  'INVALID_ID_TOKEN': FirebaseAuthException.invalidAuth(),
  'TOKEN_EXPIRED': FirebaseAuthException.tokenExpired(),
  'USER_NOT_FOUND': FirebaseAuthException.userDeleted(),

  // CORS issues.
  'CORS_UNSUPPORTED': FirebaseAuthException.corsUnsupported(),

  // Dynamic link not activated.
  'DYNAMIC_LINK_NOT_ACTIVATED': FirebaseAuthException.dynamicLinkNotActivated(),

  // iosBundleId or androidPackageName not valid error.
  'INVALID_APP_ID': FirebaseAuthException.invalidAppId(),

  // Other errors.
  'TOO_MANY_ATTEMPTS_TRY_LATER':
      FirebaseAuthException.tooManyAttemptsTryLater(),
  'WEAK_PASSWORD': FirebaseAuthException.weakPassword(),
  'OPERATION_NOT_ALLOWED': FirebaseAuthException.operationNotAllowed(),
  'USER_CANCELLED': FirebaseAuthException.userCancelled(),

  // Phone Auth related errors.
  'CAPTCHA_CHECK_FAILED': FirebaseAuthException.captchaCheckFailed(),
  'INVALID_APP_CREDENTIAL': FirebaseAuthException.invalidAppCredential(),
  'INVALID_CODE': FirebaseAuthException.invalidCode(),
  'INVALID_PHONE_NUMBER': FirebaseAuthException.invalidPhoneNumber(),
  'INVALID_SESSION_INFO': FirebaseAuthException.invalidSessionInfo(),
  'INVALID_TEMPORARY_PROOF': FirebaseAuthException.invalidIdpResponse(),
  'MISSING_APP_CREDENTIAL': FirebaseAuthException.missingAppCredential(),
  'MISSING_CODE': FirebaseAuthException.missingCode(),
  'MISSING_PHONE_NUMBER': FirebaseAuthException.missingPhoneNumber(),
  'MISSING_SESSION_INFO': FirebaseAuthException.missingSessionInfo(),
  'QUOTA_EXCEEDED': FirebaseAuthException.quotaExceeded(),
  'SESSION_EXPIRED': FirebaseAuthException.codeExpired(),
  'REJECTED_CREDENTIAL': FirebaseAuthException.rejectedCredential(),

  // Other action code errors when additional settings passed.
  'INVALID_CONTINUE_URI': FirebaseAuthException.invalidContinueUri(),

  // MISSING_CONTINUE_URI is getting mapped to INTERNAL_ERROR above.
  // This is OK as this error will be caught by client side validation.
  'MISSING_ANDROID_PACKAGE_NAME':
      FirebaseAuthException.missingAndroidPackageName(),
  'MISSING_IOS_BUNDLE_ID': FirebaseAuthException.missingIosBundleId(),
  'UNAUTHORIZED_DOMAIN': FirebaseAuthException.unauthorizedDomain(),
  'INVALID_DYNAMIC_LINK_DOMAIN':
      FirebaseAuthException.invalidDynamicLinkDomain(),

  // getProjectConfig errors when clientId is passed.
  'INVALID_OAUTH_CLIENT_ID': FirebaseAuthException.invalidOAuthClientId(),

  // getProjectConfig errors when sha1Cert is passed.
  'INVALID_CERT_HASH': FirebaseAuthException.invalidCertHash(),

  // Multi-tenant related errors.
  'UNSUPPORTED_TENANT_OPERATION':
      FirebaseAuthException.unsupportedTenantOperation(),
  'INVALID_TENANT_ID': FirebaseAuthException.invalidTenantId(),
  'TENANT_ID_MISMATCH': FirebaseAuthException.tenantIdMismatch(),

  // User actions (sign-up or deletion) disabled errors.
  'ADMIN_ONLY_OPERATION': FirebaseAuthException.adminOnlyOperation(),

  // Multi-factor related errors.
  'INVALID_MFA_PENDING_CREDENTIAL':
      FirebaseAuthException.invalidMfaPendingCredential(),
  'MFA_ENROLLMENT_NOT_FOUND': FirebaseAuthException.mfaEnrollmentNotFound(),
  'MISSING_MFA_PENDING_CREDENTIAL':
      FirebaseAuthException.missingMfaPendingCredential(),
  'MISSING_MFA_ENROLLMENT_ID': FirebaseAuthException.missingMfaEnrollmentId(),
  'EMAIL_CHANGE_NEEDS_VERIFICATION':
      FirebaseAuthException.emailChangeNeedsVerification(),
  'SECOND_FACTOR_EXISTS': FirebaseAuthException.secondFactorExists(),
  'SECOND_FACTOR_LIMIT_EXCEEDED':
      FirebaseAuthException.secondFactorLimitExceeded(),
  'UNSUPPORTED_FIRST_FACTOR': FirebaseAuthException.unsupportedFirstFactor(),
  'UNVERIFIED_EMAIL': FirebaseAuthException.unverifiedEmail(),
};

FirebaseAuthException? authErrorFromServerErrorCode(String errorCode) {
  return _serverErrors[errorCode];
}

Map<String, dynamic> errorToServerResponse(FirebaseAuthException error) {
  var code = _serverErrors.entries
      .firstWhere((element) => element.value.code == error.code)
      .key;

  return {
    'error': {'code': 400, 'message': '$code: ${error.message}'}
  };
}

FirebaseAuthException authErrorFromResponse(Map<String, dynamic> data) {
  var error = data['error'] is Map && data['error']['errors'] is List
      ? data['error']['errors'][0]
      : {};
  var reason = error['reason'] ?? '';

  switch (reason) {
    case 'keyInvalid':
      return FirebaseAuthException.invalidApiKey();
    case 'ipRefererBlocked':
      return FirebaseAuthException.appNotAuthorized();
  }
  var errorCode = data['error'] is Map
      ? data['error']['message']
      : data['error'] is String
          ? data['error']
          : null;

  if (errorCode == null) {
    throw FirebaseAuthException.internalError().replace(
      message: 'An internal error occurred while attempting to extract the '
          'errorcode from the error.',
    );
  }

  String? errorMessage;

// Get detailed message if available.
  var match = RegExp(r'^[^\s]+\s*:\s*(.*)$').firstMatch(errorCode);
  if (match != null) {
    errorCode = match.group(1);
    errorMessage = match.group(2);
  }

  var e = authErrorFromServerErrorCode(errorCode);
  if (e != null) throw e.replace(message: errorMessage);

// No error message found, return the serialized response as the message.
// This is likely to be an Apiary error for unexpected cases like keyExpired,
// etc.
  errorMessage ??= json.encode(data);
// The backend returned some error we don't recognize; this is an error on
// our side.
  return FirebaseAuthException.internalError().replace(message: errorMessage);
}
