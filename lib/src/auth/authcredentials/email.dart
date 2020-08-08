part of fireauth.credentials;

/// An [AuthCredential] created by an email auth provider.
class EmailAuthCredential extends AuthCredential {
  /// The user's email address.
  final String email;

  /// The user account password.
  final String password;

  /// The sign-in email link.
  final String link;

  @override
  String get providerId => 'password';

  EmailAuthCredential({@required this.email, this.password, this.link});

  factory EmailAuthCredential.fromJson(Map<String, dynamic> json) {
    if (json != null && json['email'] != null && json['password'] != null) {
      return EmailAuthCredential(
          email: json['email'], password: json['password'], link: json['link']);
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'link': link};
  }
}
