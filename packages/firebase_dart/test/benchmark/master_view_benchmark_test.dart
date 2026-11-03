@Tags(['benchmark'])
library;

import 'package:benchmark_test/benchmark_test.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/view.dart';
import 'package:test/test.dart';

/// How many children a limited query keeps. The master view still holds every
/// child; only the returned page is this long.
const _pageSize = 20;

/// Order used by the non-priority page. Children store a string under `field`.
const _childOrdering = TreeStructuredDataOrdering.byChild('field');

const _priorityPage = QueryFilter(limit: _pageSize, reversed: true);

const _orderedPage = QueryFilter(
  ordering: _childOrdering,
  limit: _pageSize,
  reversed: true,
);

/// Keeps a read result alive so the timed call cannot be optimized away.
Object? benchmarkSink;

/// A default unlimited [MasterView] with an orderBy child observer.
///
/// The snapshot and the observer are installed in [setUp]. The timed bodies
/// read a limited page or apply a one-child server update.
///
/// Run:
/// ```bash
/// dart test --run-skipped -t benchmark test/benchmark/master_view_benchmark_test.dart
/// ```
void main() {
  group('MasterView', () {
    _masterViewBenchmarks(100);
    _masterViewBenchmarks(1000);
  });
}

void _masterViewBenchmarks(int childCount) {
  group('$childCount children', () {
    late _Harness harness;

    setUp(() {
      harness = _Harness(childCount);
    });

    test('the orderBy page is the window', () {
      final page = harness.view.data.valueForFilter(_orderedPage).value;
      expect(page.children.length, _pageSize);
      expect(page.children.containsKey(harness.newest), isTrue);
    });

    benchmark(
      'valueForFilter (limited page)',
      () {
        benchmarkSink = harness.view.data.valueForFilter(_priorityPage).value;
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    benchmark(
      'valueForFilter (limited page, orderBy child)',
      () {
        benchmarkSink = harness.view.data.valueForFilter(_orderedPage).value;
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    benchmark(
      'server update (one child, orderBy observer)',
      () {
        harness.view.applyOperation(
          harness.nextOrderedChildMerge(),
          ViewOperationSource.server,
          null,
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

class _Harness {
  final MasterView view;
  final Name newest;
  final TreeOperation orderedChildMergeA;
  final TreeOperation orderedChildMergeB;
  var _orderedMergeA = true;

  _Harness._(
    this.view,
    this.newest,
    this.orderedChildMergeA,
    this.orderedChildMergeB,
  );

  factory _Harness(int childCount) {
    final keys = [
      for (var i = 0; i < childCount; i++)
        'key-${i.toString().padLeft(6, '0')}',
    ];
    final snapshot = TreeStructuredData.fromJson({
      for (final key in keys) key: {'field': 'value-$key'},
    });
    final newest = keys.last;
    final view = MasterView(const QueryFilter(), persistenceEnabled: true);
    view.applyOperation(
      TreeOperation.overwrite(Path(), snapshot),
      ViewOperationSource.server,
      null,
    );
    view.addEventListener('value', _orderedPage, (_) {});
    return _Harness._(
      view,
      Name(newest),
      _fieldMerge(newest, 'z'),
      _fieldMerge(newest, 'zz'),
    );
  }

  /// Alternates a field value that stays last in child order.
  TreeOperation nextOrderedChildMerge() {
    _orderedMergeA = !_orderedMergeA;
    return _orderedMergeA ? orderedChildMergeA : orderedChildMergeB;
  }
}

TreeOperation _fieldMerge(String key, String value) {
  return TreeOperation.merge(Path(), {
    Path<Name>.from([Name(key), Name('field')]):
        TreeStructuredData.fromJson(value),
  });
}
