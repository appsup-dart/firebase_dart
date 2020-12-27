import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/view.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

void main() {
  var empty = TreeStructuredData();
  group('MasterView', () {
    group('MasterView.contains', () {
      var o = TreeStructuredDataOrdering.byKey();
      test('Should contain every filter when loads all data', () {
        var view = MasterView(QueryFilter(ordering: o));

        expect(view.contains(QueryFilter(ordering: o, limit: 5)), true);
        expect(
            view.contains(QueryFilter(ordering: o, limit: 5, reversed: true)),
            true);

        var i = KeyValueInterval('key-001', empty, 'key-100', empty);
        expect(view.contains(QueryFilter(ordering: o, validInterval: i)), true);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: i, limit: 3)),
            true);
      });
      test(
          'Should contain every filter with validInterval within validInterval of master query loading all data',
          () {
        var i = KeyValueInterval('key-001', empty, 'key-100', empty);
        var view = MasterView(QueryFilter(ordering: o, validInterval: i));

        expect(view.contains(QueryFilter(ordering: o, limit: 5)), false);
        expect(
            view.contains(QueryFilter(ordering: o, limit: 5, reversed: true)),
            false);

        var j = KeyValueInterval('key-010', empty, 'key-090', empty);
        expect(view.contains(QueryFilter(ordering: o, validInterval: j)), true);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 3)),
            true);
      });

      test(
          'Should not contain when validInterval is not contained and does not limit',
          () {
        var i = KeyValueInterval('key-001', empty, 'key-100', empty);
        var view = MasterView(QueryFilter(ordering: o, validInterval: i));

        var j = KeyValueInterval('key-050', null, 'key-300', null);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j)), false);
      });

      test('Might be contained when validInterval is not contained and limits',
          () {
        var i =
            KeyValueInterval(Name('key-001'), empty, Name('key-100'), empty);
        var view = MasterView(QueryFilter(ordering: o, validInterval: i));

        var j =
            KeyValueInterval(Name('key-002'), empty, Name('key-300'), empty);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 3)),
            true);

        view.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-001': 1,
                  'key-002': 2,
                  'key-003': 3,
                  'key-004': 4,
                  'key-005': 5,
                })),
            ViewOperationSource.server,
            null);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 4)),
            true);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 8)),
            false);
      });

      test('Might be contained when master query limits', () {
        var i =
            KeyValueInterval(Name('key-001'), empty, Name('key-100'), empty);
        var view =
            MasterView(QueryFilter(ordering: o, validInterval: i, limit: 3));

        var j =
            KeyValueInterval(Name('key-002'), empty, Name('key-050'), empty);
        expect(view.contains(QueryFilter(ordering: o, validInterval: j)), true);

        view.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-001': 1,
                  'key-002': 2,
                })),
            ViewOperationSource.server,
            null);
        expect(view.contains(QueryFilter(ordering: o, validInterval: j)), true);
        view.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-001': 1,
                  'key-002': 2,
                  'key-003': 3,
                })),
            ViewOperationSource.server,
            null);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j)), false);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 8)),
            false);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 2)),
            true);
      });
      test(
          'Might be contained when master query limits and interval is not contained',
          () {
        var i =
            KeyValueInterval(Name('key-001'), empty, Name('key-100'), empty);
        var view =
            MasterView(QueryFilter(ordering: o, validInterval: i, limit: 3));

        var j =
            KeyValueInterval(Name('key-002'), empty, Name('key-200'), empty);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 3)),
            true);

        view.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-002': 2,
                  'key-003': 3,
                  'key-004': 4,
                })),
            ViewOperationSource.server,
            null);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 3)),
            true);
        view.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-001': 1,
                  'key-002': 2,
                  'key-003': 3,
                })),
            ViewOperationSource.server,
            null);
        print(j.containsPoint(
            o.mapKeyValue(Name('key-001'), TreeStructuredData.fromJson(1))));
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 3)),
            false);
        expect(
            view.contains(QueryFilter(ordering: o, validInterval: j, limit: 2)),
            true);
      });
    });
  });
  group('SyncPoint', () {
    group('SyncPoint.minimalSetOfQueries', () {
      var i = KeyValueInterval(Name('key-001'), empty, Name('key-100'), empty);
      var o = TreeStructuredDataOrdering.byKey();

      test('Should wait for data to decide', () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());
        p.addEventListener('value',
            QueryFilter(ordering: o, validInterval: i, limit: 3), (event) {});

        var j =
            KeyValueInterval(Name('key-002'), empty, Name('key-300'), empty);
        p.addEventListener('value',
            QueryFilter(ordering: o, validInterval: j, limit: 3), (event) {});

        expect(p.minimalSetOfQueries,
            [QueryFilter(ordering: o, validInterval: i, limit: 3)]);

        p.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-002': 2,
                  'key-003': 3,
                  'key-004': 4,
                })),
            QueryFilter(ordering: o, validInterval: i, limit: 3),
            ViewOperationSource.server,
            null);

        expect(p.minimalSetOfQueries,
            [QueryFilter(ordering: o, validInterval: i, limit: 3)]);

        p.applyOperation(
            TreeOperation.overwrite(
                Path(),
                TreeStructuredData.fromJson({
                  'key-001': 1,
                  'key-003': 3,
                  'key-004': 4,
                })),
            QueryFilter(ordering: o, validInterval: i, limit: 3),
            ViewOperationSource.server,
            null);

        expect(p.minimalSetOfQueries, [
          QueryFilter(ordering: o, validInterval: i, limit: 3),
          QueryFilter(ordering: o, validInterval: j, limit: 3)
        ]);
      });
    });
  });
}
