library firebase_auth;

import 'package:firebase_dart/core.dart';
import 'package:meta/meta.dart';

import '../implementation.dart';
import 'auth_credential.dart';
import 'auth_provider.dart';
import 'error.dart';
import 'multi_factor.dart';
import 'user.dart';
import 'action_code.dart';
import 'recaptcha_verifier.dart';

export 'auth_credential.dart';
export 'auth_provider.dart';
export 'error.dart';
export 'user.dart';
export 'action_code.dart';
export 'multi_factor.dart' hide PhoneMultiFactorAssertion;
export 'recaptcha_verifier.dart';

/// The entry point of the Firebase Authentication SDK.
abstract class FirebaseAuth {
  /// Returns an instance using a specified [FirebaseApp].
  factory FirebaseAuth.instanceFor({required FirebaseApp app}) {
    return FirebaseImplementation.installation.createAuth(app);
  }

  /// Returns an instance using the default [FirebaseApp].
  static final FirebaseAuth instance =
      FirebaseAuth.instanceFor(app: Firebase.app());

  /// The [FirebaseApp] for this current Auth instance.
  FirebaseApp get app;

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<User?> authStateChanges();

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out) and also token refresh events.
  Stream<User?> idTokenChanges();

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is to for listening to realtime updates to the user without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  Stream<User?> userChanges();

  /// Applies a verification code sent to the user by email or other out-of-band
  /// mechanism.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  Future<void> applyActionCode(String code);

  /// Checks a verification code sent to the user by email or other out-of-band
  /// mechanism.
  ///
  /// Returns [ActionCodeInfo] about the code.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  Future<ActionCodeInfo> checkActionCode(String code);

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **operation-not-allowed**:
  ///  - Thrown if anonymous accounts are not enabled. Enable anonymous accounts
  /// in the Firebase Console, under the Auth tab.
  Future<UserCredential> signInAnonymously();

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **email-already-in-use**:
  ///  - Thrown if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Returns a list of sign-in methods that can be used to sign in a given
  /// user (identified by its main email address).
  ///
  /// This method is useful when you support multiple authentication mechanisms
  /// if you want to implement an email-first authentication flow.
  ///
  /// An empty `List` is returned if the user could not be found.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  Future<List<String>> fetchSignInMethodsForEmail(String email);

  /// Returns a UserCredential from the redirect-based sign-in flow.
  ///
  /// If sign-in succeeded, returns the signed in user. If sign-in was
  /// unsuccessful, fails with an error. If no redirect operation was called,
  /// returns a [UserCredential] with a null User.
  ///
  /// This method is only support on web platforms.
  Future<UserCredential> getRedirectResult();

  /// Sends a password reset email to the given email address.
  ///
  /// To complete the password reset, call [confirmPasswordReset] with the code supplied
  /// in the email sent to the user, along with the new password specified by the user.
  ///
  /// May throw a [FirebaseAuthException] with the following error codes:
  ///
  /// - **auth/invalid-email**\
  ///   Thrown if the email address is not valid.
  /// - **auth/missing-android-pkg-name**\
  ///   An Android package name must be provided if the Android app is required to be installed.
  /// - **auth/missing-continue-uri**\
  ///   A continue URL must be provided in the request.
  /// - **auth/missing-ios-bundle-id**\
  ///   An iOS Bundle ID must be provided if an App Store ID is provided.
  /// - **auth/invalid-continue-uri**\
  ///   The continue URL provided in the request is invalid.
  /// - **auth/unauthorized-continue-uri**\
  ///   The domain of the continue URL is not whitelisted. Whitelist the domain in the Firebase console.
  /// - **auth/user-not-found**\
  ///   Thrown if there is no user corresponding to the email address.
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  });

  /// Sends a sign in with email link to provided email address.
  ///
  /// To complete the password reset, call [confirmPasswordReset] with the code
  /// supplied in the email sent to the user, along with the new password
  /// specified by the user.
  ///
  /// The [handleCodeInApp] of [actionCodeSettings] must be set to `true`
  /// otherwise an [ArgumentError] will be thrown.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the email address.
  Future<void> sendSignInLinkToEmail({
    required String email,
    required ActionCodeSettings actionCodeSettings,
  });

  /// Checks if an incoming link is a sign-in with email link.
  bool isSignInWithEmailLink(String link);

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in using an email address and email sign-in link.
  ///
  /// Fails with an error if the email address is invalid or OTP in email link
  /// expires.
  ///
  /// Confirm the link is a sign-in email link before calling this method,
  /// using [isSignInWithEmailLink].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if OTP in email link expires.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  Future<UserCredential> signInWithEmailLink(
      {required String email, required String emailLink});

  /// Asynchronously signs in to Firebase with the given 3rd-party credentials
  /// (e.g. a Facebook login Access Token, a Google ID Token/Access Token pair,
  /// etc.) and returns additional identity provider data.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// If the user doesn't have an account already, one will be created
  /// automatically.
  ///
  /// **Important**: You must enable the relevant accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **account-exists-with-different-credential**:
  ///  - Thrown if there already exists an account with the email address
  ///    asserted by the credential.
  ///    Resolve this by calling [fetchSignInMethodsForEmail] and then asking
  ///    the user to sign in using one of the returned providers.
  ///    Once the user is signed in, the original credential can be linked to
  ///    the user with [linkWithCredential].
  /// - **invalid-credential**:
  ///  - Thrown if the credential is malformed or has expired.
  /// - **operation-not-allowed**:
  ///  - Thrown if the type of account corresponding to the credential is not
  ///    enabled. Enable the account type in the Firebase Console, under the
  ///    Auth tab.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given credential has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and the password is invalid for the given email, or if the account
  ///    corresponding to the email does not have a password set.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.id.
  Future<UserCredential> signInWithCredential(AuthCredential credential);

  /// Signs in with an AuthProvider using native authentication flow.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  Future<UserCredential> signInWithAuthProvider(AuthProvider provider);

  /// Starts a sign-in flow for a phone number.
  ///
  /// You can optionally provide a [RecaptchaVerifier] instance to control the
  /// reCAPTCHA widget appearance and behavior.
  ///
  /// Once the reCAPTCHA verification has completed, called [ConfirmationResult.confirm]
  /// with the users SMS verification code to complete the authentication flow.
  ///
  /// This method is available on both web based platforms and other platforms.
  Future<ConfirmationResult> signInWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]);

  /// Authenticates a Firebase client using a popup-based OAuth authentication
  /// flow.
  ///
  /// If succeeds, returns the signed in user along with the provider's
  /// credential.
  ///
  /// This method is only available on web based platforms.
  Future<UserCredential> signInWithPopup(AuthProvider provider);

  /// Authenticates a Firebase client using a full-page redirect flow.
  ///
  /// To handle the results and errors for this operation, refer to
  /// [getRedirectResult].
  Future<void> signInWithRedirect(AuthProvider provider);

  /// Tries to sign in a user with a given custom token.
  ///
  /// Custom tokens are used to integrate Firebase Auth with existing auth
  /// systems, and must be generated by the auth backend.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// If the user identified by the [uid] specified in the token doesn't
  /// have an account already, one will be created automatically.
  ///
  /// Read how to use Custom Token authentication and the cases where it is
  /// useful in [the guides](https://firebase.google.com/docs/auth/android/custom-auth).
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **custom-token-mismatch**:
  ///  - Thrown if the custom token is for a different Firebase App.
  /// - **invalid-custom-token**:
  ///  - Thrown if the custom token format is incorrect.
  Future<UserCredential> signInWithCustomToken(String token);

  /// Signs out the current user.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  Future<void> signOut();

  /// Checks a password reset code sent to the user by email or other
  /// out-of-band mechanism.
  ///
  /// Returns the user's email address if valid.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the password reset code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the password reset code is invalid. This can happen if the
  ///    code is malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the password reset code.
  ///    This may have happened if the user was deleted between when the code
  ///    was issued and when this method was called.
  Future<String> verifyPasswordResetCode(String code);

  /// Starts a phone number verification process for the given phone number.
  ///
  /// This method is used to verify that the user-provided phone number belongs
  /// to the user. Firebase sends a code via SMS message to the phone number,
  /// where you must then prompt the user to enter the code. The code can be
  /// combined with the verification ID to create a [PhoneAuthProvider.credential]
  /// which you can then use to sign the user in, or link with their account (
  /// see [signInWithCredential] or [linkWithCredential]).
  ///
  /// On some Android devices, auto-verification can be handled by the device
  /// and a [PhoneAuthCredential] will be automatically provided.
  ///
  /// No duplicated SMS will be sent out unless a [forceResendingToken] is
  /// provided.
  ///
  /// [phoneNumber] The phone number for the account the user is signing up
  ///   for or signing into. Make sure to pass in a phone number with country
  ///   code prefixed with plus sign ('+').
  ///   Should be null if it's a multi-factor sign in.
  ///
  /// [multiFactorInfo] The multi factor info you're using to verify the phone number.
  ///   Should be set if a [multiFactorSession] is provided.
  ///
  /// [multiFactorSession] The multi factor session you're using to verify the phone number.
  ///   Should be set if a [multiFactorInfo] is provided.
  ///
  /// [timeout] The maximum amount of time you are willing to wait for SMS
  ///   auto-retrieval to be completed by the library. Maximum allowed value
  ///   is 2 minutes.
  ///
  /// [forceResendingToken] The [forceResendingToken] obtained from [codeSent]
  ///   callback to force re-sending another verification SMS before the
  ///   auto-retrieval timeout.
  ///
  /// [verificationCompleted] Triggered when an SMS is auto-retrieved or the
  ///   phone number has been instantly verified. The callback will receive an
  ///   [PhoneAuthCredential] that can be passed to [signInWithCredential] or
  ///   [linkWithCredential].
  ///
  /// [verificationFailed] Triggered when an error occurred during phone number
  ///   verification. A [FirebaseAuthException] is provided when this is
  ///   triggered.
  ///
  /// [codeSent] Triggered when an SMS has been sent to the users phone, and
  ///   will include a [verificationId] and [forceResendingToken].
  ///
  /// [codeAutoRetrievalTimeout] Triggered when SMS auto-retrieval times out and
  ///   provide a [verificationId].
  ///
  /// [verifier] The reCAPTCHA verifier instance to control the reCAPTCHA widget
  /// appearance and behavior on web based platforms.
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    @visibleForTesting String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
    RecaptchaVerifier? verifier,
  });

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// This getter only provides a snapshot of user state. Applictions that need
  /// to react to changes in user state should instead use [authStateChanges],
  /// [idTokenChanges] or [userChanges] to subscribe to updates.
  User? get currentUser;

  /// The current Auth instance's language code.
  ///
  /// See [setLanguageCode] to update the language code.
  String? get languageCode;

  /// When set to null, the default Firebase Console language setting is
  /// applied.
  ///
  /// The language code will propagate to email action templates (password
  /// reset, email verification and email change revocation), SMS templates for
  /// phone authentication, reCAPTCHA verifier and OAuth popup/redirect
  /// operations provided the specified providers support localization with the
  /// language code specified.
  Future<void> setLanguageCode(String language);

  /// Completes the password reset process, given a confirmation code and new
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  /// - **weak-password**:
  ///  - Thrown if the new password is not strong enough.
  Future<void> confirmPasswordReset(String oobCode, String newPassword);

  /// Changes the current type of persistence on the current Auth instance for
  /// the currently saved Auth session and applies this type of persistence for
  /// future sign-in requests, including sign-in with redirect requests.
  ///
  /// This will return a promise that will resolve once the state finishes
  /// copying from one type of storage to the other. Calling a sign-in method
  /// after changing persistence will wait for that persistence change to
  /// complete before applying it on the new Auth state.
  ///
  /// This makes it easy for a user signing in to specify whether their session
  /// should be remembered or not. It also makes it easier to never persist the
  /// Auth state for applications that are shared by other users or have
  /// sensitive data.
  ///
  /// This is only supported on web based platforms.
  Future<void> setPersistence(Persistence persistence);

  Future<UserCredential?> trySignInWithEmailLink(
      {Future<String?> Function()? askUserForEmail});
}

