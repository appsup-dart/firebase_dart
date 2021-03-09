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
    test('Random synctree test seed=1607288421899', () {
      _doTest(1607344606058);
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

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null);
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

void _doTest(int seed) {
  fakeAsync((fakeAsync) {
    var tester = RandomSyncTreeTester(seed: seed);

    for (var i = 0; i < 1000; i++) {
      tester.next();
      fakeAsync.flushMicrotasks();
      if (tester.outstandingListens.isEmpty) {
        tester.checkServerVersions();
        if (tester.outstandingWrites.isEmpty) {
          // TODO: once completeness on user operation is correctly implemented, local versions should also match when there are still outstanding writes
          tester.checkLocalVersions();
        }
      }
    }
    tester.flush();
    tester.checkLocalVersions();

    tester.checkAllViewsComplete();
  });
}
