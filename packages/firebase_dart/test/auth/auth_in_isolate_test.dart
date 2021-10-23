import 'package:test/test.dart';

import 'auth_test.dart';

void main() {
  group('auth service', () => runAuthTests(isolated: true),
      onPlatform: {'browser': Skip('Isolates not supported on web')});
}
