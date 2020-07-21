import 'package:firebase_dart/database.dart';

void main() {
  var ref = FirebaseDatabase(
          databaseURL: 'https://n6ufdauwqsdfmp.firebaseio-demo.com/')
      .reference();

  ref.child('test').onValue.listen((e) {
    print(e.snapshot.value);
  });
}
