@Tags(['benchmark'])
library;

import 'package:benchmark_test/benchmark_test.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

/// How many children a limited [withFilter] keeps.
const _pageSize = 20;

/// Keeps a read result alive so the timed call cannot be optimized away.
Object? benchmarkSink;

int _childCount = 100;

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

/// [IncompleteData] reads and updates.
///
/// The merge group updates every child. The later groups cover
/// [IncompleteData.withFilter] and a one-child [IncompleteData.applyOperation]
/// for a complete node and for partial writes.
///
/// Run:
/// ```bash
/// dart test --run-skipped -t benchmark test/benchmark/incomplete_data_benchmark_test.dart
/// ```
///
/// The filter and one-child groups are written out for 100 children and for
/// 1000, so each benchmark can be started on its own. The every-child merge
/// stays at 100.
void main() {
  group('IncompleteData', () {
    group('merge', () {
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
            result.value.children[Name('key-$i')]!.children[Name('field')]!
                .value!.value,
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

    group('100 children', () {
      group('complete', () {
        late _Fixture fixture;

        setUp(() {
          fixture = _Fixture.build(_Shape.complete, 100);
        });

        test('limited filter returns the page', () {
          _expectPage(fixture, complete: true);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (orderBy child)',
          () {
            benchmarkSink =
                fixture.data.withFilter(fixture.childOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'applyOperation (one child)',
          () {
            benchmarkSink = fixture.data.applyOperation(fixture.oneChild);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });

      group('partial', () {
        late _Fixture fixture;

        setUp(() {
          fixture = _Fixture.build(_Shape.partial, 100);
        });

        test('limited filter returns the page', () {
          _expectPage(fixture, complete: false);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (orderBy child)',
          () {
            benchmarkSink =
                fixture.data.withFilter(fixture.childOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'applyOperation (one child)',
          () {
            benchmarkSink = fixture.data.applyOperation(fixture.oneChild);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'removeWrite (one child)',
          () {
            benchmarkSink = fixture.data.removeWrite(fixture.newestPath);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });
    });

    group('1000 children', () {
      group('complete', () {
        late _Fixture fixture;

        setUp(() {
          fixture = _Fixture.build(_Shape.complete, 1000);
        });

        test('limited filter returns the page', () {
          _expectPage(fixture, complete: true);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (orderBy child)',
          () {
            benchmarkSink =
                fixture.data.withFilter(fixture.childOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'applyOperation (one child)',
          () {
            benchmarkSink = fixture.data.applyOperation(fixture.oneChild);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });

      group('partial', () {
        late _Fixture fixture;

        setUp(() {
          fixture = _Fixture.build(_Shape.partial, 1000);
        });

        test('limited filter returns the page', () {
          _expectPage(fixture, complete: false);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (same ordering)',
          () {
            benchmarkSink = fixture.data.withFilter(fixture.sameOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter + value (orderBy child)',
          () {
            benchmarkSink =
                fixture.data.withFilter(fixture.childOrdering).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'applyOperation (one child)',
          () {
            benchmarkSink = fixture.data.applyOperation(fixture.oneChild);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'removeWrite (one child)',
          () {
            benchmarkSink = fixture.data.removeWrite(fixture.newestPath);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });
    });
  });
}

void _expectPage(_Fixture fixture, {required bool complete}) {
  final same = fixture.data.withFilter(fixture.sameOrdering).value;
  final byChild = fixture.data.withFilter(fixture.childOrdering).value;
  expect(same.children.length, _pageSize);
  expect(byChild.children.length, _pageSize);
  expect(same.children.containsKey(fixture.newest), isTrue);
  expect(fixture.data.isComplete, complete);
  expect(fixture.data.withFilter(fixture.sameOrdering).isComplete, complete);
}

const _sameOrderingPage = QueryFilter(limit: _pageSize, reversed: true);

final _childOrderingPage = QueryFilter(
  ordering: TreeStructuredDataOrdering.byChild('field'),
  limit: _pageSize,
  reversed: true,
);

enum _Shape { complete, partial }

class _Fixture {
  final IncompleteData data;
  final QueryFilter sameOrdering;
  final QueryFilter childOrdering;
  final TreeOperation oneChild;
  final Path<Name> newestPath;
  final Name newest;

  _Fixture({
    required this.data,
    required this.sameOrdering,
    required this.childOrdering,
    required this.oneChild,
    required this.newestPath,
    required this.newest,
  });

  static _Fixture build(_Shape shape, int childCount) {
    final keys = [
      for (var i = 0; i < childCount; i++)
        'key-${i.toString().padLeft(6, '0')}',
    ];
    final newest = Name(keys.last);
    final newestPath = Path<Name>.from([newest]);
    final data = shape == _Shape.complete
        ? IncompleteData.complete(_snapshot(keys))
        : _partialFrom(keys);
    return _Fixture(
      data: data,
      sameOrdering: _sameOrderingPage,
      childOrdering: _childOrderingPage,
      oneChild: TreeOperation.merge(Path<Name>.from([]), {
        Path<Name>.from([newest, Name('field')]):
            TreeStructuredData.fromJson('updated'),
      }),
      newestPath: newestPath,
      newest: newest,
    );
  }
}

TreeStructuredData _snapshot(List<String> keys) {
  return TreeStructuredData.fromJson({
    for (final key in keys) key: {'field': 'value-$key', 'n': key},
  });
}

IncompleteData _partialFrom(List<String> keys) {
  return IncompleteData.fromLeafs({
    for (final key in keys)
      Path<Name>.from([Name(key)]): TreeStructuredData.fromJson({
        'field': 'value-$key',
        'n': key,
      }),
  });
}
