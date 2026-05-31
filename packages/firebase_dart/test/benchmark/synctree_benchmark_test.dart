@Tags(['benchmark'])
library;

import 'dart:io';

import 'package:benchmark_test/benchmark_test.dart';
import 'package:test/test.dart';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

/// SyncTree: parent + [synctreeMergeBenchmarkChildCount] child listeners,
/// user merge, matching server merge, write ack.
///
/// Each group creates one [SynctreeMergeHarness] in [setUp] (listener install is
/// costly). Iterations reuse that tree; only the benchmark [body] is timed.
///
/// Run:
/// ```bash
/// dart test -t benchmark test/benchmark/
/// BENCHMARK_CHILDREN=50 dart test -t benchmark test/benchmark/
/// ```
void main() {
  group('synctree merge', () {
    group('write path', () {
      late SynctreeMergeHarness harness;

      setUp(() async {
        harness = await SynctreeMergeHarness.create(
          childCount: synctreeMergeBenchmarkChildCount,
        );
      });

      tearDown(() => harness.dispose());

      benchmark('fullWriteCycle (merge + server + ack)', () {
        harness.applyUserMerge();
        harness.applyMatchingServerMerge();
        harness.applyAck();
      });

      benchmark('userMerge only', () => harness.applyUserMerge());
    });

    group('serverMerge only (after user merge)', () {
      late SynctreeMergeHarness harness;

      setUp(() async {
        harness = await SynctreeMergeHarness.create(
          childCount: synctreeMergeBenchmarkChildCount,
        );
      });

      tearDown(() => harness.dispose());

      setUpEach(() => harness.applyUserMerge());

      benchmark('serverMerge', () => harness.applyMatchingServerMerge());
    });

    group('ack only (after user merge + server merge)', () {
      late SynctreeMergeHarness harness;

      setUp(() async {
        harness = await SynctreeMergeHarness.create(
          childCount: synctreeMergeBenchmarkChildCount,
        );
      });

      tearDown(() => harness.dispose());

      setUpEach(() {
        harness.applyUserMerge();
        harness.applyMatchingServerMerge();
      });

      benchmark('ack', () => harness.applyAck());
    });
  });
}

int synctreeMergeBenchmarkChildCount =
    int.tryParse(Platform.environment['BENCHMARK_CHILDREN'] ?? '') ?? 100;

/// SyncTree with parent + per-child listeners, initial server snapshot, parent
/// registered so children are [SyncPoint.isCompleteFromParent].
class SynctreeMergeHarness {
  final int childCount;
  final SyncTree syncTree;
  final Path<Name> parentPath = Name.parsePath('data');
  final QueryFilter filter = const QueryFilter();
  static const int writeId = 1;

  SynctreeMergeHarness._(this.childCount)
      : syncTree = SyncTree(
          'benchmark:///',
          persistenceManager: NoopPersistenceManager(),
        );

  /// Builds a fresh [SyncTree] with listeners and optional pending-write state.
  ///
  /// Create once per benchmark group (in [setUp]), not each iteration: listener
  /// registration dominates cost. Iterations reuse the tree; [applyUserMerge],
  /// [applyMatchingServerMerge], and [applyAck] return it to a repeatable state.
  static Future<SynctreeMergeHarness> create({required int childCount}) async {
    final harness = SynctreeMergeHarness._(childCount);
    await harness._installListenersAndInitialServer();
    return harness;
  }

  void dispose() {
    syncTree.destroy();
  }

  Future<void> _installListenersAndInitialServer() async {
    void listener(_) {}

    await syncTree.addEventListener('value', parentPath, filter, listener);
    for (var i = 0; i < childCount; i++) {
      await syncTree.addEventListener(
        'value',
        parentPath.child(Name('key-$i')),
        filter,
        listener,
      );
    }

    syncTree.applyServerOperation(
      TreeOperation.overwrite(
        parentPath,
        TreeStructuredData.fromJson({
          for (var i = 0; i < childCount; i++)
            'key-$i': {
              'field': 'old-$i',
              'nested': {'x': 1},
            },
        }),
      ),
      QuerySpec(parentPath, filter),
    );

    syncTree.onRegistrationStateChanged(
      parentPath,
      filter,
      QueryRegistrationState.registered,
    );
    syncTree.handleInvalidPaths();
    await syncTree.waitForAllProcessed();
  }

  late final Map<Path<Name>, TreeStructuredData> mergePayload = {
    for (var i = 0; i < childCount; i++)
      Path.from([Name('key-$i'), Name('field')]):
          TreeStructuredData.fromJson('updated'),
  };

  void applyUserMerge() {
    syncTree.applyUserMerge(parentPath, mergePayload, writeId);
  }

  void applyMatchingServerMerge() {
    syncTree.applyServerOperation(
      TreeOperation.merge(parentPath, mergePayload),
      QuerySpec(parentPath, filter),
    );
  }

  void applyAck() {
    syncTree.applyAck(parentPath, writeId, true);
  }
}
