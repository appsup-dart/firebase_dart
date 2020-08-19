import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

class PureDartFirebase {
  static void setup({@required String storagePath}) {
    if (storagePath != null) Hive.init(storagePath);
    FirebaseImplementation.install(PureDartFirebaseImplementation());
  }
}
