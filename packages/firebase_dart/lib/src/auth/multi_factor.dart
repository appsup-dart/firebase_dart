import '../../auth.dart';

/// Defines multi-factor related properties and operations pertaining to a [User].
/// This class acts as the main entry point for enrolling or un-enrolling
/// second factors for a user, and provides access to their currently enrolled factors.
abstract class MultiFactor {
  /// Returns a session identifier for a second factor enrollment operation.
  Future<MultiFactorSession> getSession();

  /// Enrolls a second factor as identified by the [MultiFactorAssertion] parameter for the current user.
  ///
  /// [displayName] can be used to provide a display name for the second factor.
  Future<void> enroll(
    MultiFactorAssertion assertion, {
    String? displayName,
  });

  /// Unenrolls a second factor from this user.
  ///
  /// [factorUid] is the unique identifier of the second factor to unenroll.
  /// [multiFactorInfo] is the [MultiFactorInfo] of the second factor to unenroll.
  /// Only one of [factorUid] or [multiFactorInfo] should be provided.
  Future<void> unenroll({String? factorUid, MultiFactorInfo? multiFactorInfo});

  /// Returns a list of the [MultiFactorInfo] already associated with this user.
  Future<List<MultiFactorInfo>> getEnrolledFactors();

  /// Returns a list of the [MultiFactorInfo] already associated with this user.
  List<MultiFactorInfo> get enrolledFactors;
}

/// Provider for generating a PhoneMultiFactorAssertion.
class PhoneMultiFactorGenerator {
  /// Transforms a PhoneAuthCredential into a MultiFactorAssertion which can be
  /// used to confirm ownership of a phone second factor.
  static MultiFactorAssertion getAssertion(PhoneAuthCredential credential) {
    return PhoneMultiFactorAssertion(credential);
  }
}

class PhoneMultiFactorAssertion extends MultiFactorAssertion {
  final PhoneAuthCredential credential;

  PhoneMultiFactorAssertion(this.credential);
}

/// Represents an assertion that the Firebase Authentication server
/// can use to authenticate a user as part of a multi-factor flow.
class MultiFactorAssertion {}

/// Utility class that contains methods to resolve second factor
/// requirements on users that have opted into two-factor authentication.
abstract class MultiFactorResolver {
  /// List of [MultiFactorInfo] which represents the available
  /// second factors that can be used to complete the sign-in for the current session.
  List<MultiFactorInfo> get hints;

  /// A MultiFactorSession, an opaque session identifier for the current sign-in flow.
  MultiFactorSession get session;

  /// Completes sign in with a second factor using an MultiFactorAssertion which
  /// confirms that the user has successfully completed the second factor challenge.
  Future<UserCredential> resolveSignIn(MultiFactorAssertion assertion);
}

/// MultiFactor exception related to Firebase Authentication. Check the error code
/// and message for more details.
class FirebaseAuthMultiFactorException extends FirebaseAuthException {
  final MultiFactorResolver resolver;

  FirebaseAuthMultiFactorException(this.resolver) : super.mfaRequired();
}

/// Identifies the current session to enroll a second factor or to complete sign in when previously enrolled.
///
/// It contains additional context on the existing user, notably the confirmation that the user passed the first factor challenge.
class MultiFactorSession {}

/// Represents a single second factor means for the user.
///
/// See direct subclasses for type-specific information.
abstract class MultiFactorInfo {
  const MultiFactorInfo({
    required this.factorId,
    required this.enrollmentTimestamp,
    required this.displayName,
    required this.uid,
  });

  factory MultiFactorInfo.fromJson(Map<String, dynamic> obj) {
    switch (obj['factorId']) {
      case 'phone':
        return PhoneMultiFactorInfo.fromJson(obj);
      default:
        throw UnimplementedError();
    }
  }

  /// User-given display name for this second factor.
  final String? displayName;

  /// The enrollment timestamp for this second factor in seconds since epoch (UTC midnight on January 1, 1970).
  final double enrollmentTimestamp;

  /// The factor id of this second factor.
  final String factorId;

  /// The unique identifier for this second factor.
  final String uid;

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'enrollmentTimestamp': enrollmentTimestamp,
        'factorId': factorId,
        'uid': uid,
      };
}

/// Represents the information for a phone second factor.
class PhoneMultiFactorInfo extends MultiFactorInfo {
  const PhoneMultiFactorInfo({
    required String? displayName,
    required double enrollmentTimestamp,
    required String uid,
    required this.phoneNumber,
  }) : super(
          displayName: displayName,
          enrollmentTimestamp: enrollmentTimestamp,
          factorId: 'phone',
          uid: uid,
        );

  PhoneMultiFactorInfo.fromJson(Map<String, dynamic> obj)
      : this(
            enrollmentTimestamp: obj['enrollmentTimestamp'],
            displayName: obj['displayName'],
            uid: obj['uid'],
            phoneNumber: obj['phoneNumber']);

  /// The phone number associated with this second factor verification method.
  final String phoneNumber;

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'phoneNumber': phoneNumber,
      };
}
