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

      var x = {
        'hello': 'world',
        'object': ['test', 'test2'],
      };
      expect(TreeStructuredData.fromJson(x).toJson(), x);
      expect(TreeStructuredData.fromExportJson(x).toJson(), x);

      var z = {
        'hello': 'world',
        'object': [null, 'test', null, 'test2'],
      };
      expect(TreeStructuredData.fromJson(z).toJson(), z);
      expect(TreeStructuredData.fromExportJson(z).toJson(), z);

      var y = {
        'hello': 'world',
        'object': {'1': 'test', '3': 'test2'},
      };
      expect(TreeStructuredData.fromExportJson(y).toJson(), z);

      var z2 = {
        'hello': 'world',
        'object': [null, 'test', null, null, 'test2'],
      };
      var y2 = {
        'hello': 'world',
        'object': {'1': 'test', '4': 'test2'},
      };
      expect(TreeStructuredData.fromJson(z2).toJson(), y2);
      expect(TreeStructuredData.fromExportJson(y2).toJson(), y2);
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
