/// RegExp to detect if the email address given is valid
final emailAddressRegExp = RegExp(r'^[^@]+@[^@]+$');

/// Determines if it is a valid email address
bool isValidEmailAddress(String email) {
  return emailAddressRegExp.hasMatch(email);
}

Platform platform = Platform(isOnline: true); // TODO

class Platform {
  final bool isOnline;
  final bool isMobile;

  Platform({this.isOnline = true, this.isMobile = false});
}
