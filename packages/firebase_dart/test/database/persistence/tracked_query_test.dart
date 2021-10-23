import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:hive/hive.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

import 'mock.dart';

void main() async {
  await Hive.openBox('firebase-db-storage', bytes: Uint8List(0));

  var sampleQueryParams = QueryFilter(
      ordering: TreeStructuredDataOrdering.byChild('child'),
      limit: 5,
      reversed: true,
      validInterval: KeyValueInterval(
        Name('startKey'),
        TreeStructuredData.fromJson('startVal'),
        Name('endKey'),
        TreeStructuredData.fromJson('endVal'),
      ));

  var sampleFooQuery = QuerySpec(Name.parsePath('foo'), sampleQueryParams);

  group('TrackedQueryManager', () {
    tearDown(() async {
      await Hive.box('firebase-db-storage').clear();
    });
    test('find tracked query', () {
      var manager = newManager();
      expect(manager.findTrackedQuery(sampleFooQuery), null);
      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);
      manager.storageLayer.endTransaction();
      expect(manager.findTrackedQuery(sampleFooQuery), isNot(null));
    });
    test('remove tracked query', () {
      var manager = newManager();
      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);
      expect(manager.findTrackedQuery(sampleFooQuery), isNot(null));
      manager.removeTrackedQuery(sampleFooQuery);
      manager.storageLayer.endTransaction();
      expect(manager.findTrackedQuery(sampleFooQuery), null);
      manager.verifyCache();
    });

    test('set query active and inactive', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.setQueryActive(sampleFooQuery);
        manager.storageLayer.endTransaction();
        var q = manager.findTrackedQuery(sampleFooQuery)!;
        expect(q.active, true);
        expect(clock.now(), q.lastUse);
        manager.verifyCache();

        fakeAsync.elapse(Duration(seconds: 2));
        manager.storageLayer.beginTransaction();
        manager.setQueryInactive(sampleFooQuery);
        manager.storageLayer.endTransaction();
        q = manager.findTrackedQuery(sampleFooQuery)!;
        expect(q.active, false);
        expect(clock.now(), q.lastUse);
        manager.verifyCache();
      });
    });

    test('set query complete', () {
      var manager = newManager();
      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);
      manager.setQueryCompleteIfExists(sampleFooQuery);
      manager.storageLayer.endTransaction();
      expect(manager.findTrackedQuery(sampleFooQuery)!.complete, true);
      manager.verifyCache();
    });

    test('set queries complete', () {
      var manager = newManager();
      manager.storageLayer.beginTransaction();
      manager.setQueryActive(QuerySpec(Name.parsePath('foo')));
      manager.setQueryActive(QuerySpec(Name.parsePath('foo/bar')));
      manager.setQueryActive(QuerySpec(Name.parsePath('elsewhere')));
      manager
          .setQueryActive(QuerySpec(Name.parsePath('foo'), sampleQueryParams));
      manager.setQueryActive(
          QuerySpec(Name.parsePath('foo/baz'), sampleQueryParams));
      manager.setQueryActive(
          QuerySpec(Name.parsePath('elsewhere'), sampleQueryParams));

      manager.setQueriesComplete(Name.parsePath('foo'));
      manager.storageLayer.endTransaction();

      expect(
          manager.findTrackedQuery(QuerySpec(Name.parsePath('foo')))!.complete,
          true);
      expect(
          manager
              .findTrackedQuery(QuerySpec(Name.parsePath('foo/bar')))!
              .complete,
          true);
      expect(
          manager
              .findTrackedQuery(
                  QuerySpec(Name.parsePath('foo'), sampleQueryParams))!
              .complete,
          true);
      expect(
          manager
              .findTrackedQuery(
                  QuerySpec(Name.parsePath('foo/baz'), sampleQueryParams))!
              .complete,
          true);
      expect(
          manager
              .findTrackedQuery(QuerySpec(Name.parsePath('elsewhere')))!
              .complete,
          false);
      expect(
          manager
              .findTrackedQuery(
                  QuerySpec(Name.parsePath('elsewhere'), sampleQueryParams))!
              .complete,
          false);
      manager.verifyCache();
    });

    test('is query complete', () {
      var manager = newManager();

      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);
      manager.setQueryCompleteIfExists(sampleFooQuery);

      manager.setQueryActive(QuerySpec(Name.parsePath('bar')));

      manager.setQueryActive(QuerySpec(Name.parsePath('baz')));
      manager.setQueryCompleteIfExists(QuerySpec(Name.parsePath('baz')));
      manager.storageLayer.endTransaction();

      expect(manager.isQueryComplete(sampleFooQuery), true);
      expect(manager.isQueryComplete(QuerySpec(Name.parsePath('bar'))), false);

      expect(manager.isQueryComplete(QuerySpec(Name.parsePath(''))), false);
      expect(manager.isQueryComplete(QuerySpec(Name.parsePath('baz'))), true);
      expect(
          manager.isQueryComplete(QuerySpec(Name.parsePath('baz/quu'))), true);
    });

    test('prune old queries', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.setQueryActive(QuerySpec(Name.parsePath('active1')));
        manager.setQueryActive(QuerySpec(Name.parsePath('active2')));
        manager.setQueryActive(QuerySpec(Name.parsePath('inactive1')));
        manager.setQueryInactive(QuerySpec(Name.parsePath('inactive1')));

        fakeAsync.elapse(Duration(seconds: 100));

        manager.setQueryActive(QuerySpec(Name.parsePath('inactive2')));
        manager.setQueryInactive(QuerySpec(Name.parsePath('inactive2')));

        fakeAsync.elapse(Duration(seconds: 100));

        manager.setQueryActive(QuerySpec(Name.parsePath('inactive3')));
        manager.setQueryInactive(QuerySpec(Name.parsePath('inactive3')));

        fakeAsync.elapse(Duration(seconds: 100));

        manager.setQueryActive(QuerySpec(Name.parsePath('inactive4')));
        manager.setQueryInactive(QuerySpec(Name.parsePath('inactive4')));

        // Should prune the first two inactive queries.
        var forest = manager.pruneOldQueries(TestCachePolicy(0.5));
        var expected = PruneForest()
            .prune(Name.parsePath('inactive1'))
            .prune(Name.parsePath('inactive2'))
            .keep(Name.parsePath('active1'))
            .keep(Name.parsePath('active2'))
            .keep(Name.parsePath('inactive3'))
            .keep(Name.parsePath('inactive4'));
        expect(forest, expected);

        // Should prune the other two inactive queries.
        forest = manager.pruneOldQueries(TestCachePolicy(1.0));
        expected = PruneForest()
            .prune(Name.parsePath('inactive3'))
            .prune(Name.parsePath('inactive4'))
            .keep(Name.parsePath('active1'))
            .keep(Name.parsePath('active2'));
        expect(forest, expected);

        forest = manager.pruneOldQueries(TestCachePolicy(1.0));
        expect(forest.prunesAnything(), false);
        manager.storageLayer.endTransaction();

        manager.verifyCache();
      });
    });

    test('prune queries over max size', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        // Create a bunch of inactive queries.
        for (var i = 0; i < 15; i++) {
          manager.setQueryActive(QuerySpec(Name.parsePath('$i')));
          manager.setQueryInactive(QuerySpec(Name.parsePath('$i')));
          fakeAsync.elapse(Duration(seconds: i + 1));
        }
        manager.storageLayer.endTransaction();

        manager.storageLayer.beginTransaction();
        var forest = manager.pruneOldQueries(TestCachePolicy(0.2, 10));
        manager.storageLayer.endTransaction();

        // Should prune down to the max of 10, so 5 pruned.
        var expected = PruneForest();
        for (var i = 0; i < 15; i++) {
          if (i < 5) {
            expected = expected.prune(Name.parsePath('$i'));
          } else {
            expected = expected.keep(Name.parsePath('$i'));
          }
        }
        expect(forest, expected);

        manager.verifyCache();
      });
    });

    test('prune default with deeper queries', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.setQueryActive(QuerySpec(Name.parsePath('foo')));
        manager.setQueryActive(
            QuerySpec(Name.parsePath('foo/a'), sampleQueryParams));
        manager.setQueryActive(
            QuerySpec(Name.parsePath('foo/b'), sampleQueryParams));
        manager.setQueryInactive(QuerySpec(Name.parsePath('foo')));

        // prune foo, but keep foo/a and foo/b
        var forest = manager.pruneOldQueries(TestCachePolicy(1.0));
        manager.storageLayer.endTransaction();
        var expected = PruneForest()
            .prune(Name.parsePath('foo'))
            .keep(Name.parsePath('foo/a'))
            .keep(Name.parsePath('foo/b'));
        expect(forest, expected);
        manager.verifyCache();
      });
    });

    test('prune queries with default query on parent', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.setQueryActive(QuerySpec(Name.parsePath('foo')));
        manager.setQueryActive(
            QuerySpec(Name.parsePath('foo/a'), sampleQueryParams));
        manager.setQueryActive(
            QuerySpec(Name.parsePath('foo/b'), sampleQueryParams));
        manager.setQueryInactive(
            QuerySpec(Name.parsePath('foo/a'), sampleQueryParams));
        manager.setQueryInactive(
            QuerySpec(Name.parsePath('foo/b'), sampleQueryParams));
        manager.storageLayer.endTransaction();

        // prune foo/a and foo/b, but keep foo
        manager.storageLayer.beginTransaction();
        var forest = manager.pruneOldQueries(TestCachePolicy(1.0));
        manager.storageLayer.endTransaction();
        var expected = PruneForest()
            .prune(Name.parsePath('foo/a'))
            .prune(Name.parsePath('foo/b'))
            .keep(Name.parsePath('foo'));
        expect(forest, expected);
        manager.verifyCache();
      });
    });

    test('ensure tracked query for new query', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.ensureCompleteTrackedQuery(Name.parsePath('foo'));
        manager.storageLayer.endTransaction();
        var query = manager.findTrackedQuery(QuerySpec(Name.parsePath('foo')))!;
        expect(query.complete, true);
        expect(query.lastUse, clock.now());
      });
    });

    test('ensure tracked query for already tracked query', () {
      fakeAsync((fakeAsync) {
        var manager = newManager();

        manager.storageLayer.beginTransaction();
        manager.setQueryActive(QuerySpec(Name.parsePath('foo')));

        var lastTick = clock.now();

        fakeAsync.elapse(Duration(seconds: 2));

        manager.ensureCompleteTrackedQuery(Name.parsePath('foo'));
        manager.storageLayer.endTransaction();
        expect(
            manager.findTrackedQuery(QuerySpec(Name.parsePath('foo')))!.lastUse,
            lastTick);
      });
    });

    test('has active default query', () {
      var manager = newManager();

      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);

      manager.setQueryActive(QuerySpec(Name.parsePath('bar')));
      manager.storageLayer.endTransaction();

      expect(manager.hasActiveDefaultQuery(Name.parsePath('foo')), false);
      expect(manager.hasActiveDefaultQuery(Name.parsePath('')), false);
      expect(manager.hasActiveDefaultQuery(Name.parsePath('bar')), true);
      expect(manager.hasActiveDefaultQuery(Name.parsePath('bar/baz')), true);
    });

    test('cache sanity check', () {
      var manager = newManager();

      manager.storageLayer.beginTransaction();
      manager.setQueryActive(sampleFooQuery);
      manager.setQueryActive(QuerySpec(Name.parsePath('foo')));
      manager.storageLayer.endTransaction();
      manager.verifyCache();

      manager.storageLayer.beginTransaction();
      manager.setQueryCompleteIfExists(sampleFooQuery);
      manager.storageLayer.endTransaction();
      manager.verifyCache();

      manager.storageLayer.beginTransaction();
      manager.setQueryInactive(QuerySpec(Name.parsePath('foo')));
      manager.storageLayer.endTransaction();
      manager.verifyCache();

      var manager2 = newManager();
      manager2.verifyCache();
    });
  });
}

TrackedQueryManager newManager() {
  var engine = HivePersistenceStorageEngine(
      KeyValueDatabase(Hive.box('firebase-db-storage')));
  return TrackedQueryManager(engine);
}

extension TrackedQueryManagerTestX on TrackedQueryManager {
  void verifyCache() {
    var storedTrackedQueries = storageLayer.loadTrackedQueries();

    final trackedQueries = <TrackedQuery>[
      ...trackedQueryTree.allNonNullValues.expand((v) => v.values)
    ];
    trackedQueries.sort((o1, o2) => Comparable.compare(o1.id, o2.id));

    expect(storedTrackedQueries, trackedQueries);
  }
}
