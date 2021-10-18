import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/storage.dart';

void main() async {
  FirebaseDart.setup();

  var app = await Firebase.initializeApp(
      options: FirebaseOptions.fromMap(json
          .decode(File('example/firebase-config.json').readAsStringSync())));

  var auth = FirebaseAuth.instanceFor(app: app);

  var user = auth.currentUser;

  print('current user (from cache) = ${user?.uid}');

  await auth.signInAnonymously();

  user = auth.currentUser;
  print('current user (after sign in anonymously) = ${user!.uid}');

  await user.updateProfile(displayName: 'Jane Doe');

  print('display name = ${user.displayName}');

  var storage = FirebaseStorage.instanceFor(app: app);

  var ref = storage.ref().child('test.txt');

  await ref.putString('hello world!',
      metadata: SettableMetadata(contentType: 'text/plain'));

  var m = await ref.getMetadata();
  print('content type of file test.txt: ${m.contentType}');

  var v = utf8.decode((await ref.getData(m.size))!);
  print('content of file test.txt: $v');

  ref = storage.ref().child('test.bin');

  var task = await ref.putData(Uint8List(1024 * 1024));
  print('upladed ${task.bytesTransferred} to test.bin: state = ${task.state}');

  var l = await storage.ref().listAll();

  for (var i in l.prefixes) {
    print('root contains directory ${i.fullPath}');
  }
  for (var i in l.items) {
    print('root contains file ${i.fullPath}');
  }

  var database = FirebaseDatabase(app: app);

  var dbRef = database.reference().child('test');

  var snap = await dbRef.once();

  print('content of database /test: ${snap.value}');

  await user.delete();

  user = auth.currentUser;
  print('current user (after delete) = ${user?.uid}');

  await app.delete();
}
