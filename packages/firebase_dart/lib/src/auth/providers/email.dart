import '../auth_credential.dart';
import '../auth_provider.dart';

/// A [EmailAuthCredential] can be created by calling
/// [EmailAuthProvider.credential] with an email and password.
///
/// Usage of [EmailAuthProvider] would be when you wish to sign a user in with a
/// credential or reauthenticate a user.
abstract class EmailAuthProvider extends AuthProvider {
  static const String id = 'password';

  /// This corresponds to the sign-in method identifier for email-link sign-ins.
  static const String emailLinkSignInMethod = 'emailLink';

  /// This corresponds to the sign-in method identifier for email-password
  /// sign-ins.
  static const String emailPasswordSignInMethod = id;

  @Deprecated('Replaced by lower camel case identifier `id`')
  // ignore: constant_identifier_names
  static const String PROVIDER_ID = id;

  @Deprecated('Replaced by lower camel case identifier `emailLinkSignInMethod`')
  // ignore: constant_identifier_names
  static const EMAIL_LINK_SIGN_IN_METHOD = emailLinkSignInMethod;

  @Deprecated(
      'Replaced by lower camel case identifier `emailPasswordSignInMethod`')
  // ignore: constant_identifier_names
  static const EMAIL_PASSWORD_SIGN_IN_METHOD = emailPasswordSignInMethod;

  /// Creates a new instance.
  EmailAuthProvider() : super(id);

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
            providerId: EmailAuthProvider.id,
            signInMethod: password == null
                ? EmailAuthProvider.emailLinkSignInMethod
                : EmailAuthProvider.emailPasswordSignInMethod);

  EmailAuthCredential.fromJson(Map<String, dynamic> json)
      : this._(
            email: json['email'],
            password: json['secret'],
            emailLink: json['emailLink']);

  @override
  Map<String, String?> asMap() {
    return {
      ...super.asMap().cast<String, String?>(),
      'email': email,
      'secret': password,
      'emailLink': emailLink,
    };
  }
}
