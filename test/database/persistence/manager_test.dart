import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

import 'mock.dart';

void main() {
  var defaultFooQuery = QuerySpec(Name.parsePath('foo'));

  var limit3FooQuery =
      QuerySpec(Name.parsePath('foo'), QueryFilter(limit: 3, reversed: true));

  group('PersistenceManager', () {
    test('server cache filters results 1', () {
      var manager = newTestPersistenceManager();

      manager.updateServerCache(TreeOperation.overwrite(
          Name.parsePath('foo/bar'), TreeStructuredData.fromJson('1')));
      manager.updateServerCache(TreeOperation.overwrite(
          Name.parsePath('foo/baz'), TreeStructuredData.fromJson('2')));
      manager.updateServerCache(TreeOperation.overwrite(
          Name.parsePath('foo/quu/1'), TreeStructuredData.fromJson('3')));
      manager.updateServerCache(TreeOperation.overwrite(
          Name.parsePath('foo/quu/2'), TreeStructuredData.fromJson('4')));

      var cache = manager.serverCache(Name.parsePath('foo'));
      expect(cache.completeValue, null);
    });

    test('server cache filters results 2', () {
      var manager = newTestPersistenceManager();

      manager.setQueryActive(limit3FooQuery.path, limit3FooQuery.params);
      manager.updateServerCache(TreeOperation.overwrite(Name.parsePath('foo'),
          TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3, 'd': 4})));
      var cache =
          manager.serverCache(Name.parsePath('foo'), limit3FooQuery.params);
      expect(cache.completeValue,
          TreeStructuredData.fromJson({'b': 2, 'c': 3, 'd': 4}));
    });

    test('server cache filters results 3', () {
      var manager = newTestPersistenceManager();

      manager.setQueryActive(limit3FooQuery.path, limit3FooQuery.params);
      manager.updateServerCache(
          TreeOperation.overwrite(Name.parsePath('foo'),
              TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3})),
          limit3FooQuery.params);
      var cache =
          manager.serverCache(Name.parsePath('foo'), limit3FooQuery.params);
      expect(cache.completeValue,
          TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3}));
    });

    test('server cache filters results 4', () {
      var manager = newTestPersistenceManager();

      manager.setQueryActive(limit3FooQuery.path, limit3FooQuery.params);
      manager.updateServerCache(
          TreeOperation.overwrite(Name.parsePath('foo'),
              TreeStructuredData.fromJson({'a': 1, 'b': 2, 'c': 3})),
          limit3FooQuery.params);
      var cache = manager.serverCache(
          Name.parsePath('foo'), QueryFilter(limit: 2, reversed: true));
      expect(
          cache.completeValue, TreeStructuredData.fromJson({'b': 2, 'c': 3}));
    });

    test('no limit non default query is treated as default query', () {
      var manager = newTestPersistenceManager();

      manager.setQueryActive(defaultFooQuery.path, defaultFooQuery.params);
      var data = TreeStructuredData.fromJson({'foo': 1, 'bar': 2});
      manager.updateServerCache(
          TreeOperation.overwrite(defaultFooQuery.path, data));
      manager.setQueryComplete(defaultFooQuery.path, defaultFooQuery.params);

      var index = TreeStructuredDataOrdering.byChild('index-key');
      var node = manager.serverCache(
          Name.parsePath('foo'), QueryFilter(ordering: index));
      expect(node.completeValue, data);
      expect(node.filter, QueryFilter(ordering: index));
    });
  });
}

PersistenceManager newTestPersistenceManager() {
  var engine = MockPersistenceStorageEngine();
  engine.disableTransactionCheck = true;
  return DefaultPersistenceManager(engine, CachePolicy.none);
}
