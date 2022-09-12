part of 'user.dart';

class MultiFactorImpl extends MultiFactor {
  final FirebaseUserImpl user;

  MultiFactorImpl(this.user);

  @override
  Future<void> enroll(MultiFactorAssertion assertion,
      {String? displayName}) async {
    var session = await getSession();

    var phoneCredential = (assertion as PhoneMultiFactorAssertion).credential;
    var r = await user._rpcHandler.finalizeMultiFactorEnrollment(
        idToken: session.credential,
        code: phoneCredential.smsCode,
        phoneNumber: phoneCredential.phoneNumber,
        sessionInfo: phoneCredential.verificationId,
        displayName: displayName);

    await user._updateCredential(r.credential);
  }

  @override
  Future<List<MultiFactorInfo>> getEnrolledFactors() async => enrolledFactors;

  @override
  Future<MultiFactorSessionImpl> getSession() async {
    return MultiFactorSessionImpl.fromIdtoken(await user.getIdToken());
  }

  @override
  Future<void> unenroll(
      {String? factorUid, MultiFactorInfo? multiFactorInfo}) async {
    var r = await user._rpcHandler.withdrawMultiFactorEnrollment(
        idToken: await user.getIdToken(),
        mfaEnrollmentId: multiFactorInfo?.uid ?? factorUid!);

    await user._updateCredential(r.credential);
  }

  @override
  List<MultiFactorInfo> get enrolledFactors => [...user._enrolledFactors];
}

enum MultiFactorSessionType {
  /// The session is for a second factor enrollment operation.
  enrollment,

  /// The session is for a second factor sign in operation.
  signIn,
}

class MultiFactorSessionImpl extends MultiFactorSession {
  final MultiFactorSessionType type;

  final String credential;

  MultiFactorSessionImpl(this.type, this.credential);

  MultiFactorSessionImpl.fromIdtoken(String idToken)
      : this(MultiFactorSessionType.enrollment, idToken);

  factory MultiFactorSessionImpl.fromJson(Map<String, dynamic> obj) {
    var v = obj['multiFactorSession'] as Map;
    if (v.containsKey('pendingCredential')) {
      return MultiFactorSessionImpl.fromMfaPendingCredential(
          v['pendingCredential']);
    } else {
      return MultiFactorSessionImpl.fromIdtoken(v['idToken']);
    }
  }

  MultiFactorSessionImpl.fromMfaPendingCredential(String mfaPendingCredential)
      : this(MultiFactorSessionType.signIn, mfaPendingCredential);

  Map<String, dynamic> toJson() {
    var key = type == MultiFactorSessionType.enrollment
        ? 'idToken'
        : 'pendingCredential';
    return {
      'multiFactorSession': {key: credential}
    };
  }
}

class MultiFactorResolverImpl extends MultiFactorResolver {
  final FirebaseAuthImpl firebaseAuth;

  @override
  final List<MultiFactorInfo> hints;

  @override
  final MultiFactorSession session;

  MultiFactorResolverImpl(this.firebaseAuth,
      {required String mfaPendingCredential, required this.hints})
      : session = MultiFactorSessionImpl.fromMfaPendingCredential(
            mfaPendingCredential);

  @override
  Future<UserCredential> resolveSignIn(MultiFactorAssertion assertion) async {
    return firebaseAuth.signInWithMultiFactorAssertion(assertion, session);
  }
}
