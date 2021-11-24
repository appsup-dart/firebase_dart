import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

import 'package:test/test.dart';

void main() {
  group('TreeStructuredData', () {
    test('TreeStructuredData.toJson', () {
      var v = {
        '.priority': '1',
        'hello': 'world',
        'object': {'.priority': 2, 'test': 1},
        'number': {'.priority': 3, '.value': 1}
      };

      expect(TreeStructuredData.fromJson(v).toJson(true), v);
      expect(TreeStructuredData.fromExportJson(v).toJson(true), v);

      var w = {
        'hello': 'world',
        'object': {'test': 1},
        'number': 1
      };
      expect(TreeStructuredData.fromJson(v).toJson(), w);
      expect(TreeStructuredData.fromExportJson(v).toJson(), w);
    });
    test('performance testing', () {
      var v = {
        for (var i = 0; i < 100; i++)
          randomString(): {
            randomString(): {
              for (var i = 0; i < 1000; i++)
                randomString(): {randomString(): randomString()}
            }
          }
      };

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
