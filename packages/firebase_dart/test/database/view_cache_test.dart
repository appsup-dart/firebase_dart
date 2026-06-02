import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/view.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

void main() {
  group('ViewCache.recalcLocalVersion', () {
    final leaf = TreeStructuredData.leaf(Value.string('hello'));

    test('returns false when local already matches server with no pending ops',
        () {
      final server = IncompleteData.empty();
      final cache = ViewCache(server, server);
      expect(cache.recalcLocalVersion(), isFalse);
    });

    test('returns false on second recalc without intervening changes', () {
      final server = IncompleteData.empty();
      final cache = ViewCache(server, server);
      cache.recalcLocalVersion();
      expect(cache.recalcLocalVersion(), isFalse);
    });

    test('returns false when pending operation is a no-op', () {
      final server = IncompleteData.empty()
          .applyOperation(TreeOperation.overwrite(Path(), leaf));
      final cache = ViewCache(
        server,
        server,
        TreeMap.from({1: TreeOperation.overwrite(Path(), leaf)}),
      );
      expect(cache.recalcLocalVersion(), isFalse);
    });

    test('returns true when local was out of sync with server', () {
      final server = IncompleteData.empty()
          .applyOperation(TreeOperation.overwrite(Path(), leaf));
      final cache = ViewCache(IncompleteData.empty(), server);
      expect(cache.recalcLocalVersion(), isTrue);
      expect(cache.localVersion.value, leaf);
    });

    test('returns true when pending operation changes local version', () {
      final server = IncompleteData.empty();
      final cache = ViewCache(
        server,
        server,
        TreeMap.from({1: TreeOperation.overwrite(Path(), leaf)}),
      );
      expect(cache.recalcLocalVersion(), isTrue);
      expect(cache.localVersion.value, leaf);
    });

    test('returns true when recalc drops a removed pending operation effect',
        () {
      final server = IncompleteData.empty();
      final cache = ViewCache(
        IncompleteData.empty()
            .applyOperation(TreeOperation.overwrite(Path(), leaf)),
        server,
        TreeMap.from({1: TreeOperation.overwrite(Path(), leaf)}),
      );
      final pending = TreeMap.from(cache.pendingOperations)..remove(1);
      final withoutPending = ViewCache(cache.localVersion, server, pending);
      expect(withoutPending.recalcLocalVersion(), isTrue);
      expect(withoutPending.localVersion.isNil, isTrue);
    });
  });

  group('ViewCache.applyOperation', () {
    final leaf = TreeStructuredData.leaf(Value.string('hello'));

    test('returns localVersionChanged false for no-op user operation', () {
      final server = IncompleteData.empty()
          .applyOperation(TreeOperation.overwrite(Path(), leaf));
      final cache = ViewCache(
        server,
        server,
        TreeMap.from({1: TreeOperation.overwrite(Path(), leaf)}),
      );
      final result = cache.applyOperation(
          TreeOperation.overwrite(Path(), leaf), ViewOperationSource.user, 2);
      expect(result.localVersionChanged, isFalse);
      expect(result.viewCache.pendingOperations[2], isNotNull);
    });

    test(
        'returns localVersionChanged true for user operation that changes data',
        () {
      final server = IncompleteData.empty();
      final cache = ViewCache(server, server);
      final result = cache.applyOperation(
          TreeOperation.overwrite(Path(), leaf), ViewOperationSource.user, 1);
      expect(result.localVersionChanged, isTrue);
      expect(result.viewCache.localVersion.value, leaf);
    });

    test('returns localVersionChanged true when ack removes pending write', () {
      final server = IncompleteData.empty();
      var cache = ViewCache(
        server,
        server,
        TreeMap.from({1: TreeOperation.overwrite(Path(), leaf)}),
      );
      cache = cache
          .applyOperation(TreeOperation.overwrite(Path(), leaf),
              ViewOperationSource.user, 1)
          .viewCache;
      final result = cache.applyOperation(
          TreeOperation.ack(Path(), true), ViewOperationSource.ack, 1);
      expect(result.localVersionChanged, isTrue);
      expect(result.viewCache.localVersion.isNil, isTrue);
    });
  });
}
