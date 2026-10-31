import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import 'mock.dart';

/// A prune that runs in the same transaction as a server update must drop the
/// pruned data and still store that update. Limited queries that share a path
/// must drop children that only the pruned query covered.
void main() {
  const boxName = 'prune-leak';

  late HivePersistenceStorageEngine engine;
  late DefaultPersistenceManager manager;
  late TestCachePolicy policy;

  setUp(() async {
    var box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName, bytes: Uint8List(0));
    await box.clear();
    policy = TestCachePolicy(1);
    engine = HivePersistenceStorageEngine(KeyValueDatabase(box));
    manager = DefaultPersistenceManager(engine, policy);
  });

  tearDown(() async {
    await manager.close();
  });

  test(
      'pruning in the transaction that wrote a server update keeps that update',
      () {
    var oldQuery = QuerySpec(Name.parsePath('carDiaries/old'));
    var newQuery = QuerySpec(Name.parsePath('carDiaries/new'));
    var oldData = TreeStructuredData.fromJson({'entry': 1});
    var newData = TreeStructuredData.fromJson({'entry': 2});

    manager.runInTransaction(() {
      manager.setQueryActive(oldQuery);
      manager.updateServerCache(
          oldQuery, TreeOperation.overwrite(oldQuery.path, oldData));
      manager.setQueryInactive(oldQuery);
    });

    policy.pruneOnNextServerUpdate();
    manager.runInTransaction(() {
      manager.setQueryActive(newQuery);
      manager.updateServerCache(
          newQuery, TreeOperation.overwrite(newQuery.path, newData));
    });

    expect(querySpecs(engine), isNot(contains(oldQuery)));
    expect(querySpecs(engine), contains(newQuery));
    expect(engine.serverCache(oldQuery.path).value, TreeStructuredData(),
        reason: 'data for the pruned query should be removed');
    expect(engine.serverCache(newQuery.path).value, newData,
        reason:
            'the server update applied in the same transaction as the prune should be kept');
  });

  test(
      'pruning the oldest limited query drops children only that query covered',
      () {
    var path = Name.parsePath('carDiaries/veh1');
    var older = QuerySpec(path, QueryFilter(limit: 2));
    var newer = QuerySpec(path, QueryFilter(limit: 2, reversed: true));

    manager.runInTransaction(() {
      manager.setQueryActive(older);
      manager.updateServerCache(
          older,
          TreeOperation.overwrite(
              path, TreeStructuredData.fromJson({'a': 1, 'b': 2})));
      manager.setQueryInactive(older);
    });

    manager.runInTransaction(() {
      manager.setQueryActive(newer);
      manager.updateServerCache(
          newer,
          TreeOperation.overwrite(
              path, TreeStructuredData.fromJson({'b': 2, 'c': 3})));
      manager.setQueryInactive(newer);
    });

    // `a` is outside the newer window, so writing that query must not delete it.
    // Pruning the older query is what should remove it.
    expect(storedKeys(engine, path), {'a', 'b', 'c'});

    policy.pruneOnNextServerUpdate();
    manager.runInTransaction(() {
      manager.setQueryActive(newer);
      manager.updateServerCache(
          newer,
          TreeOperation.overwrite(
              path, TreeStructuredData.fromJson({'b': 2, 'c': 3})));
    });

    expect(querySpecs(engine), isNot(contains(older)));
    expect(querySpecs(engine), contains(newer));
    expect(storedKeys(engine, path), {'b', 'c'},
        reason:
            'children covered only by the pruned query should be removed, and children still covered by the kept query should stay');
  });
}

Iterable<QuerySpec> querySpecs(HivePersistenceStorageEngine engine) {
  return engine.loadTrackedQueries().map((query) => query.querySpec);
}

Set<String> storedKeys(HivePersistenceStorageEngine engine, Path<Name> path) {
  return engine
      .serverCache(path)
      .value
      .children
      .keys
      .map((key) => key.asString())
      .toSet();
}
