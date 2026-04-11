/// Helpers for integration/smoke testing in this workspace.
library;

import 'package:firebase_dart/core.dart';

export '_generated/all.dart';

class FirebaseProjectConfig {
  final String projectId;

  final FirebaseOptions webConfig;

  final Map<String, FirebaseOptions> iosConfigs;

  final Map<String, FirebaseOptions> androidConfigs;

  /// iOS bundle IDs for which Firebase has an APNs auth key
  final List<String> iosBundleIdsWithApnsConfigured;

  const FirebaseProjectConfig({
    required this.projectId,
    required this.webConfig,
    required this.iosConfigs,
    required this.androidConfigs,
    this.iosBundleIdsWithApnsConfigured = const [],
  });
}
