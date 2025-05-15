import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/events/value.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

class LoggingQueryRegistrar extends QueryRegistrar {
  final StreamController<String> controller = StreamController();

  @override
  Future<bool> register(QuerySpec query,
      {String? hash, required int priority}) async {
    controller.add('register');
    return true;
  }

  @override
  Future<void> unregister(QuerySpec query) async {
    controller.add('unregister');
  }

  Stream<String> get onEvent => controller.stream;

  @override
  Future<void> close() async {
    await controller.close();
  }
}

void main() {
  group('RemoteListenerRegistrar', () {
    test('RemoteListenerRegistrar should register and unregister in order',
        () async {
      var logger = LoggingQueryRegistrar();
      var registrar = QueryRegistrarTree(SequentialQueryRegistrar(logger));

      var l = logger.onEvent.take(3).toList();

      registrar.setActiveQueriesOnPath(Name.parsePath('/test'), [QueryFilter()],
          hashFcn: (filter) => filter.hashCode.toString(),
          priorityFcn: (filter) => 0,
          onRegistered: (filter) {});
      await Future.microtask(() {});
      registrar.setActiveQueriesOnPath(Name.parsePath('/test'), [],
          hashFcn: (filter) => filter.hashCode.toString(),
          priorityFcn: (filter) => 0,
          onRegistered: (filter) {});
      await Future.microtask(() {});
      registrar.setActiveQueriesOnPath(Name.parsePath('/test'), [QueryFilter()],
          hashFcn: (filter) => filter.hashCode.toString(),
          priorityFcn: (filter) => 0,
          onRegistered: (filter) {});

      expect(await l, ['register', 'unregister', 'register']);
    });
  });
  group('SyncTree', () {
    test('Upgraded query should also serve new queries', () {
      var syncTree = SyncTree('mem:///', queryRegistrar: _Registrar());

      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test/child'),
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
          (event) {});

      syncTree.handleInvalidPaths();
      syncTree.applyServerOperation(
          TreeOperation.overwrite(Name.parsePath('/test/child'),
              TreeStructuredData.fromJson({'a': 1})),
          QuerySpec(
            Name.parsePath('/test/child'),
            QueryFilter(
                ordering: TreeStructuredDataOrdering.byChild('order'),
                limit: 1),
          ));
      syncTree.applyUpgrade(
        Name.parsePath('/test/child'),
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
      );
      var point =
          syncTree.root.children[Name('test')]!.children[Name('child')]!.value;
      expect(
          point.views.keys.single,
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1));

      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test/child'),
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 2),
          (event) {});

      syncTree.handleInvalidPaths();
      expect(point.views.keys, [
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1)
      ]);
    }, skip: 'not working yet, would improve performance');
    test('Upgraded query should continue to serve queries', () {
      var syncTree = SyncTree('mem:///', queryRegistrar: _Registrar());

      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test/child'),
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
          (event) {});
      syncTree.handleInvalidPaths();
      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test/child'),
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 2),
          (event) {});
      syncTree.handleInvalidPaths();
      var point =
          syncTree.root.children[Name('test')]!.children[Name('child')]!.value;

      syncTree.applyServerOperation(
          TreeOperation.overwrite(Name.parsePath('/test/child'),
              TreeStructuredData.fromJson({'a': 1})),
          QuerySpec(
            Name.parsePath('/test/child'),
            QueryFilter(
                ordering: TreeStructuredDataOrdering.byChild('order'),
                limit: 1),
          ));
      syncTree.applyUpgrade(
        Name.parsePath('/test/child'),
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
      );
      expect(
          point.views.keys.single,
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1));

      syncTree.applyServerOperation(
          TreeOperation.overwrite(Name.parsePath('/test/child'),
              TreeStructuredData.fromJson({'b': 1})),
          QuerySpec(
            Name.parsePath('/test/child'),
            QueryFilter(
                ordering: TreeStructuredDataOrdering.byChild('order'),
                limit: 1),
          ));
      syncTree.handleInvalidPaths();

      expect(point.views.keys, [
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1)
      ]);
    }, skip: 'not working yet, would improve performance');
    test(
        'Null check operator used on a null value, when reconnecting with a query that gets upgraded',
        () {
      var syncTree = SyncTree('mem:///', queryRegistrar: _Registrar());

      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test/child'),
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
          (event) {});
      var point =
          syncTree.root.children[Name('test')]!.children[Name('child')]!.value;
      syncTree.handleInvalidPaths();
      syncTree.applyServerOperation(
          TreeOperation.overwrite(
              Name.parsePath('/test/child'), TreeStructuredData()),
          QuerySpec(
            Name.parsePath('/test/child'),
            QueryFilter(
                ordering: TreeStructuredDataOrdering.byChild('order'),
                limit: 1),
          ));
      syncTree.applyUpgrade(
        Name.parsePath('/test/child'),
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
      );

      expect(point.isCompleteFromParent, false);
      expect(
          point.views.keys.single,
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1));

      syncTree.addEventListener(
          'cancel',
          Name.parsePath('/test'),
          QueryFilter(ordering: TreeStructuredDataOrdering.byKey(), limit: 1),
          (event) {});
      syncTree.handleInvalidPaths();
      expect(point.isCompleteFromParent,
          false); // when the listeners are registered in opposite order, this would be true. Should it be true in this case as well?
      expect(
          point.views.keys.single,
          QueryFilter(
              ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1));

      syncTree.applyServerOperation(
          TreeOperation.overwrite(
              Name.parsePath('/test'), TreeStructuredData()),
          QuerySpec(
            Name.parsePath('/test'),
            QueryFilter(ordering: TreeStructuredDataOrdering.byKey(), limit: 1),
          ));
      expect(point.isCompleteFromParent, true);
      expect(point.views.keys, [
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
        QueryFilter(),
      ]);

      // when a connection is lost and re-established, the apply upgrade will be called again
      syncTree.applyUpgrade(
        Name.parsePath('/test/child'),
        QueryFilter(
            ordering: TreeStructuredDataOrdering.byChild('order'), limit: 1),
      );
      expect(point.isCompleteFromParent, true);
      expect(point.views.keys,
          contains(QueryFilter())); // this should not remove the main query

      syncTree.applyServerOperation(
          TreeOperation.overwrite(
              Name.parsePath('/test'), TreeStructuredData.fromJson({'a': 1})),
          QuerySpec(
            Name.parsePath('/test'),
            QueryFilter(ordering: TreeStructuredDataOrdering.byKey(), limit: 1),
          ));
    });

    test('Previously complete query should not notify new targets', () async {
      var syncTree = SyncTree('mem:///', queryRegistrar: _Registrar());

      var path = Name.parsePath('child1');
      var query1 = QueryFilter().copyWith(orderBy: '.key', limit: 1);
      var query2 =
          QueryFilter().copyWith(orderBy: '.key', endAtKey: Name('some-key'));

      TreeStructuredData? value1, value2, value2bis;
      await syncTree.addEventListener('value', path, query1, (v) {
        value1 = (v as ValueEvent<TreeStructuredData>).value;
      });
      syncTree.applyServerOperation(
          TreeOperation.overwrite(path, TreeStructuredData()),
          QuerySpec(path, query1));
      await Future.delayed(Duration(milliseconds: 10));
      expect(value1, TreeStructuredData());
      await syncTree.addEventListener('value', path, query2, (v) {
        value2 = (v as ValueEvent<TreeStructuredData>).value;
      });
      await Future.delayed(Duration(milliseconds: 10));
      expect(value2,
          TreeStructuredData()); // query2 is complete, because query1 was empty

      syncTree.applyServerOperation(
          TreeOperation.overwrite(
              path, TreeStructuredData.fromJson({'key-1': 'value-1'})),
          QuerySpec(path, query1));
      await Future.delayed(Duration(milliseconds: 10));

      expect(value1, TreeStructuredData.fromExportJson({'key-1': 'value-1'}));
      expect(value2,
          TreeStructuredData()); // query2 is no longer complete, so should still have the same value as before

      await syncTree.addEventListener('value', path, query2, (v) {
        value2bis = (v as ValueEvent<TreeStructuredData>).value;
      });
      await Future.delayed(Duration(milliseconds: 10));
      expect(value2bis,
          null); // query2 is not complete, so new registrations should not get a value
    });
    group('Completeness on user operation', () {
      late SyncTree syncTree;
      SyncPoint syncPoint;
      late MasterView view;

      setUp(() {
        syncTree = SyncTree('mem:///');

        var query1 = QueryFilter().copyWith(orderBy: '.key', limit: 1);
        syncTree.addEventListener('value', Path(), query1, (event) {});

        syncPoint = syncTree.root.value;

        expect(syncPoint, isNotNull);
        expect(syncPoint.views.length, 1);

        view = syncPoint.views.values.first;
        expect(view.masterFilter, query1);

        syncTree.applyServerOperation(
            TreeOperation(
                Path(),
                Overwrite(
                  TreeStructuredData.fromJson({'key-1': 'value-1'}),
                )),
            QuerySpec(Path(), query1));
        expect(view.data.serverVersion.isComplete, true);
        expect(view.data.localVersion.isComplete, true);
      });

      test('Removing a child from a limited view should make it incomplete',
          () {
        syncTree.applyUserOverwrite(
            Name.parsePath('key-1'), TreeStructuredData(), 0);

        expect(view.data.serverVersion.isComplete, true);
        expect(view.data.localVersion.isComplete, false);
      });
      test(
          'Adding a complete child from a limited view should not make it incomplete',
          () {
        syncTree.applyUserOverwrite(
            Name.parsePath('key-2'), TreeStructuredData.fromJson('value-2'), 0);

        expect(view.data.serverVersion.isComplete, true);
        expect(view.data.localVersion.isComplete, true);

        expect(
            view.data.localVersion.isCompleteForPath(Name.parsePath('key-2')),
            true);
      });
      test('Adding a sub child from a limited view should make it incomplete',
          () {
        syncTree.applyUserOverwrite(Name.parsePath('key-0/subkey'),
            TreeStructuredData.fromJson('value-2'), 0);

        expect(view.data.serverVersion.isComplete, true);
        expect(view.data.localVersion.isComplete, false);

        expect(
            view.data.localVersion.isCompleteForPath(Name.parsePath('key-0')),
            false);
      });
    }, skip: 'Completeness on user operation is not handled correctly yet');

    group('Performance measures', () {
      test('Obsolete TreeStrucutedData instances', () {
        var syncTree =
            SyncTree('test:///', persistenceManager: NoopPersistenceManager());

        syncTree.addEventListener(
            'value', Name.parsePath('main'), QueryFilter(), (event) {});
        for (var i = 0; i < 10; i++) {
          syncTree.addEventListener(
              'value', Name.parsePath('main/$i'), QueryFilter(), (event) {});
        }
        syncTree.applyServerOperation(
            TreeOperation.overwrite(
                Name.parsePath('main'),
                TreeStructuredData.fromJson({
                  for (var i = 0; i < 10; i++) '$i': {'value': i},
                })),
            QuerySpec(Name.parsePath('main')));
        for (var i = 0; i < 10; i++) {
          syncTree.applyServerOperation(
              TreeOperation.overwrite(Name.parsePath('main/$i/valueX2'),
                  TreeStructuredData.fromJson(i)),
              QuerySpec(Name.parsePath('main/$i/valueX2')));
        }

        print(
            'obsolete TreeStructuredData instances = ${syncTree.obsoleteTreeStructuredDataInstanceCount}');

        expect(syncTree.obsoleteTreeStructuredDataInstanceCount, 0,
            skip: 'TODO improve reuse of instances');
      });
    });

    group('delayed unlisten', () {
      test('when keepQueriesSyncedDuration = 2 seconds', () {
        fakeAsync((async) {
          Repo.updateDatabaseConfiguration(
              keepQueriesSyncedDuration: Duration(seconds: 2));
          var logger = LoggingQueryRegistrar();

          String? lastEvent;
          logger.onEvent.listen((v) {
            lastEvent = v;
          });
          var syncTree = SyncTree('mem:///', queryRegistrar: logger);

          void listener(event) {}
          syncTree.addEventListener(
              'value', Name.parsePath('test'), QueryFilter(), listener);

          async.elapse(Duration(milliseconds: 100));
          expect(lastEvent, 'register');

          syncTree.removeEventListener(
              'value', Name.parsePath('test'), QueryFilter(), listener);
          async.elapse(Duration(milliseconds: 100));
          expect(lastEvent, 'register');

          async.elapse(Duration(seconds: 2));
          expect(lastEvent, 'unregister');
        });
      });

      test('when keepQueriesSyncedDuration = 2 hours', () {
        fakeAsync((async) {
          Repo.updateDatabaseConfiguration(
              keepQueriesSyncedDuration: Duration(hours: 2));
          var logger = LoggingQueryRegistrar();

          String? lastEvent;
          logger.onEvent.listen((v) {
            lastEvent = v;
          });
          var syncTree = SyncTree('mem:///', queryRegistrar: logger);

          void listener(event) {}
          syncTree.addEventListener(
              'value', Name.parsePath('test'), QueryFilter(), listener);

          async.elapse(Duration(milliseconds: 100));
          expect(lastEvent, 'register');

          syncTree.removeEventListener(
              'value', Name.parsePath('test'), QueryFilter(), listener);
          async.elapse(Duration(milliseconds: 100));
          expect(lastEvent, 'register');

          async.elapse(Duration(seconds: 2));
          expect(lastEvent, 'register');

          async.elapse(Duration(hours: 2));
          expect(lastEvent, 'unregister');
        });
      });
    });
  });
}

