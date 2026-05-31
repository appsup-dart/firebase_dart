import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('IncompleteData identity', () {
    var leaf = TreeStructuredData.leaf(Value.string('hello'));
    var empty = IncompleteData.empty();

    test('withFilter returns this when filter unchanged', () {
      expect(identical(empty.withFilter(const QueryFilter()), empty), isTrue);
    });

    test('withFilter returns new instance when filter changes', () {
      final result =
          empty.withFilter(const QueryFilter(limit: 1, reversed: true));
      expect(identical(result, empty), isFalse);
    });

    test('applyOperation returns this for empty merge', () {
      final result = empty.applyOperation(TreeOperation.merge(Path(), {}));
      expect(identical(result, empty), isTrue);
    });

    test('applyOperation returns this when priority unchanged', () {
      final withPrio =
          TreeStructuredData.leaf(Value.string('x'), Value.string('1'));
      final v = empty.applyOperation(TreeOperation.overwrite(Path(), withPrio));
      final result = v.applyOperation(TreeOperation(
          Path.from([Name('.priority')]), SetPriority(withPrio.priority)));
      expect(identical(result, v), isTrue);
    });

    test('applyOperation returns this for forget on missing path', () {
      final v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('child-1'), leaf));
      final result =
          v.applyOperation(TreeOperation(Name.parsePath('child-2'), Forget()));
      expect(identical(result, v), isTrue);
    });

    test('removeWrite returns this on empty data', () {
      expect(identical(empty.removeWrite(Path()), empty), isTrue);
    });

    test('removeWrite returns this when path has no write', () {
      final v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('child-1'), leaf));
      final result = v.removeWrite(Name.parsePath('child-2'));
      expect(identical(result, v), isTrue);
    });

    test('removeWrite returns new instance when write is removed', () {
      final v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('child-1'), leaf));
      final result = v.removeWrite(Name.parsePath('child-1'));
      expect(identical(result, v), isFalse);
    });
  });
}
