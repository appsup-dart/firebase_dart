import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fake_async/fake_async.dart';
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

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null, minimize: false);
      }
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

void _doTest(int? seed, {bool minimize = true}) {
  var tester = RandomSyncTreeTester(seed: seed)..startRecording();

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

    fakeAsync((async) => recording.replay(async));
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
