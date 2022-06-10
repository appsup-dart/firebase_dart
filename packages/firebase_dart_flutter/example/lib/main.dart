import 'package:firebase_dart_flutter/firebase_dart_flutter.dart';
import 'package:firebase_dart_flutter_example/src/core.dart';
import 'package:flutter/material.dart';

void main() async {
  await FirebaseDartFlutter.setup(isolated: false);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AppListPage(),
    );
  }
}
