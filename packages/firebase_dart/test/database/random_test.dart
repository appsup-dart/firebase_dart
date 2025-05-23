import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/synctree_recorder.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'src/random_synctree_tester.dart';

void main() async {
  await Hive.openBox('firebase-db-storage', bytes: Uint8List(0));

  hierarchicalLoggingEnabled = true;
  RandomSyncTreeRecordingGenerator.logger
    ..level = Level.INFO
    ..onRecord.listen(print);

  group('Random synctree test', () {
    test('Random synctree test seed=1607344606058', () {
      _doTest(1607344606058);
    });
    test('Random synctree test seed=1607288421899', () {
      _doTest(1607288421899);
    });
    test('Random synctree test seed=1607205701181', () {
      _doTest(1607205701181);
    });
    test('Random synctree test seed=1607288421899', () {
      _doTest(1607288421899);
    });
    test('Random synctree test seed=1611229547900', () {
      _doTest(1611229547900);
    });
    test('Random synctree test seed=1725739105606', () {
      _doTest(1725739105606);
    });
    test('Random synctree test seed=1724925689256', () {
      _doTest(1724925689256);
    });
    test('Random synctree test seed=1738855293545', () {
      _doTest(1738855293545);
    });
    test('Random synctree test seed=1738919743671', () {
      _doTest(1738919743671);
    });
    test('Random synctree test seed=1747121950733', () {
      _doTest(1747121950733);
    });
    test('Random synctree test seed=1747659799315', () {
      _doTest(1747659799315);
    });

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null, minimize: false);
      }
    });
  });

  group('minimized tests', () {
    test('user operations should be added to newly created views', () {
      var path = Path.from([Name('index-key')]);
      var querySpec = QuerySpec(path, QueryFilter(limit: 1));
      var treeOperation =
          TreeOperation(path, Overwrite(TreeStructuredData.fromJson(0)));
      var treeOperation2 = TreeOperation(
          Path.from([]), Overwrite(TreeStructuredData.fromJson(0)));
      var querySpec2 = QuerySpec(Path.from([]), QueryFilter());
      var recording = SyncTreeRecording(events: [
        SyncTreeOperation.listen(querySpec, 'cancel', 1),
        SyncTreeOperation.ackListen(querySpec),
        SyncTreeOperation.operation(treeOperation, 1),
        SyncTreeOperation.ackWrite(path, 1),
        SyncTreeOperation.operation(treeOperation2, 2),
        SyncTreeOperation.listen(querySpec2, 'cancel', 2),
        SyncTreeOperation.ackListen(querySpec2),
      ]);
      fakeAsync((async) => recording.replay(async, usePersistence: true));
    });
    test(
        'should not consider server version complete when local version complete',
        () {
      var querySpec = QuerySpec(
          Path.from([]),
          QueryFilter(
            ordering: KeyOrdering(),
            limit: 1,
          ));
      var querySpec2 = QuerySpec(Path.from([Name('key-1')]), QueryFilter());
      var recording = SyncTreeRecording(events: [
        SyncTreeOperation.listen(querySpec, 'cancel', 1),
        SyncTreeOperation.ackListen(querySpec),
        SyncTreeOperation.serverOperation(
            TreeOperation(
                Path.from([]),
                Overwrite(TreeStructuredData.fromJson({
                  'key-1': 0,
                  'key-0': 0,
                }))),
            QuerySpec(Path.from([]))),

        // following operation makes the MasterView.isCompleteForChild('key-1') true, but the server version is incomplete,
        // so the newly created ViewCache for query 2 should still have an incomplete server version
        SyncTreeOperation.operation(
            TreeOperation(
                Path.from([]), Overwrite(TreeStructuredData.fromJson(0))),
            1),
        SyncTreeOperation.listen(querySpec2, 'cancel', 2),
      ]);
      fakeAsync((async) => recording.replay(async, usePersistence: true));
    });
    test('should contain priority when not limits', () {
      var querySpec = QuerySpec(Path.from([]), QueryFilter(limit: 1));
      var treeOperation = TreeOperation(
          Path.from([]),
          Overwrite(TreeStructuredData.fromJson({
            'key-1': false,
          })));

      var querySpec2 = QuerySpec(Path.from([]), QueryFilter(limit: 10));

      var treeOperation2 = TreeOperation(
          Path.from([]),
          Overwrite(
              TreeStructuredData.fromJson({'.priority': 1, '.value': true})));
      var querySpec3 = QuerySpec(Path.from([]), QueryFilter());

      var treeOperation3 = TreeOperation(
          Path.from([]),
          Overwrite(TreeStructuredData.fromJson({
            '.priority': 2,
            'key-1': false,
          })));
      var recording = SyncTreeRecording(events: [
        SyncTreeOperation.listen(querySpec, 'cancel', 1),
        SyncTreeOperation.ackListen(querySpec),
        SyncTreeOperation.serverOperation(
            treeOperation, QuerySpec(Path.from([]))),
        SyncTreeOperation.listen(querySpec2, 'cancel', 2),
        SyncTreeOperation.ackListen(querySpec2),
        SyncTreeOperation.serverOperation(
            treeOperation2, QuerySpec(Path.from([]))),
        SyncTreeOperation.listen(querySpec3, 'cancel', 3),
        SyncTreeOperation.operation(treeOperation3, 1),
      ]);

      fakeAsync((async) => recording.replay(async, usePersistence: true));
    });
  });

  group('persistence storage', () {
    test('should remove obscured data from storage', () {
      var treeOperation1 = TreeOperation(Path.from([]),
          Overwrite(TreeStructuredData.fromJson({'key-1': false})));

      var querySpec = QuerySpec(Path.from([]), QueryFilter(limit: 2));
      var treeOperation2 = TreeOperation(Path.from([]),
          Overwrite(TreeStructuredData.fromJson({'key-2': false})));

      var recording = SyncTreeRecording(events: [
        SyncTreeOperation.serverOperation(
            treeOperation1, QuerySpec(Path.from([]))),
        SyncTreeOperation.listen(querySpec, 'cancel', 1),
        SyncTreeOperation.ackListen(querySpec),
        SyncTreeOperation.serverOperation(
            treeOperation2, QuerySpec(Path.from([]))),
      ]);

      fakeAsync((async) => recording.replay(async, usePersistence: true));
    });

    test('a limiting query should not be handled as complete', () {
      // this query will contain all children - it has a limit larger than the number of children
      // and an unlimiting valid interval - but we cannot consider it complete as it might have a
      // priority which is not returned by a limiting query
      var querySpec = QuerySpec(Path.from([]), QueryFilter(limit: 30));

      var treeOperation = TreeOperation(
          Path.from([]),
          Overwrite(TreeStructuredData.fromJson({
            '.priority': 1,
            'key-1': 2,
          })));
      var recording = SyncTreeRecording(events: [
        SyncTreeOperation.listen(querySpec, 'cancel', 1),
        SyncTreeOperation.ackListen(querySpec),
        SyncTreeOperation.serverOperation(
            treeOperation, QuerySpec(Path.from([]))),
      ]);

      fakeAsync((async) => recording.replay(async, usePersistence: true));
    });
  });

  group('Performance test', () {
    test('Performance test seed=1607344606058', () {
      var result = SyncTreeBenchmark(1607344606058).measure();

      print(Duration(microseconds: result.toInt()));
    });
  });
}

