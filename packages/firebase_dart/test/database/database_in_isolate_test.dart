import 'package:test/scaffolding.dart';

import 'database_test.dart';

void main() {
  group('database service', () => runDatabaseTests(isolated: true),
      onPlatform: {'browser': Skip('Isolates not supported on web')});
}
