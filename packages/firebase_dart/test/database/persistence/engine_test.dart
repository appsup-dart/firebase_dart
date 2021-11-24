import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  group('HivePersistenceStorageEngine', () {
    test('performance test', () async {
      var box = await Hive.openBox('test', bytes: Uint8List(0));

      for (var i = 0; i < 1000; i++) {
        await box.put('C:some/path/${randomString()}',
            {for (var i = 0; i < 1000; i++) randomString(): randomString()});
      }

      var s = Stopwatch()..start();
      HivePersistenceStorageEngine(KeyValueDatabase(box));
      print('Load server cache: ${s.elapsed}');
    });
  });
}

final random = Random();
String randomString() {
  return Iterable.generate(
      24,
      (i) => PushIdGenerator
          .pushChars[random.nextInt(PushIdGenerator.pushChars.length)]).join();
}
