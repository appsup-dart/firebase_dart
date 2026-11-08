import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('WriteTree identity', () {
    var leaf = TreeStructuredData.leaf(Value.string('hello'));
    var parent = TreeStructuredData.nonLeaf({
      Name('a'): TreeStructuredData.leaf(Value.string('a')),
    });

    test('addOverwrite records complete nil at root on empty tree', () {
      var tree = WriteTree(null);
      var result = tree.addOverwrite(Path(), TreeStructuredData());
      expect(identical(result, tree), isFalse);
      expect(result.value!.isNil, isTrue);
    });

    test('addOverwrite on complete root with same value is a no-op', () {
      var tree = WriteTree(leaf);
      expect(identical(tree.addOverwrite(Path(), leaf), tree), isTrue);
    });

    test('addOverwrite on complete root with new value returns new tree', () {
      var tree = WriteTree(leaf);
      var other = TreeStructuredData.leaf(Value.string('world'));
      var result = tree.addOverwrite(Path(), other);
      expect(identical(result, tree), isFalse);
      expect(result.value, other);
    });

    test('addOverwrite on child path with same instance is a no-op', () {
      var tree = WriteTree(parent);
      var childA = parent.children[Name('a')]!;
      var result = tree.addOverwrite(Path.from([Name('a')]), childA);
      expect(identical(result, tree), isTrue);
    });

    test('addPriority with unchanged priority is a no-op', () {
      var withPrio =
          TreeStructuredData.leaf(Value.string('x'), Value.string('1'));
      var tree = WriteTree(withPrio);
      var result = tree.addPriority(Path(), withPrio.priority);
      expect(identical(result, tree), isTrue);
    });

    test('withFilter returns same tree when filter does not change value', () {
      var tree = WriteTree(leaf);
      expect(identical(tree.withFilter(const QueryFilter()), tree), isTrue);
    });

    test('withFilter returns new tree when filter changes value', () {
      var tree = WriteTree(parent);
      var result = tree.withFilter(const QueryFilter(limit: 1, reversed: true));
      expect(identical(result, tree), isFalse);
      expect(result.value, isNotNull);
    });

    test('withFilter on tree without value is a no-op', () {
      var tree = WriteTree(null);
      expect(identical(tree.withFilter(const QueryFilter()), tree), isTrue);
    });

    test('removeWrite returns this on empty tree', () {
      var tree = WriteTree(null);
      expect(identical(tree.removeWrite(Path()), tree), isTrue);
    });

    test('removeWrite returns this when path has no write', () {
      var tree = WriteTree(null).addOverwrite(Name.parsePath('child-1'), leaf);
      final result = tree.removeWrite(Name.parsePath('child-2'));
      expect(identical(result, tree), isTrue);
    });

    test('removeWrite returns new tree when root write is cleared', () {
      var tree = WriteTree(leaf);
      final result = tree.removeWrite(Path());
      expect(identical(result, tree), isFalse);
      expect(result.isNil, isTrue);
    });

    test('removeWrite returns new tree when child write is cleared', () {
      var tree = WriteTree(null).addOverwrite(Name.parsePath('child-1'), leaf);
      final result = tree.removeWrite(Name.parsePath('child-1'));
      expect(identical(result, tree), isFalse);
      expect(result.children[Name('child-1')]!.isNil, isTrue);
    });
  });

  group('WriteTree index', () {
    final ordering = TreeStructuredDataOrdering.byChild('field');

    WriteTree treeWith(Map<String, String> fields) {
      var tree = WriteTree(null);
      for (final entry in fields.entries) {
        tree = tree.addOverwrite(
          Path.from([Name(entry.key)]),
          TreeStructuredData.fromJson({'field': entry.value}),
        );
      }
      return tree;
    }

    test('addIndex stores complete child values in query order', () {
      final tree = treeWith({'a': 'm', 'b': 'a', 'c': 'z'})..addIndex(ordering);

      expect(tree.sortedValues(ordering)!.keys.map((key) => key.asString()),
          ['b', 'a', 'c']);
    });

    test('addIndex stores a composed incomplete child', () {
      var tree = treeWith({'a': 'm'});
      tree = tree.addOverwrite(
        Path.from([Name('partial'), Name('field')]),
        TreeStructuredData.fromJson('m'),
      )..addIndex(ordering);

      expect(tree.sortedValues(ordering)!.keys.map((key) => key.asString()),
          ['a', 'partial']);
      expect(tree.sortedValues(ordering)![Name('partial')],
          TreeStructuredData.fromJson({'field': 'm'}));

      final updated = tree.addOverwrite(
        Path.from([Name('partial'), Name('field')]),
        TreeStructuredData.fromJson('z'),
      );
      expect(updated.sortedValues(ordering)!.keys.map((key) => key.asString()),
          ['a', 'partial']);
      expect(updated.sortedValues(ordering)![Name('partial')],
          TreeStructuredData.fromJson({'field': 'z'}));
    });

    test('a copied tree keeps the index and a child update changes it', () {
      final tree = treeWith({'a': 'm', 'b': 'a'})..addIndex(ordering);
      final updated = tree.addOverwrite(
        Path.from([Name('a')]),
        TreeStructuredData.fromJson({'field': 'zzz'}),
      );

      expect(tree.sortedValues(ordering)![Name('a')]!.children[Name('field')],
          TreeStructuredData.fromJson('m'));
      expect(updated.sortedValues(ordering)!.keys.map((key) => key.asString()),
          ['b', 'a']);
      expect(
          updated.sortedValues(ordering)![Name('a')]!.children[Name('field')],
          TreeStructuredData.fromJson('zzz'));
    });

    test('an indexed withFilter matches the unindexed value', () {
      IncompleteData build() => IncompleteData.fromLeafs({
            for (final entry in {'a': 'm', 'b': 'a', 'c': 'z'}.entries)
              Path.from([Name(entry.key)]):
                  TreeStructuredData.fromJson({'field': entry.value}),
            Path.from([Name('partial'), Name('field')]):
                TreeStructuredData.fromJson('y'),
          });
      var indexed = build();
      var plain = build();
      final filter = QueryFilter(ordering: ordering, limit: 2, reversed: true);
      indexed.writeTree.addIndex(ordering);
      expect(indexed.withFilter(filter).value, plain.withFilter(filter).value);

      final operation = TreeOperation.overwrite(
        Path.from([Name('a')]),
        TreeStructuredData.fromJson({'field': 'zzz'}),
      );
      indexed = indexed.applyOperation(operation);
      plain = plain.applyOperation(operation);
      expect(indexed.withFilter(filter).value, plain.withFilter(filter).value);
    });

    test('addIndex on a complete node indexes that value', () {
      final data = TreeStructuredData.fromJson({
        'a': {'field': 'm'},
        'b': {'field': 'a'},
        'c': {'field': 'z'},
      });
      final tree = WriteTree(data)..addIndex(ordering);
      expect(tree.value, isA<IndexedTreeStructuredData>());

      final filter = QueryFilter(ordering: ordering, limit: 2, reversed: true);
      expect(tree.value!.withFilter(filter), data.withFilter(filter));

      final updated = tree.addOverwrite(
        Path.from([Name('a'), Name('field')]),
        TreeStructuredData.fromJson('zzz'),
      );
      expect(updated.value, isA<IndexedTreeStructuredData>());
      expect(
        updated.value!.withFilter(filter),
        data
            .withChild(Name('a'), TreeStructuredData.fromJson({'field': 'zzz'}))
            .withFilter(filter),
      );

      final leaf = WriteTree(TreeStructuredData.fromJson('x'))
        ..addIndex(ordering);
      expect(leaf.value, isNot(isA<IndexedTreeStructuredData>()));
    });

    test('removeWrite drops the child from the index', () {
      final tree = treeWith({'a': 'm', 'b': 'a'})..addIndex(ordering);
      final removed = tree.removeWrite(Path.from([Name('a')]));

      expect(tree.sortedValues(ordering)!.containsKey(Name('a')), isTrue);
      expect(removed.sortedValues(ordering)!.containsKey(Name('a')), isFalse);
    });
  });
}
