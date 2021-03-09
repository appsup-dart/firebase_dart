/// RegExp to detect if the email address given is valid
final emailAddressRegExp = RegExp(r'^[^@]+@[^@]+$');

/// Determines if it is a valid email address
bool isValidEmailAddress(String email) {
  return emailAddressRegExp.hasMatch(email);
}

void initPlatform(Platform platform) {
  Platform._current = platform;
}

abstract class Platform {
  final bool isOnline;
  final bool isMobile;

  Platform({required this.isMobile, this.isOnline = true});

  factory Platform.web(
      {required String currentUrl,
      required bool isMobile,
      required bool isOnline}) = WebPlatform;

  factory Platform.android(
      {required String packageId,
      required String sha1Cert,
      required bool isOnline}) = AndroidPlatform;

  factory Platform.ios({required String appId, required bool isOnline}) =
      IOsPlatform;

  factory Platform.macos({required String appId, required bool isOnline}) =
      MacOsPlatform;

  factory Platform.linux({required bool isOnline}) = LinuxPlatform;

  factory Platform.windows({required bool isOnline}) = WindowsPlatform;

  factory Platform.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'web':
        return Platform.web(
          currentUrl: json['currentUrl'],
          isMobile: json['isMobile'],
          isOnline: json['isOnline'],
        );
      case 'android':
        return Platform.android(
          packageId: json['packageId'],
          sha1Cert: json['sha1Cert'],
          isOnline: json['isOnline'],
        );
      case 'ios':
        return Platform.ios(
          appId: json['appId'],
          isOnline: json['isOnline'],
        );
      case 'macos':
        return Platform.macos(
          appId: json['appId'],
          isOnline: json['isOnline'],
        );
      case 'linux':
        return Platform.linux(
          isOnline: json['isOnline'],
        );
      case 'windows':
        return Platform.windows(
          isOnline: json['isOnline'],
        );
    }
    throw ArgumentError('Unknown platform ${json['type']}');
  }

  static Platform? _current;
  static Platform get current {
    var c = _current;
    if (c == null) throw StateError('No platform initialized.');
    return c;
  }

  Map<String, dynamic> toJson();
}

class WebPlatform extends Platform {
  final String currentUrl;

  WebPlatform(
      {required this.currentUrl, required bool isMobile, bool isOnline = true})
      : super(isMobile: isMobile, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'web',
        'currentUrl': currentUrl,
        'isMobile': isMobile,
        'isOnline': isOnline,
      };
}

class AndroidPlatform extends Platform {
  final String packageId;

  final String sha1Cert;

  AndroidPlatform(
      {required this.packageId, required this.sha1Cert, required bool isOnline})
      : super(isMobile: true, isOnline: isOnline);

  @override
  bool get isMobile => true;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'android',
        'packageId': packageId,
        'sha1Cert': sha1Cert,
        'isOnline': isOnline,
      };
}

class IOsPlatform extends Platform {
  final String appId;

  IOsPlatform({required this.appId, required bool isOnline})
      : super(isMobile: true, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ios',
        'appId': appId,
        'isOnline': isOnline,
      };
}

class MacOsPlatform extends Platform {
  final String appId;

  MacOsPlatform({required this.appId, required bool isOnline})
      : super(isMobile: false, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'macos',
        'appId': appId,
        'isOnline': isOnline,
      };
}

class LinuxPlatform extends Platform {
  LinuxPlatform({required bool isOnline})
      : super(isMobile: false, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'linux',
        'isOnline': isOnline,
      };
}

class WindowsPlatform extends Platform {
  WindowsPlatform({required bool isOnline})
      : super(isMobile: false, isOnline: isOnline);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'windows',
        'isOnline': isOnline,
      };
}
