import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class PureDartFirebase {
  static void setup(
      {@required String storagePath,
      bool isolated = false,
      void Function(String errorMessage, StackTrace stackTrace) onError}) {
    if (isolated) {
      FirebaseImplementation.install(
          IsolateFirebaseImplementation(storagePath, onError: onError));
    } else {
      if (storagePath != null) Hive.init(storagePath);
      FirebaseImplementation.install(PureDartFirebaseImplementation());
    }
  }
}
