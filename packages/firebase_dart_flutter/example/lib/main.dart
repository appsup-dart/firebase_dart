import 'dart:io';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:_integration_testing/_integration_testing.dart';
import 'package:firebase_dart_flutter_auth_apple/firebase_dart_flutter_auth_apple.dart';
import 'package:firebase_dart_flutter_auth_facebook/firebase_dart_flutter_auth_facebook.dart';
import 'package:firebase_dart_flutter_auth_google/firebase_dart_flutter_auth_google.dart';
import 'package:firebase_dart_flutter_example/src/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  // Accept custom ssl certificates for use in proxy servers to be able to
  // capture/monitor network traffic for debugging purposes
  if (kDebugMode) HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  var key = GlobalKey();
  var appVerifier = FlutterApplicationVerifier(
      useApns: false,
      usePlayIntegrity: false,
      getBuildContext: () => key.currentContext);
  await FirebaseDartFlutter.setup(
    isolated: false,
    socialAuthHandlers: [
      GoogleAuthHandler(),
      FacebookAuthHandler(
        facebookAppIdForFirebaseApp: (app) => '698091946903009',
      ),
      AppleAuthHandler(),
    ],
    applicationVerifier: appVerifier,
  );

  var box = await Hive.openBox('firebase_dart_flutter_example');
  await box.put(
    'apps',
    await _syncAppsWithGeneratedConfigs(box.get('apps') as List?),
  );

  runApp(MyApp(key: key));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AppListPage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}

Future<List<Map<String, dynamic>>> _syncAppsWithGeneratedConfigs(
  List? existingApps,
) async {
  final appId = await _currentPlatformAppId();
  final generatedApps = allConfigs
      .map((config) =>
          _selectOptionsForCurrentPlatform(config, appId: appId).asMap)
      .toList();

  final generatedByProjectId = <String, Map<String, dynamic>>{
    for (final app in generatedApps) app['projectId'] as String: app,
  };

  final merged = <Map<String, dynamic>>[];
  final seenProjectIds = <String>{};
  final existingProjectIds = <String>{};

  for (final entry in existingApps ?? const <dynamic>[]) {
    if (entry is! Map) continue;
    final existing = Map<String, dynamic>.from(entry);
    final projectId = existing['projectId'] as String?;
    if (projectId == null || projectId.isEmpty) {
      merged.add(existing);
      continue;
    }

    final generated = generatedByProjectId[projectId];
    if (generated != null) {
      merged.add(generated);
      seenProjectIds.add(projectId);
      existingProjectIds.add(projectId);
    } else {
      merged.add(existing);
      existingProjectIds.add(projectId);
    }
  }

  for (final generated in generatedApps) {
    final projectId = generated['projectId'];
    if (projectId == null || projectId.isEmpty) continue;
    if (!seenProjectIds.contains(projectId) &&
        !existingProjectIds.contains(projectId)) {
      merged.add(generated);
    }
  }

  return merged;
}

Future<String?> _currentPlatformAppId() async {
  if (kIsWeb) return null;
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.packageName;
}

FirebaseOptions _selectOptionsForCurrentPlatform(
  FirebaseProjectConfig config, {
  required String? appId,
}) {
  if (kIsWeb) {
    return config.webConfig;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      if (appId != null && config.androidConfigs.containsKey(appId)) {
        return config.androidConfigs[appId]!;
      }
      if (config.androidConfigs.isNotEmpty) {
        return config.androidConfigs.values.first;
      }
      return config.webConfig;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      if (appId != null && config.iosConfigs.containsKey(appId)) {
        return config.iosConfigs[appId]!;
      }
      if (config.iosConfigs.isNotEmpty) {
        return config.iosConfigs.values.first;
      }
      return config.webConfig;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return config.webConfig;
  }
}
