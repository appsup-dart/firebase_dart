import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('Operation.apply identity', () {
    var leaf = TreeStructuredData.leaf(Value.string('hello'));
    var parent = TreeStructuredData.nonLeaf({
      Name('a'): TreeStructuredData.leaf(Value.string('a')),
      Name('b'): TreeStructuredData.leaf(Value.string('b')),
    });

    test('Overwrite returns argument when overwrite value is already applied',
        () {
      var op = Overwrite(leaf);
      expect(identical(op.apply(leaf), leaf), isTrue);
    });

    test('Overwrite returns new instance when value changes', () {
      var other = TreeStructuredData.leaf(Value.string('world'));
      var op = Overwrite(other);
      var result = op.apply(leaf);
      expect(identical(result, leaf), isFalse);
      expect(identical(result, other), isTrue);
    });

    test('SetPriority returns argument when priority unchanged', () {
      var withPrio =
          TreeStructuredData.leaf(Value.string('x'), Value.string('1'));
      var op = SetPriority(withPrio.priority);
      expect(identical(op.apply(withPrio), withPrio), isTrue);
    });

    test('SetPriority returns argument on nil node with null priority', () {
      var nil = TreeStructuredData();
      var op = SetPriority(null);
      expect(identical(op.apply(nil), nil), isTrue);
    });

    test('TreeOperation returns argument for nil overwrite on missing child',
        () {
      var op = TreeOperation.overwrite(
          Path.from([Name('missing')]), TreeStructuredData());
      expect(identical(op.apply(parent), parent), isTrue);
    });

    test('TreeOperation returns argument when overwrite uses equal value', () {
      var op = TreeOperation.overwrite(
          Path.from([Name('a')]), TreeStructuredData.leaf(Value.string('a')));
      expect(identical(op.apply(parent), parent), isTrue);
    });

    test('TreeOperation returns new instance when child changes', () {
      var op = TreeOperation.overwrite(Path.from([Name('a')]),
          TreeStructuredData.leaf(Value.string('changed')));
      var result = op.apply(parent);
      expect(identical(result, parent), isFalse);
      expect(result.children[Name('a')]!.value, Value.string('changed'));
    });

    test('Merge returns argument when no overwrites change the value', () {
      var op = Merge({
        Path.from([Name('a')]): parent.children[Name('a')]!,
        Path.from([Name('missing')]): TreeStructuredData(),
      });
      expect(identical(op.apply(parent), parent), isTrue);
    });

    test('Merge returns argument for empty merge', () {
      var op = Merge({});
      expect(identical(op.apply(parent), parent), isTrue);
    });

    test('Merge returns new instance when a child changes', () {
      var op = Merge({
        Path.from([Name('a')]):
            TreeStructuredData.leaf(Value.string('changed')),
      });
      var result = op.apply(parent);
      expect(identical(result, parent), isFalse);
    });

    test('nested TreeOperation preserves identity through unchanged siblings',
        () {
      var op = TreeOperation.overwrite(
          Path.from([Name('b')]), parent.children[Name('b')]!);
      expect(identical(op.apply(parent), parent), isTrue);
    });
  });
}
