import 'dart:async';

import 'package:collection/collection.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteListenerRegistrar', () {
    test('RemoteListenerRegistrar should register and unregister in order',
        () async {
      var c = StreamController();
      var registrar = RemoteListenerRegistrar.fromCallbacks(
          NoopPersistenceManager(), remoteRegister: (path, filter, hash) async {
        c.add('register');
      }, remoteUnregister: (path, filter) async {
        c.add('unregister');
      });

      var l = c.stream.take(3).toList();

      registrar.registerAll(Name.parsePath('/test'), [QueryFilter()],
          (filter) => filter.hashCode.toString());
      registrar.registerAll(
          Name.parsePath('/test'), [], (filter) => filter.hashCode.toString());
      registrar.registerAll(Name.parsePath('/test'), [QueryFilter()],
          (filter) => filter.hashCode.toString());

      expect(await l, ['register', 'unregister', 'register']);
    });
  });
  group('SyncTree', () {
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
            query1);
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
            QueryFilter());
        for (var i = 0; i < 10; i++) {
          syncTree.applyServerOperation(
              TreeOperation.overwrite(Name.parsePath('main/$i/valueX2'),
                  TreeStructuredData.fromJson(i)),
              QueryFilter());
        }

        print(
            'obsolete TreeStructuredData instances = ${syncTree.obsoleteTreeStructuredDataInstanceCount}');

        expect(syncTree.obsoleteTreeStructuredDataInstanceCount, 0,
            skip: 'TODO improve reuse of instances');
      });
    });
  });
}

extension SyncTreeMeasurer on SyncTree {
  int get obsoleteTreeStructuredDataInstanceCount {
    var root = TreeNode<Name, Set<TreeStructuredData>>(
        EqualitySet(IdentityEquality()));

    void handleOperation(
        TreeNode<Name, Set<TreeStructuredData>> tree, Operation? operation) {
      if (operation is TreeOperation) {
        handleOperation(
            tree.subtree(operation.path,
                (parent, name) => TreeNode(EqualitySet(IdentityEquality()))),
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
          key, (parent, name) => TreeNode(EqualitySet(IdentityEquality())));
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
