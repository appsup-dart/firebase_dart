import 'dart:convert';
import 'dart:io';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/storage.dart';

void main() async {
  PureDartFirebase.setup();

  var app = await Firebase.initializeApp(
      options: FirebaseOptions.fromMap(json
          .decode(File('example/firebase-config.json').readAsStringSync())));

  var auth = FirebaseAuth.fromApp(app);

  var user = await auth.currentUser();

  print('current user (from cache) = ${user?.uid}');

  await auth.signInAnonymously();

  user = await auth.currentUser();
  print('current user (after sign in anonymously) = ${user.uid}');

  await user.updateProfile(UserUpdateInfo()..displayName = 'Jane Doe');

  print('display name = ${user.displayName}');

  var storage = FirebaseStorage(app: app);

  var ref = storage.ref().child('test.txt');

  var m = await ref.getMetadata();
  print('content type of file test.txt: ${m.contentType}');

  var v = utf8.decode(await ref.getData(m.sizeBytes));
  print('content of file test.txt: $v');

  var database = FirebaseDatabase(app: app);

  var dbRef = database.reference().child('test');

  var snap = await dbRef.once();

  print('content of database /test: ${snap.value}');

  await user.delete();

  user = await auth.currentUser();
  print('current user (after delete) = ${user?.uid}');

  await app.delete();
}
