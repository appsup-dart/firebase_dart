import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

import 'package:test/test.dart';

void main() {
  group('TreeStructuredData', () {
    test('addIndex stores an extra ordering on a default-filter node', () {
      final node = TreeStructuredData.fromJson({'a': 1, 'b': 2});
      expect(node, isNot(isA<IndexedTreeStructuredData>()));
      expect(
        TreeStructuredData.fromJson(1),
        isNot(isA<IndexedTreeStructuredData>()),
      );
      expect(
        TreeStructuredData.fromExportJson({'a': 1}),
        isNot(isA<IndexedTreeStructuredData>()),
      );
      expect(
        TreeStructuredData(
          filter: const QueryFilter(limit: 1, reversed: true),
        ),
        isNot(isA<IndexedTreeStructuredData>()),
      );

      final indexed = IndexedTreeStructuredData.from(node);
      expect(indexed.indexedOrderings, {
        const TreeStructuredDataOrdering.byPriority(),
      });
      indexed.addIndex(const TreeStructuredDataOrdering.byPriority());
      expect(indexed.indexedOrderings, {
        const TreeStructuredDataOrdering.byPriority(),
      });
      final ordering = TreeStructuredDataOrdering.byChild('field');
      indexed.addIndex(ordering);
      indexed.addIndex(ordering);
      expect(indexed.indexedOrderings, {
        const TreeStructuredDataOrdering.byPriority(),
        ordering,
      });

      final page = indexed.withFilter(
        const QueryFilter(limit: 1, reversed: true),
      );
      expect(page, isNot(isA<IndexedTreeStructuredData>()));
    });

    test('indexed withFilter matches an unindexed filter', () {
      final json = {
        for (var i = 0; i < 30; i++)
          'key-${i.toString().padLeft(2, '0')}': {
            'field': i.isEven ? 'value-$i' : null,
          },
      };
      final unindexed = TreeStructuredData.fromJson(json);
      final indexed = IndexedTreeStructuredData.from(unindexed);
      final ordering = TreeStructuredDataOrdering.byChild('field');
      final filter = QueryFilter(
        ordering: ordering,
        limit: 5,
        reversed: true,
      );
      final bounded = filter.copyWith(
        startAtKey: Name('key-10'),
        startAtValue: TreeStructuredData.fromJson({'field': 'value-10'}),
      );
      indexed.addIndex(ordering);

      expect(indexed.withFilter(filter), unindexed.withFilter(filter));
      expect(indexed.withFilter(bounded), unindexed.withFilter(bounded));
      expect(
        indexed.withFilter(QueryFilter(ordering: ordering)),
        unindexed.withFilter(QueryFilter(ordering: ordering)),
      );

      const changedKey = 'key-29';
      final changedChild = TreeStructuredData.fromJson({'field': 'zzz'});
      final updated = indexed.withChild(Name(changedKey), changedChild);
      final expected = unindexed.withChild(Name(changedKey), changedChild);
      expect(updated.withFilter(filter), expected.withFilter(filter));
      expect(updated.indexedOrderings, contains(ordering));

      final removed = updated.withoutChild(Name('key-00'));
      expect(
        removed.withFilter(filter),
        expected.withoutChild(Name('key-00')).withFilter(filter),
      );

      final prioritized = updated.withPriority(Value.string('p'));
      expect(
        prioritized.withFilter(filter),
        expected.withPriority(Value.string('p')).withFilter(filter),
      );
      expect(prioritized.indexedOrderings, contains(ordering));
    });

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
