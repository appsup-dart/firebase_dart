
A pure Dart implementation of the Firebase client


## Usage

A simple usage example:

    import 'package:firebase_dart/firebase_dart.dart';

    main() {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/");
      
      ref.child("test").onValue.listen((e) {
        print(e.snapshot.val);
      });
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/appsup-dart/firebase_dart/issues
