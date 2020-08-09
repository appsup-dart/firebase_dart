import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/authcredential.dart';

/// Represents a user.
abstract class FirebaseUser implements UserInfo {
  FirebaseUser();

  /// Returns true if the user is anonymous; that is, the user account was
  /// created with signInAnonymously() and has not been linked to another
  /// account.
  bool get isAnonymous;

  /// Returns true if the user's email is verified.
  bool get isEmailVerified;

  FirebaseUserMetadata get metadata;

  List<UserInfo> get providerData;

  @override
  String get providerId => 'firebase';

  /// Obtains the id token result for the current user, forcing a [refresh] if
  /// desired.
  ///
  /// Useful when authenticating against your own backend. Use our server
  /// SDKs or follow the official documentation to securely verify the
  /// integrity and validity of this token.
  ///
  /// Completes with an error if the user is signed out.
  Future<IdTokenResult> getIdToken({bool refresh = false});

  /// Associates a user account from a third-party identity provider with this
  /// user and returns additional identity provider data.
  ///
  /// This allows the user to sign in to this account in the future with
  /// the given account.
  ///
  /// Errors:
  ///
  ///  * `ERROR_WEAK_PASSWORD` - If the password is not strong enough.
  ///  * `ERROR_INVALID_CREDENTIAL` - If the credential is malformed or has expired.
  ///  * `ERROR_EMAIL_ALREADY_IN_USE` - If the email is already in use by a different account.
  ///  * `ERROR_CREDENTIAL_ALREADY_IN_USE` - If the account is already in use by a different account, e.g. with phone auth.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_REQUIRES_RECENT_LOGIN` - If the user's last sign-in time does not meet the security threshold. Use reauthenticate methods to resolve.
  ///  * `ERROR_PROVIDER_ALREADY_LINKED` - If the current user already has an account of this type linked.
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that this type of account is not enabled.
  ///  * `ERROR_INVALID_ACTION_CODE` - If the action code in the link is malformed, expired, or has already been used.
  ///       This can only occur when using [EmailAuthProvider.getCredentialWithLink] to obtain the credential.
  Future<AuthResult> linkWithCredential(AuthCredential credential);

  /// Initiates email verification for the user.
  Future<void> sendEmailVerification();

  /// Manually refreshes the data of the current user (for example,
  /// attached providers, display name, and so on).
  Future<void> reload();

  /// Deletes the current user (also signs out the user).
  ///
  /// Errors:
  ///
  ///  * `ERROR_REQUIRES_RECENT_LOGIN` - If the user's last sign-in time does not meet the security threshold. Use reauthenticate methods to resolve.
  ///  * `ERROR_INVALID_CREDENTIAL` - If the credential is malformed or has expired.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_USER_NOT_FOUND` - If the user has been deleted (for example, in the Firebase console)
  Future<void> delete();

  /// Updates the email address of the user.
  ///
  /// The original email address recipient will receive an email that allows
  /// them to revoke the email address change, in order to protect them
  /// from account hijacking.
  ///
  /// **Important**: This is a security sensitive operation that requires
  /// the user to have recently signed in.
  ///
  /// Errors:
  ///
  ///  * `ERROR_INVALID_CREDENTIAL` - If the email address is malformed.
  ///  * `ERROR_EMAIL_ALREADY_IN_USE` - If the email is already in use by a different account.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_USER_NOT_FOUND` - If the user has been deleted (for example, in the Firebase console)
  ///  * `ERROR_REQUIRES_RECENT_LOGIN` - If the user's last sign-in time does not meet the security threshold. Use reauthenticate methods to resolve.
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Email & Password accounts are not enabled.
  Future<void> updateEmail(String email);

  /// Updates the phone number of the user.
  ///
  /// The new phone number credential corresponding to the phone number
  /// to be added to the Firebase account, if a phone number is already linked to the account.
  /// this new phone number will replace it.
  ///
  /// **Important**: This is a security sensitive operation that requires
  /// the user to have recently signed in.
  ///
  Future<void> updatePhoneNumberCredential(AuthCredential credential);

  /// Updates the password of the user.
  ///
  /// Anonymous users who update both their email and password will no
  /// longer be anonymous. They will be able to log in with these credentials.
  ///
  /// **Important**: This is a security sensitive operation that requires
  /// the user to have recently signed in.
  ///
  /// Errors:
  ///
  ///  * `ERROR_WEAK_PASSWORD` - If the password is not strong enough.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_USER_NOT_FOUND` - If the user has been deleted (for example, in the Firebase console)
  ///  * `ERROR_REQUIRES_RECENT_LOGIN` - If the user's last sign-in time does not meet the security threshold. Use reauthenticate methods to resolve.
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Email & Password accounts are not enabled.
  Future<void> updatePassword(String password);

