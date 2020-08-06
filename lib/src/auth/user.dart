/// Represents a user.
abstract class FirebaseUser implements UserInfo {
  FirebaseUser();

  /// Returns true if the user is anonymous; that is, the user account was
  /// created with signInAnonymously() and has not been linked to another
  /// account.
  bool get isAnonymous;

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

  /// Manually refreshes the data of the current user (for example,
  /// attached providers, display name, and so on).
  Future<void> reload();
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
