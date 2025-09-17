import 'dart:io';

import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:firebase_dart_flutter_auth_apple/firebase_dart_flutter_auth_apple.dart';
import 'package:firebase_dart_flutter_auth_facebook/firebase_dart_flutter_auth_facebook.dart';
import 'package:firebase_dart_flutter_auth_google/firebase_dart_flutter_auth_google.dart';
import 'package:firebase_dart_flutter_example/src/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'firebase_options.dart';

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
  if (box.get('apps') == null || (box.get('apps') as List).isEmpty) {
    await box.put('apps', [DefaultFirebaseOptions.currentPlatform.asMap]);
  }

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