  /// Updates the user profile information.
  ///
  /// Errors:
  ///
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_USER_NOT_FOUND` - If the user has been deleted (for example, in the Firebase console)
  Future<void> updateProfile(UserUpdateInfo userUpdateInfo);

  /// Renews the user’s authentication tokens by validating a fresh set of
  /// [credential]s supplied by the user and returns additional identity provider
  /// data.
  ///
  /// This is used to prevent or resolve `ERROR_REQUIRES_RECENT_LOGIN`
  /// response to operations that require a recent sign-in.
  ///
  /// If the user associated with the supplied credential is different from the
  /// current user, or if the validation of the supplied credentials fails; an
  /// error is returned and the current user remains signed in.
  ///
  /// Errors:
  ///
  ///  * `ERROR_INVALID_CREDENTIAL` - If the [authToken] or [authTokenSecret] is malformed or has expired.
  ///  * `ERROR_WRONG_PASSWORD` - If the password is invalid or the user does not have a password.
  ///  * `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///  * `ERROR_USER_NOT_FOUND` - If the user has been deleted (for example, in the Firebase console)
  ///  * `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Email & Password accounts are not enabled.
  Future<AuthResult> reauthenticateWithCredential(AuthCredential credential);

  /// Detaches the [provider] account from the current user.
  ///
  /// This will prevent the user from signing in to this account with those
  /// credentials.
  ///
  /// **Important**: This is a security sensitive operation that requires
  /// the user to have recently signed in.
  ///
  /// Use the `providerId` method of an auth provider for [provider].
  ///
  /// Errors:
  ///
  ///  * `ERROR_NO_SUCH_PROVIDER` - If the user does not have a Github Account linked to their account.
  ///  * `ERROR_REQUIRES_RECENT_LOGIN` - If the user's last sign-in time does not meet the security threshold. Use reauthenticate methods to resolve.
  Future<void> unlinkFromProvider(String provider);
}

/// Represents user data returned from an identity provider.
class UserInfo {
  /// The provider identifier.
  final String providerId;

  /// The provider’s user ID for the user.
  final String uid;

  /// The name of the user.
  final String displayName;

  /// The URL of the user’s profile photo.
  final String photoUrl;

  /// The user’s email address.
  final String email;

  /// The user's phone number.
  final String phoneNumber;

  UserInfo(
      {this.providerId,
      this.uid,
      this.displayName,
      this.photoUrl,
      this.email,
      this.phoneNumber});

  UserInfo.fromJson(Map<String, dynamic> json)
      : this(
            providerId: json['providerId'],
            uid: json['uid'],
            displayName: json['displayName'],
            photoUrl: json['photoUrl'],
            email: json['email'],
            phoneNumber: json['phoneNumber']);

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'uid': uid,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'email': email,
        'phoneNumber': phoneNumber,
      };
}

/// Interface representing a user's metadata.
class FirebaseUserMetadata {
  /// When this account was created as dictated by the server clock.
  final DateTime creationTime;

  /// When the user last signed in as dictated by the server clock.
  ///
  /// This is only accurate up to a granularity of 2 minutes for consecutive
  /// sign-in attempts.
  final DateTime lastSignInTime;

  FirebaseUserMetadata({this.creationTime, this.lastSignInTime});
}

/// Represents ID token result obtained from [FirebaseUser], containing the
/// ID token JWT string and other helper properties for getting different
/// data associated with the token as well as all the decoded payload claims.
///
/// Note that these claims are not to be trusted as they are parsed client side.
/// Only server side verification can guarantee the integrity of the token
/// claims.
abstract class IdTokenResult {
  /// The Firebase Auth ID token JWT string.
  String get token;

  /// The time when the ID token expires.
  DateTime get expirationTime;

  /// The time the user authenticated (signed in).
  ///
  /// Note that this is not the time the token was refreshed.
  DateTime get authTime;

  /// The time when ID token was issued.
  DateTime get issuedAtTime;

  /// The sign-in provider through which the ID token was obtained (anonymous,
  /// custom, phone, password, etc). Note, this does not map to provider IDs.
  String get signInProvider;

  /// The entire payload claims of the ID token including the standard reserved
  /// claims as well as the custom claims.
  Map<dynamic, dynamic> get claims;
}

/// Interface representing a user's additional information
abstract class AdditionalUserInfo {
  /// Returns whether the user is new or existing
  bool get isNewUser;

  /// Returns the username if the provider is GitHub or Twitter
  String get username;

  /// Returns the provider ID for specifying which provider the
  /// information in [profile] is for.
  String get providerId;

  /// Returns a Map containing IDP-specific user data if the provider
  /// is one of Facebook, GitHub, Google, Twitter, Microsoft, or Yahoo.
  Map<String, dynamic> get profile;
}

/// Represents user profile data that can be updated by [updateProfile]
///
/// The purpose of having separate class with a map is to give possibility
/// to check if value was set to null or not provided
class UserUpdateInfo {
  /// Container of data that will be send in update request
  final Map<String, String> _updateData = <String, String>{};

  set displayName(String displayName) =>
      _updateData['displayName'] = displayName;

  String get displayName => _updateData['displayName'];

  set photoUrl(String photoUri) => _updateData['photoUrl'] = photoUri;

  String get photoUrl => _updateData['photoUrl'];

  Map<String, dynamic> toJson() => {..._updateData};
}
