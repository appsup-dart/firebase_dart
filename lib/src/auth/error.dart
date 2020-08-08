import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/authcredential.dart';

/// Generic exception related to Firebase Authentication.
///
/// Check the error code and message for more details.
class AuthException extends FirebaseException {
  final String email;

  final String phoneNumber;

  final AuthCredential credential;

  AuthException._(
      {String code,
      String message,
      this.email,
      this.phoneNumber,
      this.credential})
      : super(plugin: 'auth', code: code, message: message);

  AuthException(String code, [String message])
      : this._(code: code, message: message);

  AuthException.adminOnlyOperation()
      : this('admin-restricted-operation',
            'This operation is restricted to administrators only');
  AuthException.argumentError(String message) : this('argument-error', '');
  AuthException.appNotAuthorized()
      : this(
            'app-not-authorized',
            'This app, identified by the domain where it\'s hosted, is not '
                'authorized to use Firebase Authentication with the provided API key. '
                'Review your key configuration in the Google API console');
  AuthException.appNotInstalled()
      : this(
            'app-not-installed',
            'The requested mobile application corresponding to the identifier ('
                'Android package name or iOS bundle ID) provided is not installed on '
                'this device');
  AuthException.captchaCheckFailed()
      : this(
            'captcha-check-failed',
            'The reCAPTCHA response token provided is either invalid, expired, '
                'already used or the domain associated with it does not match the list '
                'of whitelisted domains');
  AuthException.codeExpired()
      : this(
            'code-expired',
            'The SMS code has expired. Please re-send the verification code to try '
                'again');
  AuthException.cordovaNotReady()
      : this('cordova-not-ready', 'Cordova framework is not ready');
  AuthException.corsUnsupported()
      : this('cors-unsupported', 'This browser is not supported');
  AuthException.credentialAlreadyInUse()
      : this('credential-already-in-use',
            'This credential is already associated with a different user account');
  AuthException.credentialMismatch()
      : this('custom-token-mismatch',
            'The custom token corresponds to a different audience');
  AuthException.credentialTooOldLoginAgain()
      : this(
            'requires-recent-login',
            'This operation is sensitive and requires recent authentication. Log in '
                'again before retrying this request');
  AuthException.dynamicLinkNotActivated()
      : this(
            'dynamic-link-not-activated',
            'Please activate '
                'Dynamic Links in the Firebase Console and agree to the terms and '
                'conditions');
  AuthException.emailChangeNeedsVerification()
      : this('email-change-needs-verification',
            'Multi-factor users must always have a verified email.');
  AuthException.emailExists()
      : this('email-already-in-use',
            'The email address is already in use by another account');
  AuthException.expiredOobCode()
      : this('expired-action-code', 'The action code has expired. ');
  AuthException.expiredPopupRequest()
      : this(
            'cancelled-popup-request',
            'This operation has been cancelled due to another conflicting popup '
                'being opened');
  AuthException.internalError()
      : this('internal-error', 'An internal error has occurred');
  AuthException.invalidApiKey()
      : this('invalid-api-key',
            'Your API key is invalid, please check you have copied it correctly');
  AuthException.invalidAppCredential()
      : this(
            'invalid-app-credential',
            'The phone verification request contains an invalid application verifier.'
                ' The reCAPTCHA token response is either invalid or expired');
  AuthException.invalidAppId()
      : this('invalid-app-id',
            'The mobile app identifier is not registed for the current project');
  AuthException.invalidAuth()
      : this(
            'invalid-user-token',
            'This user\'s credential isn\'t valid for this project. This can happen '
                'if the user\'s token has been tampered with, or if the user isn\'t for '
                'the project associated with this API key');
  AuthException.invalidAuthEvent()
      : this('invalid-auth-event', 'An internal error has occurred');
  AuthException.invalidCertHash()
      : this('invalid-cert-hash',
            'The SHA-1 certificate hash provided is invalid');
  AuthException.invalidCode()
      : this(
            'invalid-verification-code',
            'The SMS verification code used to create the phone auth credential is '
                'invalid. Please resend the verification code sms and be sure use the '
                'verification code provided by the user');
  AuthException.invalidContinueUri()
      : this('invalid-continue-uri',
            'The continue URL provided in the request is invalid');
  AuthException.invalidCordovaConfiguration()
      : this(
            'invalid-cordova-configuration',
            'The following'
                ' Cordova plugins must be installed to enable OAuth sign-in: '
                'cordova-plugin-buildinfo, cordova-universal-links-plugin, '
                'cordova-plugin-browsertab, cordova-plugin-inappbrowser and '
                'cordova-plugin-customurlscheme');
  AuthException.invalidCustomToken()
      : this('invalid-custom-token',
            'The custom token format is incorrect. Please check the documentation');
  AuthException.invalidDynamicLinkDomain()
      : this(
            'invalid-dynamic-link-domain',
            'The provided '
                'dynamic link domain is not configured or authorized for the current '
                'project');
  AuthException.invalidEmail()
      : this('invalid-email', 'The email address is badly formatted');
  AuthException.invalidIdpResponse()
      : this('invalid-credential',
            'The supplied auth credential is malformed or has expired');
  AuthException.invalidMessagePayload()
      : this(
            'invalid-message-payload',
            'The email template corresponding to this action contains invalid charac'
                'ters in its message. Please fix by going to the Auth email templates se'
                'ction in the Firebase Console');
  AuthException.invalidMfaPendingCredential()
      : this(
            'invalid-multi-factor-session',
            'The request does not contain a valid proof of first factor successful '
                'sign-in.');
  AuthException.invalidOAuthClientId()
      : this(
            'invalid-oauth-client-id',
            'The OAuth client ID provided is either invalid or does not match the '
                'specified API key');
  AuthException.invalidOAuthProvider()
      : this(
            'invalid-oauth-provider',
            'EmailAuthProvider is not supported for this operation. This operation '
                'only supports OAuth providers');

