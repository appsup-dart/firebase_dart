import 'dart:io';

import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:firebase_dart_flutter_example/src/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'firebase_options.dart';

void main() async {
  // Accept custom ssl certificates for use in proxy servers to be able to
  // capture/monitor network traffic for debugging purposes
  if (kDebugMode) HttpOverrides.global = MyHttpOverrides();

  await FirebaseDartFlutter.setup(isolated: false);

  var box = await Hive.openBox('firebase_dart_flutter_example');
  if (box.get('apps') == null || (box.get('apps') as List).isEmpty) {
    await box.put('apps', [DefaultFirebaseOptions.currentPlatform.asMap]);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
