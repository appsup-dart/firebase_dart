import 'package:test/scaffolding.dart';

import 'database_test.dart';

void main() {
  group('database service',
      () => runDatabaseTests(isolated: false, keepQueriesSynced: false));
}
