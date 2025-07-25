import 'dart:typed_data';

import 'package:hive/hive.dart';

class PersistenceStorage {
  static bool _memoryStorage = false;

  static final _openBoxes = <String, Box>{};

  static Future<Box> openBox(String name) async {
    final openBox = _openBoxes[name];

    if (openBox != null) return openBox;

    Future<Box> getBox() async {
      final box = await Hive.openBox(
        name,
        bytes: _memoryStorage ? Uint8List(0) : null,
      );

      await box.compact();

      return _openBoxes[name] = box;
    }

    try {
      return await getBox();
    } on HiveError {
      await Hive.deleteBoxFromDisk(name);

      return await getBox();
    }
  }

  static void setupMemoryStorage() {
    _memoryStorage = true;
  }
}
