import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/event.dart';
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
    test('adopt observers', () {
      var p = SyncPoint('test', Path(),
          persistenceManager: FakePersistenceManager((path, filter) {
        if (filter.reversed) {
          return IncompleteData.complete(
              TreeStructuredData.fromJson('last value'));
        }
        return IncompleteData.empty();
      }));

      Event? event1, event2;
      p.addEventListener('value', QueryFilter(limit: 1), (event) {
        event1 = event;
      });
      p.addEventListener('value', QueryFilter(limit: 1, reversed: true),
          (event) {
        event2 = event;
      });

      expect(p.minimalSetOfQueries.length, 2);

      expect(p.views.length, 2);

      expect(event1, null);
      expect(event2, isNotNull);
    });

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

      test('Should merge queries with limit == null', () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 0; i < 10; i++) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                validInterval: KeyValueInterval(Name('key-${1000 + i * 10}'),
                    empty, Name('key-${1000 + (i + 1) * 10}'), empty),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            validInterval: KeyValueInterval(
                Name('key-1000'), empty, Name('key-1100'), empty),
          )
        ]);
      });

      test('Should not merge queries with non overlapping intervals', () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 0; i < 10; i++) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                validInterval: KeyValueInterval(Name('key-${1000 + i * 10}'),
                    empty, Name('key-${1000 + (i + 1) * 10}'), empty),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          for (var i = 0; i < 10; i += 2)
            QueryFilter(
              ordering: o,
              limit: 1,
              validInterval: KeyValueInterval(Name('key-${1000 + i * 10}'),
                  empty, Name('key-${1000 + (i + 1) * 10}'), empty),
            ),
        ]);
      });

      test(
          'should retain reverse ordered queries when data makes them non overlapping',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: FakePersistenceManager((path, filter) {
          var key =
              int.parse(filter.endKey!.asString().substring('key-'.length));

          return IncompleteData.complete(TreeStructuredData.fromJson({
            'key-${key - 5}': key,
          }));
        }));

        for (var i = 0; i < 10; i++) {
          var filter = QueryFilter(
            ordering: o,
            limit: 1,
            reversed: true,
            validInterval: KeyValueInterval(
                Name.min, empty, Name('key-${1000 + (i + 1) * 10}'), empty),
          );
          p.addEventListener('value', filter, (e) {});
        }

        expect(p.minimalSetOfQueries.length, 10);
      });

      test(
          'should retain non-reverse ordered queries when data makes them non overlapping',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: FakePersistenceManager((path, filter) {
          var key =
              int.parse(filter.startKey!.asString().substring('key-'.length));

          return IncompleteData.complete(TreeStructuredData.fromJson({
            'key-${key + 5}': key,
          }));
        }));

        for (var i = 0; i < 10; i++) {
          var filter = QueryFilter(
            ordering: o,
            limit: 1,
            validInterval: KeyValueInterval(
                Name('key-${1000 + i * 10}'), empty, Name.max, empty),
          );
          p.addEventListener('value', filter, (e) {});
        }

        expect(p.minimalSetOfQueries.length, 10);
      });

      test(
          'should use query with max end as master query for reverse ordered queries',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 0; i < 10; i++) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                reversed: true,
                validInterval: KeyValueInterval(
                    Name.min, empty, Name('key-${1000 + (i + 1) * 10}'), empty),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            limit: 1,
            reversed: true,
            validInterval:
                KeyValueInterval(Name.min, empty, Name('key-1100'), empty),
          )
        ]);
      });

      test(
          'should use query with min start as master query for non-reverse ordered queries',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 9; i >= 0; i--) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                validInterval: KeyValueInterval(
                    Name('key-${1000 + i * 10}'), empty, Name.max, empty),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            limit: 1,
            validInterval:
                KeyValueInterval(Name('key-1000'), empty, Name.max, empty),
          )
        ]);
      });

      test('Should combine all overlapping intervals', () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 0; i < 10; i++) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                validInterval: KeyValueInterval(Name('key-${1000 + i * 10}'),
                    empty, Name('key-${1000 + (i + 1) * 10}'), empty),
              ),
              (event) {});
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                validInterval: KeyValueInterval(
                    Name('key-${1000 + (i + 1) * 10}'), empty, null, null),
              ),
              (event) {});
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                reversed: true,
                validInterval: KeyValueInterval(
                    null, null, Name('key-${1000 + i * 10}'), empty),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            validInterval: KeyValueInterval(
                Name('key-1000'), empty, Name('key-1100'), empty),
          ),
        ]);

        p.applyOperation(
            TreeOperation.overwrite(Path(), TreeStructuredData()),
            QueryFilter(
              ordering: o,
              validInterval: KeyValueInterval(
                  Name('key-1000'), empty, Name('key-1100'), empty),
            ),
            ViewOperationSource.server,
            null);

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            validInterval: KeyValueInterval(
                Name('key-1000'), empty, Name('key-1100'), empty),
          ),
          QueryFilter(
            ordering: o,
            limit: 1,
            validInterval:
                KeyValueInterval(Name('key-1010'), empty, null, null),
          ),
          QueryFilter(
            ordering: o,
            limit: 1,
            reversed: true,
            validInterval:
                KeyValueInterval(null, null, Name('key-1090'), empty),
          ),
        ]);
      });

      test('Should contain when filter within complete interval', () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        for (var i = 0; i < 10; i++) {
          p.addEventListener(
              'value',
              QueryFilter(
                ordering: o,
                limit: 1,
                validInterval: KeyValueInterval(
                    Name('key-${1000 + i * 10}'), empty, null, null),
              ),
              (event) {});
        }

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            limit: 1,
            validInterval:
                KeyValueInterval(Name('key-1000'), empty, null, null),
          ),
        ]);

        p.applyOperation(
            TreeOperation.overwrite(Path(), TreeStructuredData()),
            QueryFilter(
              ordering: o,
              limit: 1,
              validInterval:
                  KeyValueInterval(Name('key-1000'), empty, null, null),
            ),
            ViewOperationSource.server,
            null);

        expect(p.minimalSetOfQueries, [
          QueryFilter(
            ordering: o,
            limit: 1,
            validInterval:
                KeyValueInterval(Name('key-1000'), empty, null, null),
          ),
        ]);
      });

      test(
          'Should not return const QueryFilter() when isCompleteFromParent is set to false',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        p.isCompleteFromParent = true;
        p.addEventListener('value', QueryFilter(limit: 1), (event) {});
        expect(p.minimalSetOfQueries, []);
        expect(p.views.keys, [const QueryFilter()]);

        p.isCompleteFromParent = false;
        expect(p.minimalSetOfQueries, [QueryFilter(limit: 1)]);
      });

      test(
          'Should not return empty list when isCompleteFromParent is set to true',
          () {
        var p = SyncPoint('test', Path(),
            persistenceManager: NoopPersistenceManager());

        p.addEventListener('value', QueryFilter(limit: 1), (event) {});
        expect(p.minimalSetOfQueries, [QueryFilter(limit: 1)]);
        expect(p.views.keys, [QueryFilter(limit: 1)]);

        p.isCompleteFromParent = true;
        expect(p.minimalSetOfQueries, []);
      });
    });
  });
}
