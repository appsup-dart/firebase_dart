import 'package:test/scaffolding.dart';

import 'storage_test.dart';

void main() {
  group('storage service', () => runStorageTests(isolated: true),
      onPlatform: {'browser': Skip('Isolates not supported on web')});
}
