import 'package:firebase_dart/src/database/impl/data_observer.dart';
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
}
