/// RegExp to detect if the email address given is valid
final emailAddressRegExp = RegExp(r'^[^@]+@[^@]+$');

/// Determines if it is a valid email address
bool isValidEmailAddress(String email) {
  return emailAddressRegExp.hasMatch(email);
}

/// The current URL. */
String getCurrentUrl() {
  return platform.currentUrl;
}

/// Whether the current environment is http or https.
bool isHttpOrHttps() {
  return getCurrentScheme() == 'http' || getCurrentScheme() == 'https';
}

/// The current URL scheme.
String getCurrentScheme() {
  return Uri.parse(getCurrentUrl()).scheme;
}

Platform platform =
    Platform(currentUrl: 'http://localhost', isOnline: true); // TODO

class Platform {
  final String currentUrl;
  final bool isOnline;
  final bool isMobile;

  Platform({this.currentUrl, this.isOnline = true, this.isMobile = false});
}
