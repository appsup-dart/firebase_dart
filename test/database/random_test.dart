import 'package:fake_async/fake_async.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'src/random_synctree_tester.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  RandomSyncTreeTester.logger
//    ..level = Level.ALL
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

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null);
      }
    });
  });
}

void _doTest(int seed) {
  fakeAsync((fakeAsync) {
    var tester = RandomSyncTreeTester(seed: seed);

    for (var i = 0; i < 1000; i++) {
      tester.next();
      fakeAsync.flushMicrotasks();
      tester.checkServerVersions();
      if (tester.outstandingWrites.isEmpty) {
        // TODO: once completeness on user operation is correctly implemented, local versions should also match when there are still outstanding writes
        tester.checkLocalVersions();
      }
    }
    tester.flush();
    tester.checkLocalVersions();

    tester.checkAllViewsComplete();
  });
}