class SyncTreeBenchmark extends BenchmarkBase {
  final int seed;
  SyncTreeBenchmark(this.seed) : super('SyncTree');

  @override
  void run() {
    fakeAsync((fakeAsync) {
      var tester = RandomSyncTreeRecordingGenerator(seed: seed);
      for (var i = 0; i < 1000; i++) {
        tester.next();
        fakeAsync.flushMicrotasks();
      }
    });
  }
}

void _doTest(int? seed, {bool minimize = true, bool usePersistence = true}) {
  var generator = RandomSyncTreeRecordingGenerator(
      seed: seed, usePersistence: usePersistence);

  generator.tester.startRecording();

  try {
    _executeTest(generator);
  } catch (e) {
    if (!minimize) {
      rethrow;
    }
    var recording = generator.tester.stopRecording();

    num count = double.maxFinite;
    while (recording.events.length < count) {
      count = recording.events.length;
      recording = _minimizeRecording(recording);
    }
    // print(recording);

    print(recording.toCode());

    fakeAsync(
        (async) => recording.replay(async, usePersistence: usePersistence));
  }
}

void _executeTest(RandomSyncTreeRecordingGenerator generator) {
  fakeAsync((fakeAsync) {
    for (var i = 0; i < 1000; i++) {
      generator.next();
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      generator.tester.checkServerVersions();
      generator.tester.checkLocalVersions();
    }
    while (generator.tester.outstandingListens.isNotEmpty ||
        generator.tester.outstandingWrites.isNotEmpty) {
      generator.flush();
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      generator.tester.checkServerVersions();
      generator.tester.checkLocalVersions();
    }

    generator.tester.checkAllViewsComplete();
  });
}

SyncTreeRecording _minimizeRecording(SyncTreeRecording recording) {
  var events = <SyncTreeOperation?>[...recording.events];
  for (var i = 0; i < recording.events.length; i++) {
    events[i] = null;
    var r = SyncTreeRecording()..events.addAll(events.whereType());

    try {
      fakeAsync((async) {
        r.replay(async);
      });
      events[i] = recording.events[i];
    } catch (e) {
      // ignore
    }
  }

  return SyncTreeRecording()..events.addAll(events.whereType());
}
