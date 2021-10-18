import 'package:meta/meta.dart';

/// The type of operation that generated the action code from calling
/// [checkActionCode].
enum ActionCodeInfoOperation {
  /// Unknown operation.
  unknown,

  /// Password reset code generated via [sendPasswordResetEmail].
  passwordReset,

  /// Email verification code generated via [User.sendEmailVerification].
  verifyEmail,

  /// Email change revocation code generated via [User.updateEmail].
  recoverEmail,

  /// Email sign in code generated via [sendSignInLinkToEmail].
  emailSignIn,

  /// Verify and change email code generated via [User.verifyBeforeUpdateEmail].
  verifyAndChangeEmail,

  /// Action code for reverting second factor addition.
  revertSecondFactorAddition,
}

/// A response from calling [checkActionCode].
abstract class ActionCodeInfo {
  /// The type of operation that generated the action code.
  ActionCodeInfoOperation get operation;

  /// The data associated with the action code.
  ///
  /// Depending on the [ActionCodeInfoOperation], `email` and `previousEmail`
  /// may be available.
  Map<String, dynamic> get data;
}

/// Interface that defines the required continue/state URL with optional
/// Android and iOS bundle identifiers.
class ActionCodeSettings {
  @protected
  ActionCodeSettings({
    this.androidPackageName,
    this.androidMinimumVersion,
    this.androidInstallApp,
    this.dynamicLinkDomain,
    this.handleCodeInApp,
    this.iOSBundleId,
    required this.url,
  });

  /// The Android package name of the application to open when the URL is pressed.
  final String? androidPackageName;

  /// The minimum app version which must be installed on the device.
  ///
  /// This argument is only set if [androidPackageName] is also set. If the user
  /// has the application on the device but it is a lower version number than the
  /// one specified they will be taken to the Play Store to upgrade the application.
  final String? androidMinimumVersion;

  /// Whether or not the user should be automatically prompted to install the app
  /// via the Play Store if it is not already installed.
  final bool? androidInstallApp;

  /// The iOS app to open if it is installed on the device.
  final String? iOSBundleId;

  /// Sets an optional Dynamic Link domain.
  final String? dynamicLinkDomain;

  /// The default is false. When true, the action code link will be sent
  /// as a Universal Link or Android App Link and will be opened by the
  /// app if installed.
  final bool? handleCodeInApp;

  /// Sets the link continue/state URL
  final String url;

  /// Returns the current instance as a [Map].
  Map<String, dynamic> asMap() {
    return <String, dynamic>{
      'url': url,
      'dynamicLinkDomain': dynamicLinkDomain,
      'handleCodeInApp': handleCodeInApp,
      'android': <String, dynamic>{
        'installApp': androidInstallApp,
        'minimumVersion': androidMinimumVersion,
        'packageName': androidPackageName,
      },
      'iOS': <String, dynamic>{
        'bundleId': iOSBundleId,
      }
    };
  }

  @override
  String toString() {
    return 'ActionCodeSettings(${asMap()})';
  }
}
