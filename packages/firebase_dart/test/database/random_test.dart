import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'src/random_synctree_tester.dart';

void main() async {
  await Hive.openBox('firebase-db-storage', bytes: Uint8List(0));

  hierarchicalLoggingEnabled = true;
  RandomSyncTreeTester.logger
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

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null, minimize: false);
      }
    });
  });

  group('persistence storage', () {
    test('should remove obscured data from storage', () {
      var treeOperation1 = TreeOperation(Path.from([]),
          Overwrite(TreeStructuredData.fromJson({'key-1': false})));

      var querySpec = QuerySpec(Path.from([]), QueryFilter(limit: 2));
      var treeOperation2 = TreeOperation(Path.from([]),
          Overwrite(TreeStructuredData.fromJson({'key-2': false})));

      var recording = SyncTreeTesterRecording(events: [
        SyncTreeTesterEvent.serverOperation(treeOperation1),
        SyncTreeTesterEvent.listen(querySpec),
        SyncTreeTesterEvent.ackListen(querySpec),
        SyncTreeTesterEvent.serverOperation(treeOperation2),
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
      var recording = SyncTreeTesterRecording(events: [
        SyncTreeTesterEvent.listen(querySpec),
        SyncTreeTesterEvent.ackListen(querySpec),
        SyncTreeTesterEvent.serverOperation(treeOperation),
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
      var tester = RandomSyncTreeTester(seed: seed);
      for (var i = 0; i < 1000; i++) {
        tester.next();
        fakeAsync.flushMicrotasks();
      }
    });
  }
}

void _doTest(int? seed, {bool minimize = true, bool usePersistence = true}) {
  var tester = RandomSyncTreeTester(seed: seed, usePersistence: usePersistence)
    ..startRecording();

  try {
    _executeTest(tester);
  } catch (e) {
    if (!minimize) {
      rethrow;
    }
    var recording = tester.stopRecording();

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

void _executeTest(RandomSyncTreeTester tester) {
  fakeAsync((fakeAsync) {
    for (var i = 0; i < 1000; i++) {
      tester.next();
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      tester.checkServerVersions();
      tester.checkLocalVersions();
    }
    while (tester.outstandingListens.isNotEmpty ||
        tester.outstandingWrites.isNotEmpty) {
      tester.flush();
      fakeAsync.flushMicrotasks();
      fakeAsync.flushTimers();
      tester.checkServerVersions();
      tester.checkLocalVersions();
    }

    tester.checkAllViewsComplete();
  });
}

SyncTreeTesterRecording _minimizeRecording(SyncTreeTesterRecording recording) {
  var events = <SyncTreeTesterEvent?>[...recording.events];
  for (var i = 0; i < recording.events.length; i++) {
    events[i] = null;
    var r = SyncTreeTesterRecording()..events.addAll(events.whereType());

    try {
      fakeAsync((async) {
        r.replay(async);
      });
      events[i] = recording.events[i];
    } catch (e) {
      // ignore
    }
  }

  return SyncTreeTesterRecording()..events.addAll(events.whereType());
}
