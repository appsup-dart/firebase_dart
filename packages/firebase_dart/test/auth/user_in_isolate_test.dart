import 'package:test/scaffolding.dart';

import 'user_test.dart';

void main() {
  group('auth service - user', () => runUserTests(isolated: true),
      onPlatform: {'browser': Skip('Isolates not supported on web')});
}