  AuthException.invalidOobCode()
      : this(
            'invalid-action-code',
            'The action code is invalid. This can happen if the code is malformed, '
                'expired, or has already been used');
  AuthException.invalidOrigin()
      : this(
            'unauthorized-domain',
            'This domain is not authorized for OAuth operations for your Firebase '
                'project. Edit the list of authorized domains from the Firebase console');
  AuthException.invalidPassword()
      : this('wrong-password',
            'The password is invalid or the user does not have a password');
  AuthException.invalidPersistence()
      : this(
            'invalid-persistence-type',
            'The specified persistence type is invalid. It can only be local, '
                'session or none');
  AuthException.invalidPhoneNumber()
      : this(
            'invalid-phone-number',
            'The format of the phone number provided is incorrect. Please enter the '
                'phone number in a format that can be parsed into E.164 format. E.164 '
                'phone numbers are written in the format [+][country code][subscriber '
                'number including area code]');
  AuthException.invalidProviderId()
      : this('invalid-provider-id', 'The specified provider ID is invalid');
  AuthException.invalidRecipientEmail()
      : this(
            'invalid-recipient-email',
            'The email corresponding to this action failed to send as the provided '
                'recipient email address is invalid');
  AuthException.invalidSender()
      : this(
            'invalid-sender',
            'The email template corresponding to this action contains an invalid sen'
                'der email or name. Please fix by going to the Auth email templates sect'
                'ion in the Firebase Console');
  AuthException.invalidSessionInfo()
      : this('invalid-verification-id',
            'The verification ID used to create the phone auth credential is invalid');
  AuthException.invalidTenantId()
      : this('invalid-tenant-id', 'The Auth instance\'s tenant ID is invalid.');
  AuthException.mfaEnrollmentNotFound()
      : this(
            'multi-factor-info-not-found',
            'The user does not '
                'have a second factor matching the identifier provided.');
  AuthException.mfaRequired()
      : this('multi-factor-auth-required',
            'Proof of ownership of a second factor is required to complete sign-in.');

  AuthException.missingAndroidPackageName()
      : this(
            'missing-android-pkg-name',
            'An Android '
                'Package Name must be provided if the Android App is required to be '
                'installed');
  AuthException.missingAppCredential()
      : this(
            'missing-app-credential',
            'The phone verification request is missing an application verifier '
                'assertion. A reCAPTCHA response token needs to be provided');
  AuthException.missingAuthDomain()
      : this(
            'auth-domain-config-required',
            'Be sure to include authDomain when calling firebase.initializeApp(), '
                'by following the instructions in the Firebase console');
  AuthException.missingCode()
      : this(
            'missing-verification-code',
            'The phone auth credential was created with an empty SMS verification '
                'code');
  AuthException.missingContinueUri()
      : this('missing-continue-uri',
            'A continue URL must be provided in the request');
  AuthException.missingIframeStart()
      : this('missing-iframe-start', 'An internal error has occurred');
  AuthException.missingIosBundleId()
      : this('missing-ios-bundle-id',
            'An iOS Bundle ID must be provided if an App Store ID is provided');
  AuthException.missingMfaEnrollmentId()
      : this('missing-multi-factor-info',
            'No second factor identifier is provided.');
  AuthException.missingMfaPendingCredential()
      : this('missing-multi-factor-session',
            'The request is missing proof of first factor successful sign-in.');
  AuthException.missingOrInvalidNonce()
      : this('missing-or-invalid-nonce',
            'The OIDC ID token requires a valid unhashed nonce');
  AuthException.missingPhoneNumber()
      : this('missing-phone-number',
            'To send verification codes, provide a phone number for the recipient');
  AuthException.missingSessionInfo()
      : this('missing-verification-id',
            'The phone auth credential was created with an empty verification ID');

