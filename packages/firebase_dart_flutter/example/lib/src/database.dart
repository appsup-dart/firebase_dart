import 'package:firebase_dart/firebase_dart.dart';
import 'package:flutter/material.dart';

import 'database/inspector.dart';

class DatabaseTab extends StatelessWidget {
  final FirebaseApp app;

  final FirebaseDatabase database;

  DatabaseTab({Key? key, required this.app})
      : database = FirebaseDatabase(app: app),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: const Text('query inspector'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return QueryInspectorPage(database: database);
                  },
                ));
              },
            )
          ],
        ));
  }
}
