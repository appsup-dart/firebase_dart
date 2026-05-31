@Tags(['benchmark'])
library;

import 'dart:io';

import 'package:benchmark_test/benchmark_test.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

int _childCount =
    int.tryParse(Platform.environment['BENCHMARK_CHILDREN'] ?? '') ?? 100;

TreeStructuredData _initialSnapshot(int childCount) {
  return TreeStructuredData.fromJson({
    for (var i = 0; i < childCount; i++)
      'key-$i': {
        'field': 'old-$i',
        'nested': {'x': 1},
      },
  });
}

IncompleteData _completeData(int childCount) {
  return IncompleteData.complete(_initialSnapshot(childCount));
}

TreeOperation _mergeOperation(int childCount, {bool identity = false}) {
  return TreeOperation.merge(
    Path.from([]),
    {
      for (var i = 0; i < childCount; i++)
        Path.from([Name('key-$i'), Name('field')]): TreeStructuredData.fromJson(
          identity ? 'old-$i' : 'updated',
        ),
    },
  );
}

/// [IncompleteData.applyOperation] for a complete tree + root merge over many
/// child paths (updates one subchild per child).
///
/// Run:
/// ```bash
/// dart test -t benchmark test/benchmark/incomplete_data_merge_benchmark_test.dart
/// BENCHMARK_CHILDREN=100 dart test -t benchmark test/benchmark/incomplete_data_merge_benchmark_test.dart
/// ```
void main() {
  group('IncompleteData merge', () {
    late IncompleteData data;
    late TreeOperation merge;
    late TreeOperation identityMerge;

    setUp(() {
      data = _completeData(_childCount);
      merge = _mergeOperation(_childCount);
      identityMerge = _mergeOperation(_childCount, identity: true);
    });

    test('snapshot is complete', () {
      expect(data.isComplete, isTrue);
      expect(data.value.children.length, _childCount);
    });

    test('merge updates every child field', () {
      final result = data.applyOperation(merge);
      expect(result.isComplete, isTrue);
      for (var i = 0; i < _childCount; i++) {
        expect(
          result.value.children[Name('key-$i')]!.children[Name('field')]!.value!
              .value,
          'updated',
        );
      }
    });

    benchmark('applyOperation (complete root merge)', () {
      data.applyOperation(merge);
    });

    test('identity merge leaves every child field unchanged', () {
      final before = data.value;
      final result = data.applyOperation(identityMerge);
      expect(result.isComplete, isTrue);
      for (var i = 0; i < _childCount; i++) {
        expect(
          result.value.children[Name('key-$i')]!.children[Name('field')],
          before.children[Name('key-$i')]!.children[Name('field')],
        );
      }
    });

    benchmark('applyOperation (complete identity merge)', () {
      data.applyOperation(identityMerge);
    });

    group('non-complete (per-overwrite loop)', () {
      late IncompleteData sparseData;

      setUp(() {
        sparseData = IncompleteData.fromLeafs({
          for (var i = 0; i < _childCount; i++)
            Path.from([Name('key-$i'), Name('field')]):
                TreeStructuredData.fromJson('old-$i'),
        });
      });

      test('sparse snapshot is not complete', () {
        expect(sparseData.isComplete, isFalse);
      });

      benchmark('applyOperation (sparse merge)', () {
        sparseData.applyOperation(merge);
      });

      benchmark('applyOperation (sparse identity merge)', () {
        sparseData.applyOperation(identityMerge);
      });
    });
  });
}
