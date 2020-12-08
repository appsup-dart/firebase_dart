import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('SyncTree', () {
    group('Completeness on user operation', () {
      SyncTree syncTree;
      SyncPoint syncPoint;
      MasterView view;

      setUp(() {
        syncTree = SyncTree('mem:///', RemoteListenerRegistrar.fromCallbacks());

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
  });
}
