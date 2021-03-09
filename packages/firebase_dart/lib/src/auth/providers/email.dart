// @dart=2.9

import 'package:meta/meta.dart';

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
    @required String email,
    @required String password,
  }) {
    assert(email != null);
    assert(password != null);
    return EmailAuthCredential._(email: email, password: password);
  }

  static AuthCredential credentialWithLink({
    @required String email,
    @required String emailLink,
  }) {
    assert(email != null);
    assert(emailLink != null);
    return EmailAuthCredential._(email: email, emailLink: emailLink);
  }
}

/// The auth credential returned from calling
/// [EmailAuthProvider.credential].
class EmailAuthCredential extends AuthCredential {
  /// The user's email address.
  final String email;

  /// The user account password.
  final String password;

  /// The sign-in email link.
  final String emailLink;

  @override
  String get providerId => 'password';

  @override
  String get signInMethod => password == null
      ? EmailAuthProvider.EMAIL_LINK_SIGN_IN_METHOD
      : EmailAuthProvider.EMAIL_PASSWORD_SIGN_IN_METHOD;

  EmailAuthCredential._({@required this.email, this.password, this.emailLink});

  factory EmailAuthCredential.fromJson(Map<String, dynamic> json) {
    if (json != null &&
        json['email'] != null &&
        (json['secret'] != null || json['emailLink'] != null)) {
      return EmailAuthCredential._(
          email: json['email'],
          password: json['secret'],
          emailLink: json['emailLink']);
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'email': email,
      'secret': password,
      'emailLink': emailLink,
    };
  }
}
