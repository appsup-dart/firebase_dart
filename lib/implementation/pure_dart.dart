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
      void Function(String errorMessage, StackTrace stackTrace) onError,
      Function(Uri url) launchUrl}) {
    if (isolated) {
      FirebaseImplementation.install(IsolateFirebaseImplementation(storagePath,
          onError: onError, platform: platform));
    } else {
      if (storagePath != null) Hive.init(storagePath);
      initPlatform(platform);
      FirebaseImplementation.install(
          PureDartFirebaseImplementation(launchUrl: launchUrl));
    }
  }
}