extension SyncTreeMeasurer on SyncTree {
  int get obsoleteTreeStructuredDataInstanceCount {
    var root = ModifiableTreeNode<Name, Set<TreeStructuredData>>(
        EqualitySet(IdentityEquality()));

    void handleOperation(ModifiableTreeNode<Name, Set<TreeStructuredData>> tree,
        Operation? operation) {
      if (operation is TreeOperation) {
        handleOperation(
            tree.subtree(
                operation.path,
                (parent, name) =>
                    ModifiableTreeNode(EqualitySet(IdentityEquality()))),
            operation.nodeOperation);
      } else if (operation is Overwrite) {
        var set = tree.value;
        set.add(operation.value);
        operation.value.children.forEach((key, value) {
          handleOperation(
              tree, TreeOperation.overwrite(Path.from([key]), value));
        });
      } else if (operation is Merge) {
        for (var o in operation.overwrites) {
          handleOperation(tree, o);
        }
      }
    }

    this.root.forEachNode((key, value) {
      var tree = root.subtree(
          key,
          (parent, name) =>
              ModifiableTreeNode(EqualitySet(IdentityEquality())));
      for (var view in value.views.values) {
        for (var data in [view.data.localVersion, view.data.serverVersion]) {
          var op = data.toOperation();
          handleOperation(tree, op);
        }
      }
    });

    var obsoleteCount = 0;
    root.forEachNode((key, value) {
      value.removeWhere((element) => element == TreeStructuredData());

      obsoleteCount += value.length - Set.from(value).length;
    });

    return obsoleteCount;
  }
}

class _Registrar extends QueryRegistrar {
  final Map<QuerySpec, Completer<bool>> _pendingRegistrations = {};

  @override
  Future<void> close() async {}

  @override
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority}) {
    return (_pendingRegistrations[query] ??= Completer<bool>()).future;
  }

  @override
  Future<void> unregister(QuerySpec query) {
    return Completer<bool>().future;
  }

  Future<void> completeRegistration(QuerySpec query) {
    var completer = _pendingRegistrations.remove(query);
    if (completer != null) {
      completer.complete(true);
    }
    return Future.value();
  }
}
