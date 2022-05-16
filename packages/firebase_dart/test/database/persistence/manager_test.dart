import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() async {
  await Hive.openBox('firebase-db-storage', bytes: Uint8List(0));

  var defaultFooQuery = QuerySpec(Name.parsePath('foo'));

  var limit3FooQuery =
      QuerySpec(Name.parsePath('foo'), QueryFilter(limit: 3, reversed: true));

  group('PersistenceManager', () {
    test('server cache filters results 1', () {
      var manager = newTestPersistenceManager();

      manager.runInTransaction(() {
        manager.updateServerCache(
            QuerySpec(Name.parsePath('foo/bar')),
            TreeOperation.overwrite(
                Name.parsePath('foo/bar'), TreeStructuredData.fromJson('1')));
        manager.updateServerCache(
            QuerySpec(Name.parsePath('foo/baz')),
            TreeOperation.overwrite(
                Name.parsePath('foo/baz'), TreeStructuredData.fromJson('2')));
        manager.updateServerCache(
            QuerySpec(Name.parsePath('foo/quu/1')),
            TreeOperation.overwrite(
                Name.parsePath('foo/quu/1'), TreeStructuredData.fromJson('3')));
        manager.updateServerCache(
            QuerySpec(Name.parsePath('foo/quu/2')),
            TreeOperation.overwrite(
                Name.parsePath('foo/quu/2'), TreeStructuredData.fromJson('4')));
      });

      var cache = manager.serverCache(QuerySpec(Name.parsePath('foo')));
      expect(cache.completeValue, null);
    });

    test('server cache filters results 2', () {
      var manager = newTestPersistenceManager();

      manager.runInTransaction(() {
        manager.setQueryActive(limit3FooQuery);
        manager.updateServerCache(
            QuerySpec(Name.parsePath('foo')),
            TreeOperation.overwrite(Name.parsePath('foo'),
                TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3, 'd': 4})));
      });

      var cache = manager.serverCache(limit3FooQuery);
      expect(cache.completeValue,
          TreeStructuredData.fromJson({'b': 2, 'c': 3, 'd': 4}));
    });

    test('server cache filters results 3', () {
      var manager = newTestPersistenceManager();

      manager.runInTransaction(() {
        manager.setQueryActive(limit3FooQuery);
        manager.updateServerCache(
            limit3FooQuery,
            TreeOperation.overwrite(Name.parsePath('foo'),
                TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3})));
      });

      var cache = manager.serverCache(limit3FooQuery);
      expect(cache.completeValue,
          TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3}));
    });

    test('server cache filters results 4', () {
      var manager = newTestPersistenceManager();

      manager.runInTransaction(() {
        manager.setQueryActive(limit3FooQuery);
        manager.updateServerCache(
            limit3FooQuery,
            TreeOperation.overwrite(Name.parsePath('foo'),
                TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3})));
      });

      var cache = manager.serverCache(QuerySpec(
          Name.parsePath('foo'), QueryFilter(limit: 2, reversed: true)));
      expect(
          cache.completeValue, TreeStructuredData.fromJson({'b': 2, 'c': 3}));
    });

    test('no limit non default query is treated as default query', () {
      var manager = newTestPersistenceManager();

      var data = TreeStructuredData.fromJson({'foo': 1, 'bar': 2});
      manager.runInTransaction(() {
        manager.setQueryActive(defaultFooQuery);
        manager.updateServerCache(defaultFooQuery,
            TreeOperation.overwrite(defaultFooQuery.path, data));
        manager.setQueryComplete(defaultFooQuery);
      });
      var index = TreeStructuredDataOrdering.byChild('index-key');
      var node = manager.serverCache(
          QuerySpec(Name.parsePath('foo'), QueryFilter(ordering: index)));
      expect(node.completeValue, data);
      expect(node.filter, QueryFilter(ordering: index));
    });
  });
}

PersistenceManager newTestPersistenceManager() {
  var engine = HivePersistenceStorageEngine(
      KeyValueDatabase(Hive.box('firebase-db-storage')..clear()));
  return DefaultPersistenceManager(engine, CachePolicy.none);
}
