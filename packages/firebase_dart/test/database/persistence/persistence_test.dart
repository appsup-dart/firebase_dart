import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../src/random_synctree_tester.dart';

void main() async {
  await Hive.openBox('firebase-db-storage', bytes: Uint8List(0));

  hierarchicalLoggingEnabled = true;
/*   RandomSyncTreeTester.logger
    ..level = Level.ALL
    ..onRecord.listen(print);
 */
  group('Random synctree test', () {
    test('Random synctree test seed=1607344606058', () {
      _doTest(1607344606058);
    });

    test('Random synctree test seed=epoch', () {
      for (var i = 0; i < 10; i++) {
        _doTest(null);
      }
    });
  });
}

void _doTest(int? seed) {
  fakeAsync((fakeAsync) {
    var generator =
        RandomSyncTreeRecordingGenerator(seed: seed, unlistenProbability: 0.1);

    for (var i = 0; i < 1000; i++) {
      generator.next();
      fakeAsync.flushMicrotasks();

      generator.tester.checkPersistedActiveQueries();
      generator.tester.checkPersistedWrites();

      if (generator.tester.outstandingListens.isEmpty) {
        generator.tester.checkPersistedServerCache();
      }
    }
    generator.flush();
  });
}
