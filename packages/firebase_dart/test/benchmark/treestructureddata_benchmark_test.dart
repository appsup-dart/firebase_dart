@Tags(['benchmark'])
library;

import 'package:benchmark_test/benchmark_test.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

/// How many children a limited [TreeStructuredData.withFilter] keeps.
const _pageSize = 20;

/// Keeps a read result alive so the timed call cannot be optimized away.
Object? benchmarkSink;

const _sameOrderingPage = QueryFilter(limit: _pageSize, reversed: true);

final _childOrderingPage = QueryFilter(
  ordering: TreeStructuredDataOrdering.byChild('field'),
  limit: _pageSize,
  reversed: true,
);

const _priority = TreeStructuredDataOrdering.byPriority();

final _childOrdering = TreeStructuredDataOrdering.byChild('field');

/// [TreeStructuredData.withFilter] and the child updates around it.
///
/// Each benchmark is written out so it can be started on its own.

///
/// Run:
/// ```bash
/// dart test --run-skipped -t benchmark test/benchmark/treestructureddata_benchmark_test.dart
/// ```
void main() {
  group('TreeStructuredData', () {
    group('100 children', () {
      group('node', () {
        late IndexedTreeStructuredData node;
        late Name newest;

        setUp(() {
          node = _node(100);
          newest = _newest(100);
          node.addIndex(_priority);
          node.addIndex(_childOrdering);
        });

        test('limited filter returns the page', () {
          _expectPage(node);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = node.withFilter(_sameOrderingPage);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter (orderBy child)',
          () {
            benchmarkSink = node.withFilter(_childOrderingPage);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'view (same ordering)',
          () {
            benchmarkSink = node.view(
              start: Pair.min(),
              end: Pair.max(),
              limit: _pageSize,
              reversed: true,
            );
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withChild',
          () {
            benchmarkSink = node.withChild(
              newest,
              TreeStructuredData.fromJson({'field': 'updated'}),
            );
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withoutChild',
          () {
            benchmarkSink = node.withoutChild(newest);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });
    });

    group('1000 children', () {
      group('node', () {
        late IndexedTreeStructuredData node;
        late Name newest;

        setUp(() {
          node = _node(1000);
          newest = _newest(1000);
          node.addIndex(_priority);
          node.addIndex(_childOrdering);
        });

        test('limited filter returns the page', () {
          _expectPage(node);
        });

        benchmark(
          'withFilter (same ordering)',
          () {
            benchmarkSink = node.withFilter(_sameOrderingPage);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withFilter (orderBy child)',
          () {
            benchmarkSink = node.withFilter(_childOrderingPage);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'view (same ordering)',
          () {
            benchmarkSink = node.view(
              start: Pair.min(),
              end: Pair.max(),
              limit: _pageSize,
              reversed: true,
            );
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withChild',
          () {
            benchmarkSink = node.withChild(
              newest,
              TreeStructuredData.fromJson({'field': 'updated'}),
            );
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'withoutChild',
          () {
            benchmarkSink = node.withoutChild(newest);
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });
    });
  });
}

void _expectPage(IndexedTreeStructuredData node) {
  expect(node.withFilter(_sameOrderingPage).children.length, _pageSize);
  expect(node.withFilter(_childOrderingPage).children.length, _pageSize);
  expect(node.indexedOrderings, contains(_childOrdering));
}

TreeStructuredData _tree(int childCount) {
  return TreeStructuredData.fromJson({
    for (var i = 0; i < childCount; i++)
      'key-${i.toString().padLeft(6, '0')}': {'field': 'value-$i'},
  });
}

IndexedTreeStructuredData _node(int childCount) =>
    IndexedTreeStructuredData.from(_tree(childCount));

Name _newest(int childCount) =>
    Name('key-${(childCount - 1).toString().padLeft(6, '0')}');
