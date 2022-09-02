import 'package:firebase_dart/src/auth/auth.dart';

/// A user account.
abstract class User {
  User();

  /// The user's unique ID.
  String get uid;

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  String? get displayName;

  /// Returns a photo URL for the user.
  ///
  /// This property will be populated if the user has signed in or been linked
  /// with a 3rd party OAuth provider (such as Google).
  String? get photoURL;

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  String? get email;

  /// Returns the users phone number.
  ///
  /// This property will be `null` if the user has not signed in or been has
  /// their phone number linked.
  String? get phoneNumber;

  /// Returns whether the user is a anonymous.
  bool get isAnonymous;

  /// Returns whether the users email address has been verified.
  ///
  /// To send a verification email, see [sendEmailVerification].
  ///
  /// Once verified, call [reload] to ensure the latest user information is
  /// retrieved from Firebase.
  bool get emailVerified;

  /// Returns additional metadata about the user, such as their creation time.
  UserMetadata get metadata;

  /// Returns a list of user information for each linked provider.
  List<UserInfo> get providerData;

  /// Returns a JWT refresh token for the user.
  ///
  /// This property maybe `null` or empty if the underlying platform does not
  /// support providing refresh tokens.
  String? get refreshToken;

  /// The current user's tenant ID.
  ///
  /// This is a read-only property, which indicates the tenant ID used to sign
  /// in the current user. This is `null` if the user is signed in from the
  /// parent project.
  String? get tenantId;

  /// Returns a JSON Web Token (JWT) used to identify the user to a Firebase
  /// service.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<String> getIdToken([bool forceRefresh = false]);

  /// Returns a [IdTokenResult] containing the users JSON Web Token (JWT) and
  /// other metadata.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refreshed regardless
  /// of token expiration.
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]);

  /// Links the user account with the given credentials.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the credential already exists
  ///    among your users, or is already linked to a Firebase User. For example,
  ///    this error could be thrown if you are upgrading an anonymous user to a
  ///    Google user by linking a Google credential to it and the Google
  ///    credential used is already associated with an existing Firebase Google
  ///    user. The fields `email`, `phoneNumber`, and `credential`
  ///    ([AuthCredential]) may be provided, depending on the type of
  ///    credential. You can recover from this error by signing in with
  ///    `credential` directly via [signInWithCredential].
  /// - **email-already-in-use**:
  ///  - Thrown if the email corresponding to the credential already exists
  ///    among your users. When thrown while linking a credential to an existing
  ///    user, an `email` and `credential` ([AuthCredential]) fields are also
  ///    provided. You have to link the credential to the existing user with
  ///    that email if you wish to continue signing in with that credential. To
  ///    do so, call [fetchSignInMethodsForEmail], sign in to `email` via one of
  ///    the providers returned and then [User.linkWithCredential] the original
  ///    credential to that newly signed in user.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  /// - **invalid-email**:
  ///  - Thrown if the email used in a [EmailAuthProvider.credential] is
  ///    invalid.
  /// - **invalid-email**:
  ///  - Thrown if the password used in a [EmailAuthProvider.credential] is not
  ///    correct or when the user associated with the email does not have a
  ///    password.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  Future<UserCredential> linkWithCredential(AuthCredential credential);

  /// Sends a verification email to a user.
  ///
  /// The verification process is completed by calling [applyActionCode].
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]);

  /// Refreshes the current user, if signed in.
  Future<void> reload();

  /// Deletes and signs out the user.
  ///
  /// **Important**: this is a security-sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, ask the
  /// user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> delete();

  /// Updates the user's email address.
  ///
  /// An email will be sent to the original email address (if it was set) that
  /// allows to revoke the email address change, in order to protect them from
  /// account hijacking.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  ///   user to have recently signed in. If this requirement isn't met, ask the
  ///   user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email used is invalid.
  /// - **email-already-in-use**:
  ///  - Thrown if the email is already used by another user.
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> updateEmail(String newEmail);

  /// Updates the user's phone number.
  ///
  /// A credential can be created by verifying a phone number via [signInWithPhoneNumber].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-verification-code**:
  ///  - Thrown if the verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the verification ID of the credential is not valid.
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential);

  /// Updates the user's password.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  ///   user to have recently signed in. If this requirement isn't met, ask the
  ///   user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> updatePassword(String newPassword);

  /// Updates a user's profile data.
  Future<void> updateProfile({String? displayName, String? photoURL});

  /// Sends a verification email to a new email address. The user's email will
  /// be updated to the new one after being verified.
  ///
  /// If you have a custom email action handler, you can complete the
  /// verification process by calling [applyActionCode].
  Future<void> verifyBeforeUpdateEmail(String newEmail,
      [ActionCodeSettings? actionCodeSettings]);

  /// Re-authenticates a user using a fresh credential.
  ///
  /// Use before operations such as [User.updatePassword] that require tokens
  /// from recent sign-in attempts.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **user-mismatch**:
  ///  - Thrown if the credential given does not correspond to the user.
  /// - **user-not-found**:
  ///  - Thrown if the credential given does not correspond to any existing
  ///    user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **invalid-email**:
  ///  - Thrown if the email used in a [EmailAuthProvider.credential] is
  ///    invalid.
  /// - **wrong-password**:
  ///  - Thrown if the password used in a [EmailAuthProvider.credential] is not
  ///    correct or when the user associated with the email does not have a
  ///    password.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  Future<UserCredential> reauthenticateWithCredential(
      AuthCredential credential);

  /// Unlinks a provider from a user account.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **no-such-provider**:
  ///  - Thrown if the user does not have this provider linked or when the
  ///    provider ID given does not exist.
  Future<User> unlink(String providerId);

  @override
  String toString() {
    return '$User(displayName: $displayName, email: $email, emailVerified: $emailVerified, isAnonymous: $isAnonymous, metadata: ${metadata.toString()}, phoneNumber: $phoneNumber, photoURL: $photoURL, providerData, ${providerData.toString()}, refreshToken: $refreshToken, tenantId: $tenantId, uid: $uid)';
  }

  Map<String, dynamic> toJson();

  MultiFactor get multiFactor;
}

