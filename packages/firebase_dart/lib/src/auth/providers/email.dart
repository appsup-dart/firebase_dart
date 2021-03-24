import '../auth_credential.dart';
import '../auth_provider.dart';

/// A [EmailAuthCredential] can be created by calling
/// [EmailAuthProvider.credential] with an email and password.
///
/// Usage of [EmailAuthProvider] would be when you wish to sign a user in with a
/// credential or reauthenticate a user.
abstract class EmailAuthProvider extends AuthProvider {
  static const String PROVIDER_ID = 'password';

  /// This corresponds to the sign-in method identifier for email-link sign-ins.
  static String get EMAIL_LINK_SIGN_IN_METHOD => 'emailLink';

  /// This corresponds to the sign-in method identifier for email-password
  /// sign-ins.
  static String get EMAIL_PASSWORD_SIGN_IN_METHOD => PROVIDER_ID;

  /// Creates a new instance.
  EmailAuthProvider() : super(PROVIDER_ID);

  static AuthCredential credential({
    required String email,
    required String password,
  }) {
    return EmailAuthCredential._(email: email, password: password);
  }

  static AuthCredential credentialWithLink({
    required String email,
    required String emailLink,
  }) {
    return EmailAuthCredential._(email: email, emailLink: emailLink);
  }
}

/// The auth credential returned from calling
/// [EmailAuthProvider.credential].
class EmailAuthCredential extends AuthCredential {
  /// The user's email address.
  final String email;

  /// The user account password.
  final String? password;

  /// The sign-in email link.
  final String? emailLink;

  EmailAuthCredential._({required this.email, this.password, this.emailLink})
      : super(
            providerId: EmailAuthProvider.PROVIDER_ID,
            signInMethod: password == null
                ? EmailAuthProvider.EMAIL_LINK_SIGN_IN_METHOD
                : EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD);

  EmailAuthCredential.fromJson(Map<String, dynamic> json)
      : this._(
            email: json['email'],
            password: json['secret'],
            emailLink: json['emailLink']);

  @override
  Map<String, String?> asMap() {
    return {
      ...super.asMap() as Map<String, String?>,
      'email': email,
      'secret': password,
      'emailLink': emailLink,
    };
  }
}
