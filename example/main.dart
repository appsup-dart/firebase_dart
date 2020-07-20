import 'package:firebase_dart/database.dart';

void main() {
  var ref = Firebase('https://n6ufdauwqsdfmp.firebaseio-demo.com/');

  ref.child('test').onValue.listen((e) {
    print(e.snapshot.value);
  });
}
