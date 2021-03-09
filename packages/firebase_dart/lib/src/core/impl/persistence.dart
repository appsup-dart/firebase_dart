// @dart=2.9

import 'dart:typed_data';

import 'package:hive/hive.dart';

class PersistenceStorage {
  static bool _memoryStorage = false;
  static Future<Box> openBox(String name) {
    return Hive.openBox(name, bytes: _memoryStorage ? Uint8List(0) : null);
  }

  static void setupMemoryStorage() {
    _memoryStorage = true;
  }
}
