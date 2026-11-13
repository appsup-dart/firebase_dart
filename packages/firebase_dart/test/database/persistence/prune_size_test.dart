import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

/// A cache that is over its maximum should be pruned once, down to 80% of
/// that maximum, and the recorded size should match a full recompute.
void main() {
  const boxName = 'prune-size';

  late HivePersistenceStorageEngine engine;
  late DefaultPersistenceManager manager;
  late _SizePolicy policy;

  setUp(() async {
    var box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName, bytes: Uint8List(0));
    await box.clear();
    policy = _SizePolicy(1 << 30);
    engine = HivePersistenceStorageEngine(KeyValueDatabase(box));
    manager = DefaultPersistenceManager(engine, policy);
  });

  tearDown(() async {
    await manager.close();
  });

  test('a size prune stops at the low-water mark', () async {
    var data = TreeStructuredData.fromJson({'v': 1});
    for (var i = 0; i < 5; i++) {
      var query = QuerySpec(_path(i));
      manager.runInTransaction(() {
        manager.setQueryActive(query);
        manager.updateServerCache(
            query, TreeOperation.overwrite(query.path, data));
        manager.setQueryInactive(query);
      });
    }

    var size = engine.serverCacheEstimatedSizeInBytes();
    expect(size % 5, 0, reason: 'the five cached nodes should be equal');
    policy.maxSizeBytes = (size ~/ 5) * 3;
    var lowWater = policy.maximumCacheSizeAfterPrune;

    var again = QuerySpec(_path(4));
    manager.runInTransaction(() {
      manager.updateServerCache(
          again, TreeOperation.overwrite(again.path, data));
    });

    var afterUpdate = engine.serverCacheEstimatedSizeInBytes();
    expect(afterUpdate, greaterThan(lowWater),
        reason: 'the size check only marks the cache; it does not prune yet');

    await Future<void>.delayed(Duration.zero);

    var after = engine.serverCacheEstimatedSizeInBytes();
    expect(after, lessThanOrEqualTo(lowWater));
    expect(after, engine.serverCache(Path<Name>()).estimatedStorageSize);
  });

  test('an LRU policy checks the cache size about every 100 updates', () {
    var policy = LRUCachePolicy(1);
    expect(policy.shouldCheckCacheSize(100), isFalse);
    expect(policy.shouldCheckCacheSize(101), isTrue);
  });

  test('opening an over-size cache prunes in a later task', () async {
    var data = TreeStructuredData.fromJson({'v': 1});
    for (var i = 0; i < 5; i++) {
      var query = QuerySpec(_path(i));
      manager.runInTransaction(() {
        manager.setQueryActive(query);
        manager.updateServerCache(
            query, TreeOperation.overwrite(query.path, data));
        manager.setQueryInactive(query);
      });
    }

    var size = engine.serverCacheEstimatedSizeInBytes();
    var lowPolicy = _SizePolicy((size ~/ 5) * 3);
    var lowWater = lowPolicy.maximumCacheSizeAfterPrune;
    DefaultPersistenceManager(engine, lowPolicy);

    expect(engine.serverCacheEstimatedSizeInBytes(), greaterThan(lowWater),
        reason: 'opening only marks the cache; it does not prune yet');

    await Future<void>.delayed(Duration.zero);

    expect(
        engine.serverCacheEstimatedSizeInBytes(), lessThanOrEqualTo(lowWater));
  });
}

Path<Name> _path(int index) =>
    Name.parsePath('item/${index.toString().padLeft(2, '0')}');

/// Prunes whenever the cache is over [maxSizeBytes], down to 80% of it.
class _SizePolicy implements CachePolicy {
  int maxSizeBytes;

  _SizePolicy(this.maxSizeBytes);

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) => true;

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) =>
      currentSizeBytes > maxSizeBytes;

  @override
  int get maxNumberOfQueriesToKeep => 1 << 31;

  @override
  int get maximumCacheSizeAfterPrune => (maxSizeBytes * 0.8).floor();
}
