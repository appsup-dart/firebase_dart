// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:firebase_dart/src/firebase.dart';
import 'package:logging/logging.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);

  group('Reference location', () {
    var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/");
    var ref2 = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");

    test('child', () {
      expect(ref.key, null);
      expect(ref.child('test').key, 'test');
      expect(ref.child('test/hello').key, 'hello');
      expect(ref.child('test').child('hello').key, 'hello');
      expect(ref.child('test').child('hello').url.path, '/test/hello');
      expect(ref2.key, 'test');
      expect(ref2.child('object/hello').url.path, '/test/object/hello');
    });
    test('parent', () {
      expect(ref.child('test').parent.key, null);
      expect(ref.child('test/hello').parent.key, 'test');
    });
    test('root', () {
      expect(ref.child('test').root.key, null);
      expect(ref.child('test/hello').root.key, null);
    });
  });
  group('Authenticate', () {
    var host = "REPLACE WITH FIREBASE HOST";
    var secret = "REPLACE WITH SECRET";

    if (host=="REPLACE WITH FIREBASE HOST") {
      print("Cannot test Authenticate: set a host and secret.");
      return;
    }

    var uid = "pub-test-01";
    var authData = {
      "uid": uid
    };
    var token = jwt(authData, secret);

    var ref = new Firebase(host);


    test('auth', () async {
      var fromStream = ref.onAuth.first;
      var auth = await ref.authWithCustomToken(token);
      expect(auth["uid"], uid);
      expect(ref.auth["uid"], uid);
      expect((await fromStream)["uid"], uid);
    });
    test('unauth', () async {
      var fromStream = ref.onAuth.first;
      expect(ref.auth["uid"], uid);
      await ref.unauth();
      expect(ref.auth, isNull);
      expect((await fromStream), isNull);
    });
  });
  group('Listen', () {

    var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");

    test('Initial value', () async {
      print(await ref.get());
    });

    test('Value after set', () async {
      var v = "Hello world ${new Random().nextDouble()}";
      await ref.set(v);
      print("set to $v");
      expect(await ref.get(), v);
      print("got value");
      await ref.set("Hello all");
      print("set to Hello all");
      expect(await ref.get(), "Hello all");
    });

    test('Set object', () async {
      await ref.set({
        "object": {
          "hello": "world"
        }
      });
      ref.onValue.forEach((_){});

      expect(await ref.child("object/hello").get(), "world");

      await ref.set({
        "object": {
          "hello": "all",
          "something": "else"
        }
      });

      expect(await ref.child("object/hello").get(), "all");

    });

  });

  group('Push/Merge/Remove', () {
    var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");

    test('Remove', () async {
      await ref.set('hello');
      expect(await ref.get(),'hello');
      await ref.set(null);
      expect((await ref.onceValue).exists, false);
    });

    test('Merge', () async {
      await ref.set({
        "text1": "hello1"
      });
      expect(await ref.get(),{
        "text1": "hello1"
      });
      await ref.update({
        "text2": "hello2",
        "text3": "hello3"
      });

      expect(await ref.get(),{
        "text1": "hello1",
        "text2": "hello2",
        "text3": "hello3"
      });

    });

    test('Push', () async {
      await ref.set({
        "text1": "hello1"
      });
      expect(await ref.get(),{
        "text1": "hello1"
      });
      var childRef = await ref.push("hello2");
      expect(await childRef.get(), "hello2");
    });


  });

  group('Query', () {


    test('Limit', () async {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");

      await ref.set({
        "text1": "hello1",
        "text2": "hello2",
        "text3": "hello3"
      });

      expect(await ref.limitToFirst(1).get(), {
        "text1": "hello1"
      });

      expect(await ref.limitToFirst(2).get(), {
        "text1": "hello1",
        "text2": "hello2",
      });

      expect(await ref.limitToLast(1).get(), {
        "text3": "hello3"
      });

      expect(await ref.limitToLast(2).get(), {
        "text2": "hello2",
        "text3": "hello3"
      });


    });

    test('Order by value', () async {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");
      await ref.set({
        "text1": "b",
        "text2": "c",
        "text3": "a"
      });

      ref = ref.orderByValue();

      expect(await ref.limitToFirst(1).get(), {
        "text3": "a"
      });

      expect(await ref.limitToFirst(2).get(), {
        "text3": "a",
        "text1": "b"
      });

      expect(await ref.limitToLast(1).get(), {
        "text2": "c"
      });

      expect(await ref.limitToLast(2).get(), {
        "text1": "b",
        "text2": "c"
      });


    });

    test('Order by key', () async {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");
      await ref.set({
        "text2": "b",
        "text1": "c",
        "text3": "a"
      });

      ref = ref.orderByKey();

      expect(await ref.limitToFirst(1).get(), {
        "text1": "c"
      });

      expect(await ref.limitToFirst(2).get(), {
        "text1": "c",
        "text2": "b"
      });

      expect(await ref.limitToLast(1).get(), {
        "text3": "a"
      });

      expect(await ref.limitToLast(2).get(), {
        "text2": "b",
        "text3": "a"
      });


    });

    test('Order by priority', () async {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");
      await ref.set({
        "text2": "b",
        "text1": "c",
        "text3": "a"
      });
      await ref.child("text1").setPriority(2);
      await ref.child("text2").setPriority(1);
      await ref.child("text3").setPriority(3);


      ref = ref.orderByPriority();

      expect(await ref.limitToFirst(1).get(), {
        "text2": "b"
      });

      expect(await ref.limitToFirst(2).get(), {
        "text2": "b",
        "text1": "c"
      });

      expect(await ref.limitToLast(1).get(), {
        "text3": "a"
      });

      expect(await ref.limitToLast(2).get(), {
        "text1": "c",
        "text3": "a"
      });


    });
    test('Order by child', () async {
      var ref = new Firebase("https://n6ufdauwqsdfmp.firebaseio-demo.com/test");
      await ref.set({
        "text2": {"order":"b"},
        "text1": {"order":"c"},
        "text3": {"order":"a"}
      });

      ref = ref.orderByChild("order");

      expect(await ref.limitToFirst(1).get(), {
        "text3": {"order":"a"}
      });

      expect(await ref.limitToFirst(2).get(), {
        "text3": {"order":"a"},
        "text2": {"order":"b"}
      });

      expect(await ref.limitToLast(1).get(), {
        "text1": {"order":"c"}
      });

      expect(await ref.limitToLast(2).get(), {
        "text2": {"order":"b"},
        "text1": {"order":"c"}
      });


    });
  });

}



String jwt(Map data, String secret) {
  var d = {
    "exp": new DateTime.now().add(new Duration(days: 30)).millisecondsSinceEpoch,
    "v": 0,
    "d": data,
    "iat": new DateTime.now().millisecondsSinceEpoch
  };
  return _jwt(JSON.encode(d).codeUnits, secret: secret, header: const {
    'typ': 'JWT',
    'alg': 'HS256'
  });
}

String _jwt(List<int> payload, {Map header, String secret}) {
  final msg = '${BASE64URL.encode(JSON.encode(header).codeUnits)}.${BASE64URL.encode(payload)}';
  return "${msg}.${_signMessage(msg, secret)}";
}

String _signMessage(String msg, String secret) {
  final hmac = new Hmac(sha256, secret.codeUnits);
  final signature = hmac.convert(msg.codeUnits);
  return BASE64URL.encode(signature.bytes);
}