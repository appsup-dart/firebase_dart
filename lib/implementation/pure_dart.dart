import 'dart:io';

import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:hive/hive.dart';

class PureDartFirebase {
  static void setup() {
    Hive.init(Directory.systemTemp.path);
    FirebaseImplementation.install(PureDartFirebaseImplementation());
  }
}
