import 'package:fake_async/fake_async.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../src/random_synctree_tester.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  RandomSyncTreeTester.logger
//    ..level = Level.ALL
    ..onRecord.listen(print);

  group('Random synctree test', () {
    test('Random synctree test seed=1607288421899', () {
      _doTest(1607344606058);
    });
  });
}

void _doTest(int seed) {
  fakeAsync((fakeAsync) {
    var tester = RandomSyncTreeTester(seed: seed);

    for (var i = 0; i < 1000; i++) {
      tester.next();
      fakeAsync.flushMicrotasks();

      tester.checkPersistedWrites();
    }
    tester.flush();
  });
}
