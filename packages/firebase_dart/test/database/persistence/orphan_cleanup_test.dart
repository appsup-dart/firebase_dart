import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  const boxName = 'orphan-cleanup';

  late HivePersistenceStorageEngine engine;

  setUp(() async {
    var box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName, bytes: Uint8List(0));
    await box.clear();
    engine = HivePersistenceStorageEngine(KeyValueDatabase(box));
  });

  tearDown(() async {
    await engine.close();
  });

  test('opening persistence drops cache data no tracked query covers',
      () async {
    var kept = QuerySpec(Name.parsePath('carDiaries/kept'));
    var keptData = TreeStructuredData.fromJson({'entry': 1});
    var orphanPath = Name.parsePath('carDiaries/orphan');
    var vehicle = Name.parsePath('carDiaries/veh1');
    var limited = QuerySpec(vehicle, QueryFilter(limit: 2));
    var writePath = Name.parsePath('pending');

    engine.beginTransaction();
    engine.saveTrackedQuery(TrackedQuery(
        id: 1,
        querySpec: kept,
        lastUse: DateTime.utc(2020),
        complete: true,
        active: true));
    engine.saveTrackedQuery(TrackedQuery(
        id: 2,
        querySpec: limited,
        lastUse: DateTime.utc(2020),
        complete: true,
        active: false));
    engine.overwriteServerCache(TreeOperation.overwrite(kept.path, keptData));
    engine.overwriteServerCache(TreeOperation.overwrite(
        orphanPath, TreeStructuredData.fromJson({'entry': 2})));
    engine.overwriteServerCache(TreeOperation.merge(vehicle, {
      Name.parsePath('a'): TreeStructuredData.fromJson(1),
      Name.parsePath('b'): TreeStructuredData.fromJson(2),
      Name.parsePath('c'): TreeStructuredData.fromJson(3),
    }));
    engine.saveUserOperation(
        TreeOperation.overwrite(writePath, TreeStructuredData.fromJson(1)), 7);
    engine.endTransaction();

    DefaultPersistenceManager(engine, CachePolicy.none);

    expect(engine.serverCache(orphanPath).value,
        TreeStructuredData.fromJson({'entry': 2}),
        reason: 'cleanup waits for a later task');

    await Future<void>.delayed(Duration.zero);

    expect(engine.serverCache(orphanPath).value, TreeStructuredData(),
        reason: 'cache data with no tracked query should be removed');
    expect(engine.serverCache(kept.path).value, keptData);
    expect(storedKeys(engine, vehicle), {'a', 'b'},
        reason:
            'a limited query should keep only the children that match its filter');
    expect(engine.loadUserOperations().keys, [7]);

    engine.beginTransaction();
    engine.overwriteServerCache(TreeOperation.overwrite(
        orphanPath, TreeStructuredData.fromJson({'entry': 3})));
    engine.endTransaction();

    DefaultPersistenceManager(engine, CachePolicy.none);
    await Future<void>.delayed(Duration.zero);

    expect(engine.serverCache(orphanPath).value,
        TreeStructuredData.fromJson({'entry': 3}),
        reason: 'the cleanup runs once, so later orphans are left in place');
  });
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
