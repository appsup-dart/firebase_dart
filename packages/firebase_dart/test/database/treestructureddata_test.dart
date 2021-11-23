import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

import 'package:test/test.dart';

void main() {
  var v = {
    for (var i = 0; i < 100; i++)
      randomString(): {
        randomString(): {
          for (var i = 0; i < 1000; i++)
            randomString(): {randomString(): randomString()}
        }
      }
  };

  group('TreeStructuredData', () {
    test('performance testing', () {
      var s = Stopwatch()..start();

      var value = TreeStructuredData.fromExportJson(v);
      print('TreeStructuredData.fromExportJson: ${s.elapsed}');

      s.reset();
      json.encode(value);
      print('TreeStructuredDataFromExportJson.toJson: ${s.elapsed}');

      s.reset();
      value = TreeStructuredData.fromJson(v);
      print('TreeStructuredData.fromJson: ${s.elapsed}');

      s.reset();
      json.encode(value);
      print('TreeStructuredDataImpl.toJson: ${s.elapsed}');
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
