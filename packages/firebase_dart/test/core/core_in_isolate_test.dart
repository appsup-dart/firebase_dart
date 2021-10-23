import 'package:test/scaffolding.dart';

import 'core_test.dart';

void main() {
  group('firebase core', () => runCoreTests(isolated: true),
      onPlatform: {'browser': Skip('Isolates not supported on web')});
}
