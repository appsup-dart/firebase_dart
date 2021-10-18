import 'dart:typed_data';

import 'package:hive/hive.dart';

class PersistenceStorage {
  static bool _memoryStorage = false;
  static Future<Box> openBox(String name) async {
    try {
      return await Hive.openBox(name,
          bytes: _memoryStorage ? Uint8List(0) : null);
    } on HiveError {
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox(name,
          bytes: _memoryStorage ? Uint8List(0) : null);
    }
  }

  static void setupMemoryStorage() {
    _memoryStorage = true;
  }
}
