import 'dart:convert';
import 'dart:io';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';

void main() async {
  FirebaseDart.setup();

  var app = await Firebase.initializeApp(
      options: FirebaseOptions.fromMap(json
          .decode(File('example/firebase-config.json').readAsStringSync())));

  var auth = FirebaseAuth.instanceFor(app: app);

  var now = DateTime.now().microsecondsSinceEpoch;
  var user = await auth.createUserWithEmailAndPassword(
      email: '$now@test.com', password: 'test123');

  await Future.delayed(Duration(minutes: 5));

  await user.user!.reauthenticateWithCredential(EmailAuthProvider.credential(
      email: '$now@test.com', password: 'test123'));

  await user.user!.updatePassword('test1234');

  await user.user!.delete();
}