/// A UserCredential is returned from authentication requests such as
/// [createUserWithEmailAndPassword].
abstract class UserCredential {
  /// Returns a [User] containing additional information and user specific
  /// methods.
  User? get user;

  /// Returns additional information about the user, such as whether they are a
  /// newly created one.
  AdditionalUserInfo? get additionalUserInfo;

  /// The users [AuthCredential].
  AuthCredential? get credential;

  @override
  String toString() {
    return 'UserCredential(additionalUserInfo: ${additionalUserInfo.toString()}, credential: ${credential.toString()}, user: $user)';
  }
}

/// Typedef for handling automatic phone number timeout resolution.
typedef PhoneCodeAutoRetrievalTimeout = void Function(String verificationId);

/// Typedef for handling when Firebase sends a SMS code to the provided phone
/// number.
typedef PhoneCodeSent = void Function(
    String verificationId, int? forceResendingToken);

/// Typedef for a automatic phone number resolution.
///
/// This handler can only be called on supported Android devices.
typedef PhoneVerificationCompleted = void Function(
    PhoneAuthCredential phoneAuthCredential);

/// Typedef for handling errors via phone number verification.
typedef PhoneVerificationFailed = void Function(FirebaseAuthException error);

/// An enumeration of the possible persistence mechanism types.
///
/// Setting a persistence type is only available on web based platforms.
enum Persistence {
  /// Indicates that the state will be persisted even when the browser window is
  /// closed.
  local,

  /// Indicates that the state will only be stored in memory and will be
  /// cleared when the window or activity is refreshed.
  none,

  /// Indicates that the state will only persist in current session/tab,
  /// relevant to web only, and will be cleared when the tab is closed.
  session,
}

/// A result from a phone number sign-in, link, or reauthenticate call.
///
/// This class is only usable on web based platforms.
abstract class ConfirmationResult {
  /// The phone number authentication operation's verification ID.
  ///
  /// This can be used along with the verification code to initialize a phone
  /// auth credential.
  String get verificationId;

  /// Finishes a phone number sign-in, link, or reauthentication, given the code
  /// that was sent to the user's mobile device.
  Future<UserCredential> confirm(String verificationCode);
}
