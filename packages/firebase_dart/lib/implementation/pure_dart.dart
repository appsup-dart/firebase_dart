import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

export 'package:firebase_dart/src/auth/utils.dart' show Platform;

class PureDartFirebase {
  static void setup(
      {@required String storagePath,
      @required Platform platform,
      bool isolated = false,
      Function(Uri url) launchUrl,
      Future<Map<String, dynamic>> Function() getAuthResult,
      Future<OAuthCredential> Function(OAuthProvider provider) oauthSignIn,
      Future<void> Function(String providerId) oauthSignOut}) {
    if (isolated) {
      FirebaseImplementation.install(IsolateFirebaseImplementation(storagePath,
          platform: platform,
          launchUrl: launchUrl,
          getAuthResult: getAuthResult,
          oauthSignIn: oauthSignIn,
          oauthSignOut: oauthSignOut));
    } else {
      if (storagePath != null) Hive.init(storagePath);
      initPlatform(platform);
      FirebaseImplementation.install(PureDartFirebaseImplementation(
          launchUrl: launchUrl,
          getAuthResult: getAuthResult,
          oauthSignIn: oauthSignIn,
          oauthSignOut: oauthSignOut));
    }
  }
}
