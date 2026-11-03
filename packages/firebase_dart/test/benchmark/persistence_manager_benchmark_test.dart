@Tags(['benchmark'])
library;

import 'node_self_stub.dart' if (dart.library.js_interop) 'node_self.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:benchmark_test/benchmark_test.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

/// How many children a limited query keeps. The stored node still has every
/// child; only the returned page is this long.
const _pageSize = 20;

/// Order used by the non-priority page. Children store a string under `field`.
const _childOrdering = TreeStructuredDataOrdering.byChild('field');

const _orderedPage = QueryFilter(
  ordering: _childOrdering,
  limit: _pageSize,
  reversed: true,
);

/// Keeps a read result alive so the timed call cannot be optimized away.
Object? benchmarkSink;

/// [DefaultPersistenceManager] with one stored node of many children.
///
/// [CachePolicy.none] keeps prune and size checks out of the samples. The
/// stored node is complete. The limited query is the newest [_pageSize]
/// children. The orderBy query asks for a page of the same size sorted by
/// each child's `field`.
///
/// The file runs at 100 children and at 1000.
///
/// Run:
/// ```bash
/// dart test --run-skipped -t benchmark test/benchmark/persistence_manager_benchmark_test.dart
/// ```
void main() {
  group('DefaultPersistenceManager', () {
    for (final childCount in _childCounts) {
      group('$childCount children', () {
        late _Harness harness;

        setUp(() async {
          harness = await _Harness.open(childCount);
        });

        tearDown(() => harness.close());

        test('server cache holds the node and the limited page', () {
          final page = harness.manager.serverCache(harness.limited);
          final ordered = harness.manager.serverCache(harness.limitedByChild);
          final whole = harness.manager.serverCache(harness.whole);
          expect(page.isComplete, isTrue);
          expect(page.value.children.length, min(_pageSize, childCount));
          expect(ordered.isComplete, isTrue);
          expect(ordered.value.children.length, min(_pageSize, childCount));
          expect(ordered.value.children.containsKey(harness.newest), isTrue);
          expect(whole.isComplete, isTrue);
          expect(whole.value.children.length, childCount);
        });

        benchmark(
          'serverCache (limited page)',
          () {
            benchmarkSink = harness.manager.serverCache(harness.limited).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'serverCache (limited page, orderBy child)',
          () {
            benchmarkSink =
                harness.manager.serverCache(harness.limitedByChild).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        // A repeated read with the stored filter returns the value composed on
        // the first read. The limited page builds a new filtered value each call.
        benchmark(
          'serverCache (whole node, cached value)',
          () {
            benchmarkSink = harness.manager.serverCache(harness.whole).value;
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'updateServerCache (limited, one child)',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.updateServerCache(
                harness.limited,
                harness.nextChildMerge(),
              );
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'updateServerCache (limited orderBy, one child)',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.updateServerCache(
                harness.limitedByChild,
                harness.nextOrderedChildMerge(),
              );
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'updateServerCache (whole node, one child)',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.updateServerCache(
                harness.whole,
                harness.nextChildMerge(),
              );
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        group('updateServerCache (limited page overwrite)', () {
          setUpEach(() {
            harness.manager.runInTransaction(() {
              harness.manager
                  .updateServerCache(harness.whole, harness.fullOverwrite);
            });
          });

          benchmark(
            'replaces the stored page',
            () {
              harness.manager.runInTransaction(() {
                harness.manager
                    .updateServerCache(harness.limited, harness.pageOverwrite);
              });
            },
            timeout: const Timeout(Duration(minutes: 2)),
          );
        });

        benchmark(
          'saveUserOperation + removeUserOperation',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.saveUserOperation(harness.userWrite, 1);
              harness.manager.removeUserOperation(1);
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'setQueryActive + setQueryInactive',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.setQueryInactive(harness.limited);
              harness.manager.setQueryActive(harness.limited);
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );

        benchmark(
          'setQueryComplete',
          () {
            harness.manager.runInTransaction(() {
              harness.manager.setQueryComplete(harness.limited);
            });
          },
          timeout: const Timeout(Duration(minutes: 2)),
        );
      });
    }
  });
}

const _childCounts = [100, 1000];

int _boxSeq = 0;

class _Harness {
  final DefaultPersistenceManager manager;
  final QuerySpec whole;
  final QuerySpec limited;
  final QuerySpec limitedByChild;
  final Name newest;
  final TreeOperation fullOverwrite;
  final TreeOperation pageOverwrite;
  final TreeOperation childMergeA;
  final TreeOperation childMergeB;
  final TreeOperation orderedChildMergeA;
  final TreeOperation orderedChildMergeB;
  final TreeOperation userWrite;
  var _mergeA = true;
  var _orderedMergeA = true;

  _Harness({
    required this.manager,
    required this.whole,
    required this.limited,
    required this.limitedByChild,
    required this.newest,
    required this.fullOverwrite,
    required this.pageOverwrite,
    required this.childMergeA,
    required this.childMergeB,
    required this.orderedChildMergeA,
    required this.orderedChildMergeB,
    required this.userWrite,
  });

  static Future<_Harness> open(int childCount) async {
    // [nodeSelfReady] is bound before Hive loads. Touch it so that stays true.
    if (!nodeSelfReady) ensureGlobalSelf();
    final box = await Hive.openBox(
      'persistence-manager-benchmark-${_boxSeq++}',
      bytes: Uint8List(0),
    );
    final manager = DefaultPersistenceManager(
      HivePersistenceStorageEngine(KeyValueDatabase(box)),
      CachePolicy.none,
    );
    // Let the open-time maintenance timer run before the cache is filled.
    await Future<void>.delayed(Duration.zero);

    final path = Name.parsePath('items');
    final whole = QuerySpec(path);
    final limited = QuerySpec(
      path,
      const QueryFilter(limit: _pageSize, reversed: true),
    );
    final limitedByChild = QuerySpec(path, _orderedPage);
    final keys = [
      for (var i = 0; i < childCount; i++)
        'key-${i.toString().padLeft(6, '0')}',
    ];
    final children = {
      for (final key in keys) key: {'field': 'value-$key'},
    };
    final snapshot = TreeStructuredData.fromJson(children);
    final pageCount = min(_pageSize, childCount);
    final page = TreeStructuredData.fromJson({
      for (final key in keys.sublist(keys.length - pageCount))
        key: children[key],
    });
    final newest = keys.last;

    manager.runInTransaction(() {
      manager.setQueryActive(whole);
      manager.updateServerCache(
        whole,
        TreeOperation.overwrite(path, snapshot),
      );
      manager.setQueryActive(limited);
      manager.setQueryActive(limitedByChild);
    });

    return _Harness(
      manager: manager,
      whole: whole,
      limited: limited,
      limitedByChild: limitedByChild,
      newest: Name(newest),
      fullOverwrite: TreeOperation.overwrite(path, snapshot),
      pageOverwrite: TreeOperation.overwrite(path, page),
      childMergeA: _fieldMerge(path, newest, 'a'),
      childMergeB: _fieldMerge(path, newest, 'b'),
      // Stay after every `value-*` field so the child remains on the page.
      orderedChildMergeA: _fieldMerge(path, newest, 'z'),
      orderedChildMergeB: _fieldMerge(path, newest, 'zz'),
      userWrite: TreeOperation.overwrite(
        Name.parsePath('pending'),
        TreeStructuredData.fromJson('write'),
      ),
    );
  }

  /// Alternates the written field so each sample changes the stored node.
  TreeOperation nextChildMerge() {
    _mergeA = !_mergeA;
    return _mergeA ? childMergeA : childMergeB;
  }

  /// Alternates a field value that stays last in child order.
  TreeOperation nextOrderedChildMerge() {
    _orderedMergeA = !_orderedMergeA;
    return _orderedMergeA ? orderedChildMergeA : orderedChildMergeB;
  }

  Future<void> close() => manager.close();
}

TreeOperation _fieldMerge(Path<Name> path, String key, String value) {
  return TreeOperation.merge(path, {
    Path<Name>.from([Name(key), Name('field')]):
        TreeStructuredData.fromJson(value),
  });
}
