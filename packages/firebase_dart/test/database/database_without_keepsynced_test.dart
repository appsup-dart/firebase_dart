import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:test/scaffolding.dart';

import 'database_test.dart';

void main() {
  FirebaseDart.updateDatabaseConfiguration(
      keepQueriesSyncedDuration: Duration());

  group('database service', () => runDatabaseTests(isolated: false));
}