  AuthException.moduleDestroyed()
      : this('app-deleted', 'This instance of FirebaseApp has been deleted');
  AuthException.needConfirmation()
      : this(
            'account-exists-with-different-credential',
            'An account already exists with the same email address but different '
                'sign-in credentials. Sign in using a provider associated with this '
                'email address');
  AuthException.networkRequestFailed()
      : this(
            'network-request-failed',
            'A network error (such as timeout, interrupted connection or '
                'unreachable host) has occurred');
  AuthException.nullUser()
      : this(
            'null-user',
            'A null user object was provided as the argument for an operation which '
                'requires a non-null user object');
  AuthException.noAuthEvent()
      : this('no-auth-event', 'An internal error has occurred');
  AuthException.noSuchProvider()
      : this('no-such-provider',
            'User was not linked to an account with the given provider');
  AuthException.operationNotAllowed()
      : this(
            'operation-not-allowed',
            'The given sign-in provider is disabled for this Firebase project. '
                'Enable it in the Firebase console, under the sign-in method tab of the '
                'Auth section');
  AuthException.operationNotSupported()
      : this(
            'operation-not-supported-in-this-environment',
            'This operation is not supported in the environment this application is '
                'running on. "location.protocol" must be http, https or chrome-extension'
                ' and web storage must be enabled');
  AuthException.popupBlocked()
      : this(
            'popup-blocked',
            'Unable to establish a connection with the popup. It may have been '
                'blocked by the browser');
  AuthException.popupClosedByUser()
      : this('popup-closed-by-user',
            'The popup has been closed by the user before finalizing the operation');
  AuthException.providerAlreadyLinked()
      : this('provider-already-linked',
            'User can only be linked to one identity for the given provider');

  AuthException.quotaExceeded()
      : this('quota-exceeded',
            'The project\'s quota for this operation has been exceeded');
  AuthException.redirectCancelledByUser()
      : this('redirect-cancelled-by-user',
            'The redirect operation has been cancelled by the user before finalizing');
  AuthException.redirectOperationPending()
      : this('redirect-operation-pending',
            'A redirect sign-in operation is already pending');
  AuthException.rejectedCredential()
      : this('rejected-credential',
            'The request contains malformed or mismatching credentials');
  AuthException.secondFactorExists()
      : this('second-factor-already-in-use',
            'The second factor is already enrolled on this account.');
  AuthException.secondFactorLimitExceeded()
      : this('maximum-second-factor-count-exceeded',
            'The maximum allowed number of second factors on a user has been exceeded.');
  AuthException.tenantIdMismatch()
      : this('tenant-id-mismatch',
            'The provided tenant ID does not match the Auth instance\'s tenant ID');
  AuthException.timeout() : this('timeout', 'The operation has timed out');
  AuthException.tokenExpired()
      : this('user-token-expired',
            'The user\'s credential is no longer valid. The user must sign in again');
  AuthException.tooManyAttemptsTryLater()
      : this(
            'too-many-requests',
            'We have blocked all requests from this device due to unusual activity. '
                'Try again later');
  AuthException.unauthorizedDomain()
      : this(
            'unauthorized-continue-uri',
            'The domain of the continue URL is not whitelisted.  Please whitelist '
                'the domain in the Firebase console');
  AuthException.unsupportedFirstFactor()
      : this(
            'unsupported-first-factor',
            'Enrolling a second '
                'factor or signing in with a multi-factor account requires sign-in with '
                'a supported first factor.');
  AuthException.unsupportedPersistence()
      : this('unsupported-persistence-type',
            'The current environment does not support the specified persistence type');
  AuthException.unsupportedTenantOperation()
      : this('unsupported-tenant-operation',
            'This operation is not supported in a multi-tenant context.');
  AuthException.unverifiedEmail()
      : this('unverified-email', 'The operation requires a verified email.');
  AuthException.userCancelled()
      : this('user-cancelled',
            'User did not grant your application the permissions it requested');
  AuthException.userDeleted()
      : this(
            'user-not-found',
            'There is no user record corresponding to this identifier. The user may '
                'have been deleted');
  AuthException.userDisabled()
      : this('user-disabled',
            'The user account has been disabled by an administrator');
  AuthException.userMismatch()
      : this(
            'user-mismatch',
            'The supplied credentials do not correspond to the previously signed in '
                'user');
  AuthException.userSignedOut() : this('user-signed-out', '');
  AuthException.weakPassword()
      : this('weak-password', 'The password must be 6 characters long or more');
  AuthException.webStorageUnsupported()
      : this(
            'web-storage-unsupported',
            'This browser is not supported or 3rd party cookies and data may be '
                'disabled');

  AuthException replace(
          {String message,
          String email,
          String phoneNumber,
          AuthCredential credential}) =>
      AuthException._(
          code: code,
          message: message ?? this.message,
          email: email ?? this.email,
          phoneNumber: phoneNumber ?? this.phoneNumber,
          credential: credential ?? this.credential);

  @override
  int get hashCode =>
      super.hashCode +
      email.hashCode +
      phoneNumber.hashCode +
      credential.hashCode;

  @override
  bool operator ==(other) =>
      other is AuthException &&
      other.code == code &&
      other.message == message &&
      other.email == email &&
      other.phoneNumber == phoneNumber &&
      other.credential == credential;
}