/// Represents user data returned from an identity provider.
class UserInfo {
  /// The federated provider ID.
  final String providerId;

  /// The user's unique ID.
  final String uid;

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  final String? displayName;

  /// Returns a photo URL for the user.
  ///
  /// This property will be populated if the user has signed in or been linked
  /// with a 3rd party OAuth provider (such as Google).
  final String? photoURL;

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  final String? email;

  /// Returns the users phone number.
  ///
  /// This property will be `null` if the user has not signed in or been has
  /// their phone number linked.
  final String? phoneNumber;

  UserInfo(
      {required this.providerId,
      required this.uid,
      this.displayName,
      this.photoURL,
      this.email,
      this.phoneNumber});

  UserInfo.fromJson(Map<String, dynamic> json)
      : this(
            providerId: json['providerId'],
            uid: json['uid'],
            displayName: json['displayName'],
            photoURL: json['photoUrl'],
            email: json['email'],
            phoneNumber: json['phoneNumber']);

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoURL,
        'email': email,
        'phoneNumber': phoneNumber,
      };

  @override
  String toString() {
    return '$UserInfo(displayName: $displayName, email: $email, phoneNumber: $phoneNumber, photoURL: $photoURL, providerId: $providerId, uid: $uid)';
  }
}

/// Interface representing a user's metadata.
class UserMetadata {
  /// When this account was created as dictated by the server clock.
  final DateTime? creationTime;

  /// When the user last signed in as dictated by the server clock.
  ///
  /// This is only accurate up to a granularity of 2 minutes for consecutive
  /// sign-in attempts.
  final DateTime? lastSignInTime;

  UserMetadata({this.creationTime, this.lastSignInTime});

  @override
  String toString() {
    return 'UserMetadata(creationTime: ${creationTime.toString()}, lastSignInTime: ${lastSignInTime.toString()})';
  }
}

/// Interface representing ID token result obtained from [getIdTokenResult].
/// It contains the ID token JWT string and other helper properties for getting
/// different data associated with the token as well as all the decoded payload
/// claims.
///
/// Note that these claims are not to be trusted as they are parsed client side.
/// Only server side verification can guarantee the integrity of the token
/// claims.
abstract class IdTokenResult {
  /// The Firebase Auth ID token JWT string.
  String? get token;

  /// The time when the ID token expires.
  DateTime? get expirationTime;

  /// The time the user authenticated (signed in).
  ///
  /// Note that this is not the time the token was refreshed.
  DateTime? get authTime;

  /// The time when ID token was issued.
  DateTime? get issuedAtTime;

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  String? get signInProvider;

  /// The type of second factor associated with this session, provided the user
  /// was multi-factor authenticated (eg. phone, etc).
  String? get signInSecondFactor;

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  Map<String, dynamic>? get claims;

  @override
  String toString() {
    return '$IdTokenResult(authTime: $authTime, claims: ${claims.toString()}, expirationTime: $expirationTime, issuedAtTime: $issuedAtTime, signInProvider: $signInProvider, token: $token)';
  }
}

/// A structure containing additional user information from a federated identity
/// provider.
abstract class AdditionalUserInfo {
  /// Whether the user account has been recently created.
  bool get isNewUser;

  /// The username given from the federated identity provider.
  String? get username;

  /// The  federated identity provider ID.
  String? get providerId;

  /// A [Map] containing additional profile information from the identity
  /// provider.
  Map<String, dynamic>? get profile;

  @override
  String toString() {
    return '$AdditionalUserInfo(isNewUser: $isNewUser, profile: ${profile.toString()}, providerId: $providerId, username: $username)';
  }
}
