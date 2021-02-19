import 'package:meta/meta.dart';

/// RegExp to detect if the email address given is valid
final emailAddressRegExp = RegExp(r'^[^@]+@[^@]+$');

/// Determines if it is a valid email address
bool isValidEmailAddress(String email) {
  return emailAddressRegExp.hasMatch(email);
}

void initPlatform(Platform platform) {
  assert(platform != null);
  Platform._current = platform;
}

abstract class Platform {
  final bool isOnline;
  final bool isMobile;

  Platform({@required this.isMobile, this.isOnline = true})
      : assert(isMobile != null),
        assert(isOnline != null);

  factory Platform.web(
      {@required String currentUrl,
      @required bool isMobile,
      @required bool isOnline}) = WebPlatform;

  factory Platform.android(
      {@required String packageId,
      @required String sha1Cert,
      @required bool isOnline}) = AndroidPlatform;

  factory Platform.ios(
      {@required String appId,
      String clientId,
      @required bool isOnline}) = IOsPlatform;

  factory Platform.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'web':
        return Platform.web(
            currentUrl: json['currentUrl'], isMobile: json['isMobile']);
      case 'android':
        return Platform.android(
            packageId: json['packageId'], sha1Cert: json['sha1Cert']);
      case 'ios':
        return Platform.ios(appId: json['appId'], clientId: json['clientId']);
    }
    throw ArgumentError('Unknown platform ${json['type']}');
  }

  static Platform _current;
  static Platform get current => _current;

  Map<String, dynamic> toJson();
}

class WebPlatform extends Platform {
  final String currentUrl;

  WebPlatform(
      {@required this.currentUrl,
      @required bool isMobile,
      bool isOnline = true})
      : assert(currentUrl != null),
        assert(isMobile != null),
        super(isMobile: isMobile, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'web',
        'currentUrl': currentUrl,
        'isMobile': isMobile,
      };
}

class AndroidPlatform extends Platform {
  final String packageId;

  final String sha1Cert;

  AndroidPlatform(
      {@required this.packageId,
      @required this.sha1Cert,
      @required bool isOnline})
      : assert(packageId != null),
        assert(sha1Cert != null),
        super(isMobile: true, isOnline: isOnline);

  @override
  bool get isMobile => true;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'android',
        'packageId': packageId,
        'sha1Cert': sha1Cert,
      };
}

class IOsPlatform extends Platform {
  final String appId;

  final String clientId;

  IOsPlatform({@required this.appId, this.clientId, @required bool isOnline})
      : assert(appId != null),
        super(isMobile: true, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ios',
        'clientId': clientId,
        'appId': appId,
      };
}
