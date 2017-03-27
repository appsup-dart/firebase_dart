// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:firebase_dart/src/firebase.dart';
import 'package:firebase_dart/src/repo.dart';
import 'package:firebase_dart/src/connections/mem.dart';
import 'package:logging/logging.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'secrets.dart'
  if (dart.library.html) 'secrets.dart'
  if (dart.library.io) 'secrets_io.dart' as s;
import 'dart:isolate';
import 'package:isolate/isolate.dart';
import 'package:firebase_dart/src/isolate_runner.dart';



void main() {
  StreamSubscription logSubscription;
  setUp(() {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen(print);
  });
  tearDown(() async {
    await logSubscription.cancel();
  });


  group("mem",() {
    testsWith({
      "host": "mem://test/",
      "secret": "x"
    });
  });

  group("https",() {
    testsWith(s.secrets);
  });
}

void testsWith(Map<String,String> secrets) {
  String testUrl = "${secrets["host"]}";


  Firebase ref, ref2;

  group('Reference location', () {
    setUp(() {
      ref = new Firebase("${testUrl}");
      ref2 = new Firebase("${testUrl}test");
    });

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
    String token, uid;
    setUp(() {
      var host = secrets["host"];
      var secret = secrets["secret"];

      if (host==null||secret==null) {
        print("Cannot test Authenticate: set a host and secret.");
        return;
      }

      uid = "pub-test-01";
      var authData = {
        "uid": uid,
        "debug": true,
        "provider": "custom"
      };
      var codec = new FirebaseTokenCodec(secret);
      token = codec.encode(new FirebaseToken(authData));

      ref = new Firebase(host);
    });


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

    test('permission denied', () async {
      if (ref.url.scheme=="mem") {
        // TODO
        return;
      }
      ref = ref.child('test-protected');
      ref.onValue.listen((e)=>print(e.snapshot.val));
      await ref.authWithCustomToken(token);
      await ref.set('hello world');
      expect(await ref.get(),'hello world');
      await ref.unauth();
      await ref.set('hello all').catchError(print);
      expect(await ref.get(),'hello world');

    });
    test('token', () {
      var token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InJpa0BwYXJ0YWdvLmJlIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJpYXQiOjE0NzIxMjIyMzgsInYiOjAsImQiOnsicHJvdmlkZXIiOiJwYXNzd29yZCIsInVpZCI6IjMzZTc1ZjI0LTE5MTAtNGI1Mi1hZDJjLWNmZGQwYWFjNzI4YiJ9fQ.ZO0zH6xgk58SKDqmqi9gWzsvzoSvPx6QCJizR94rzEc";
      var t = (new FirebaseTokenCodec(null).decode(token));
      print(t.toJson());
    });
  });

  group('Snapshot', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/snapshot");
      print("ref setup");
    });

    test('Child', () async {

      await ref.set({
        "hello": "world"
      });

      var e = await ref.onValue.first;

      var s = e.snapshot;
      expect(s.key, "snapshot");
      expect(s.exists, true);
      expect(s.val, {"hello": "world"});

      s = s.child("hello");
      expect(s.key, "hello");
      expect(s.exists, true);
      expect(s.val, "world");

      s = s.child("does not exist");
      expect(s.key, "does not exist");
      expect(s.exists, false);
      expect(s.val, null);

      s = s.child("also does not exist");
      expect(s.key, "also does not exist");
      expect(s.exists, false);
      expect(s.val, null);

      s = s.child("also does not exist");
      expect(s.key, "also does not exist");
      expect(s.exists, false);
      expect(s.val, null);

    });
  });

  group('Listen', () {

    setUp(() {
      ref = new Firebase("${testUrl}test/listen");
    });

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
      ref.onValue.listen((_){});

      expect(await ref.child("object/hello").get(), "world");

      await ref.set({
        "object": {
          "hello": "all",
          "something": "else"
        }
      });

      expect(await ref.child("object/hello").get(), "all");

    });

    test('Multiple listeners on on*-stream', () async {
      await(ref.set("hello world"));

      var onValue = ref.onValue;

      expect((await onValue.first).snapshot.val, "hello world");
      expect((await onValue.first).snapshot.val, "hello world");

    });

    test('Child added', () async {

      await(ref.remove());

      var keys = ref.onChildAdded.take(2).map((e)=>e.snapshot.key).toList();
      await ref.get();

      await ref.child("hello").set("world");
      await ref.child("hi").set("everyone");

      expect(await keys, ["hello","hi"]);
    });

    test('Child removed', () async {

      await ref.set({
        "hello": "world",
        "hi": "everyone"
      });

      var keys = ref.onChildRemoved.take(2).map((e)=>e.snapshot.key).toList();
      await ref.get();

      await ref.update({"test": "something","hello":null});
      await ref.child("hi").remove();

      expect(await keys, ["hello","hi"]);
    });

    test('Child changed', () async {

      await ref.set({
        "hello": "world",
        "hi": "everyone"
      });

      var keys = ref.onChildChanged.take(2).map((e)=>e.snapshot.key).toList();
      await ref.get();

      await ref.child("hello").set("world2");
      await ref.child("hi").set("everyone2");

      expect(await keys, ["hello","hi"]);
    });

    test('Child moved', () async {

      await ref.set({
        "hello": "world",
        "hi": "everyone",
      });

      var f = ref.orderByValue().onChildMoved.where((e)=>e.prevChild!=null).first;

      await ref.get();

      expect((await ref.orderByValue().get()).keys, ["hi","hello"]);

      await ref.child("hello").set("abc");

      var e = await f;

      expect(e.snapshot.key, "hi");
      expect(e.prevChild, "hello");
    });


  });

  group('Push/Merge/Remove', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/push-merge-remove");
    });

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

  group('Special characters', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/special-chars");
    });

    test('colon', () async {

      await ref.child("users").child("facebook:12345").set({'name':'me'});

      expect(await new Firebase("${ref.url}/users/facebook:12345/name").get(), "me");
    });

    test('spaces', () async {

      await ref.child("users").set(null);
      await ref.child("users").child("Jane Doe").set({'name':'Jane'});

      expect(ref.child("users").child("Jane Doe").key, "Jane Doe");

      expect(await ref.child("users").child("Jane Doe").get(), {"name": "Jane"});
      expect(await ref.child("users").get(), {
        "Jane Doe": {"name": "Jane"}
      });

    });
  });

  group('ServerValue', () {

    test('timestamp', () async {
      var ref = new Firebase("${testUrl}test/server-values/timestamp");

      await ref.set(null);
      var events = <Event>[];
      ref.onValue.listen(events.add);

      await ref.get();

      await ref.set(ServerValue.timestamp);

      await new Future.delayed(new Duration(seconds: 1));
      var values = events.map((e)=>e.snapshot.val).toList();
      print(values);
      expect(values.length, 3);
      expect(values[0], null);

      expect(values[1] is num, isTrue);
      expect(values[2] is num, isTrue);
      expect(values[2]-values[1]>0, isTrue);
      expect(values[2]-values[1]<1000, isTrue);

      return;
      await ref.set({
        "hello": "world",
        "it is now": ServerValue.timestamp
      });

      print(await ref.child("it is now").get());
      expect(await ref.child("it is now").get() is num, isTrue);

    });

    test('transaction', () async {
      var ref = new Firebase("${testUrl}test/server-values/transaction");
      await ref.set("hello");

      await new Stream.periodic(new Duration(milliseconds: 10))
          .take(10).forEach((_) {
        ref.transaction((v) {
          return ServerValue.timestamp;
        });
      });

      await new Future.delayed(new Duration(seconds: 1));

      expect(await ref.get() is num, isTrue);


    });
  });

  group('Transaction', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/transactions");
    });

    test('Counter', () async {
      await ref.set(0);

      ref.onValue.listen((e)=>print("onValue ${e.snapshot.val}"));
      await ref.onValue.first;
      var f1 = new Stream.periodic(new Duration(milliseconds: 10))
          .take(10)
          .map((i) => ref.transaction((v)=>(v??0)+1))
          .toList();
      var f2 = new Stream.periodic(new Duration(milliseconds: 50))
          .take(10)
          .map((i) => ref.transaction((v)=>(v??0)+1))
          .toList();

      await Future.wait((await f1)..addAll(await f2));

      expect(await ref.get(), 20);
    });

    test('Counter in tree', () async {

      await ref.child('object/count').set(0);

      var f1 = new Stream.periodic(new Duration(milliseconds: 10))
          .take(10)
          .map((i) => ref.child('object/count').transaction((v)=>(v??0)+1))
          .toList();
      var f2 = new Stream.periodic(new Duration(milliseconds: 50))
          .take(10)
          .map((i) => ref.transaction((v) {
        v ??= {};
        v
            .putIfAbsent("object",()=>{})
            .putIfAbsent("count",()=>0);
        v["object"]["count"]++;
        return v;
      }))
          .toList();
      var f3 = new Stream.periodic(new Duration(milliseconds: 30))
          .take(10)
          .map((i) => ref.child("object").transaction((v) {
        v ??= {};
        v
            .putIfAbsent("count",()=>0);
        v["count"]++;
        return v;
      }))
          .toList();

      await Future.wait((await f1)..addAll(await f2)..addAll(await f3));

      expect(await ref.child("object/count").get(), 30);
    });

    test('Abort', () async {
      await ref.child('object/count').set(0);

      var futures = <Future>[];
      for (var i=0;i<10;i++) {
        futures.add(ref.child('object/count').transaction((v)=>(v??0)+1));
      }
      for (var i=0;i<10;i++) {
        futures.add(ref.child('object').transaction((v) {
          v ??= {};
          v
              .putIfAbsent("count",()=>0);
          v["count"]++;
          return v;
        }).catchError((_){}));
      }
      futures.add(ref.child('object/test').set('hello'));

      await Future.wait(futures);

      await wait(400);

      expect(await ref.child("object/count").get(), 10);

    });

  });

  group('OnDisconnect', () {
    Repo repo;
    setUp(() {
      ref = new Firebase("${testUrl}test/disconnect");
      repo = new Repo(ref.url.resolve("/"));
    });

    test('put', () async {
      await ref.set("hello");

      await ref.onDisconnect.set("disconnected");

      await repo.triggerDisconnect();

      await new Future.delayed(new Duration(milliseconds: 200));

      expect(await ref.get(),"disconnected");

    });
    test('merge', () async {
      await ref.set({"hello":"world"});
      ref.child('state').onValue.listen((_){});


      await ref.onDisconnect.update({"state":"disconnected"});

      await repo.triggerDisconnect();

      await new Future.delayed(new Duration(milliseconds: 200));

      expect(await ref.child('state').get(),"disconnected");

    });
    test('cancel', () async {
      await ref.set({"hello":"world"});

      await ref.onDisconnect.update({"state":"disconnected"});

      await ref.onDisconnect.cancel();

      await repo.triggerDisconnect();

      await new Future.delayed(new Duration(milliseconds: 200));

      expect(await ref.child('state').get(),null);

    });
  });

  group('Query', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/query");
    });


    test('Limit', () async {

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
      await ref.set({
        "text1": "b",
        "text2": "c",
        "text3": "a"
      });

      var q = ref.orderByValue();

      expect(await q.limitToFirst(1).get(), {
        "text3": "a"
      });

      expect(await q.limitToFirst(2).get(), {
        "text3": "a",
        "text1": "b"
      });

      expect(await q.limitToLast(1).get(), {
        "text2": "c"
      });

      expect(await q.limitToLast(2).get(), {
        "text1": "b",
        "text2": "c"
      });

      expect(await q.startAt("b").get(), {
        "text1": "b",
        "text2": "c"
      });

      expect(await q.startAt("b","text1").get(), {
        "text1": "b",
        "text2": "c"
      });

      expect(await q.startAt("b","text2").get(), {
        "text2": "c"
      });


    });

    test('Order by key', () async {
      var ref = new Firebase("${testUrl}test/query-key");
      await ref.set({
        "text2": "b",
        "text1": "c",
        "text3": "a"
      });

      var q = ref.orderByKey();

      expect(await q.limitToFirst(1).get(), {
        "text1": "c"
      });

      expect(await q.limitToFirst(2).get(), {
        "text1": "c",
        "text2": "b"
      });

      expect(await q.limitToLast(1).get(), {
        "text3": "a"
      });

      expect(await q.limitToLast(2).get(), {
        "text2": "b",
        "text3": "a"
      });

      expect(await q.startAt("text2").get(), {
        "text2": "b",
        "text3": "a"
      });



    });

    test('Order by priority', () async {
      await ref.set({
        "text2": "b",
        "text1": "c",
        "text3": "a"
      });
      await ref.child("text1").setPriority(2);
      await ref.child("text2").setPriority(1);
      await ref.child("text3").setPriority(3);


      var q = ref.orderByPriority();

      expect(await q.limitToFirst(1).get(), {
        "text2": "b"
      });

      expect(await q.limitToFirst(2).get(), {
        "text2": "b",
        "text1": "c"
      });

      expect(await q.limitToLast(1).get(), {
        "text3": "a"
      });

      expect(await q.limitToLast(2).get(), {
        "text1": "c",
        "text3": "a"
      });

      expect(await q.startAt(2).get(), {
        "text1": "c",
        "text3": "a"
      });

      expect(await q.startAt(2,"text1").get(), {
        "text1": "c",
        "text3": "a"
      });

      expect(await q.startAt(2,"text2").get(), {
        "text3": "a"
      });

    });
    test('Order by child', () async {
      await ref.set({
        "text2": {"order":"b"},
        "text1": {"order":"c"},
        "text3": {"order":"a"}
      });

      var q = ref.orderByChild("order");

      expect(await q.limitToFirst(1).get(), {
        "text3": {"order":"a"}
      });

      expect(await q.limitToFirst(2).get(), {
        "text3": {"order":"a"},
        "text2": {"order":"b"}
      });

      expect(await q.limitToLast(1).get(), {
        "text1": {"order":"c"}
      });

      expect(await q.limitToLast(2).get(), {
        "text2": {"order":"b"},
        "text1": {"order":"c"}
      });

      expect(await q.startAt("b").get(), {
        "text2": {"order":"b"},
        "text1": {"order":"c"}
      });

      expect(await q.startAt("b","text2").get(), {
        "text2": {"order":"b"},
        "text1": {"order":"c"}
      });

      expect(await q.startAt("b","text3").get(), {
        "text1": {"order":"c"}
      });

    });

    test('Order after remove', () async {
      var iref = new IsolatedReference(ref);
      await iref.set({
        "text2": {"order":"b"},
        "text1": {"order":"c"},
        "text3": {"order":"a"}
      });

      var q = ref.orderByChild("order");
      var l = q.startAt("b").limitToFirst(1).onValue
          .map((e)=>e.snapshot.val?.keys?.single)
          .where((v)=>v!=null)  // returns null first when has index on order otherwise not
          .take(2).toList();

      await new Future.delayed(new Duration(milliseconds: 200));
      await iref.child("text2").remove();
      await new Future.delayed(new Duration(milliseconds: 500));

      expect(await l, ["text2","text1"]);

    });

    test('Start/End at', () async {
      await ref.set({
        "text2": {"order":"b"},
        "text1": {"order":"c"},
        "text3": {"order":"a"},
        "text4": {"order":"e"},
        "text5": {"order":"d"},
        "text6": {"order":"b"}
      });

      var q = ref.orderByChild("order");

      expect(await q.startAt("b").endAt("c").get(), {
        "text2": {"order":"b"},
        "text6": {"order":"b"},
        "text1": {"order":"c"}
      });

      expect(await q.startAt("b", "text6").endAt("c").get(), {
        "text6": {"order":"b"},
        "text1": {"order":"c"}
      });


      await ref.set({
        "text2": {"order":2},
        "text1": {"order":3},
        "text3": {"order":1},
        "text4": {"order":5},
        "text5": {"order":4},
        "text6": {"order":2}
      });
      q = ref.orderByChild("order");

      expect((await q.equalTo(2).get()).keys, ["text2","text6"]);

    });

    test('Ordering', () async {
      await ref.set({
        "b": {"order":true},
        "c": {"x":1},
        "a": {"order":4},
        "e": {"order":-2.3},
        "i": {"order": "def"},
        "g": {"order":5},
        "j": {"order": {"x": 1}},
        "d": {"order":7.1},
        "23a": {"order":5},
        "h": {"order": "abc"},
        "f": {"order":5},
        "25": {"order":5},
        "k": {"order":false},
      });
      var q = ref.orderByChild("order");
      expect((await q.get()).keys, ["c","k","b","e","a","25","23a","f","g","d","h","i","j"]);


    });
  });

  group('multiple frames', () {
    setUp(() {
      ref = new Firebase("${testUrl}test/frames");
    });

    test('Receive large value', () async {


      var random = new Random();

      var value = BASE64.encode(new List<int>.generate(15000, (i)=>random.nextInt(255)));
      await ref.set(value);

      expect(await ref.get(), value);
    });
    test('Send large value', () async {

      var random = new Random();

      var value = BASE64.encode(new List<int>.generate(50000, (i)=>random.nextInt(255)));
      await ref.set(value);

      expect(await ref.get(), value);
    });
  });


  group('Complex operations', () {
    IsolatedReference iref;
    setUp(() {
      ref = new Firebase("${testUrl}test/complex");
      iref = new IsolatedReference(ref);
    });

    test('Remove out of view', () async {
      await iref.set({
        "text1": "b",
        "text2": "c",
        "text3": "a"
      });

      await wait(500);

      var l = ref.orderByKey().limitToFirst(2)
          .onValue.map((e)=>e.snapshot.val?.keys?.first).take(4).toList();


      await iref.child('text0').set("d");
      await iref.child('text1').remove();
      await iref.child('text0').remove();

      expect(await l, ["text1","text0","text0","text2"]);
    });

    test('Upgrade subquery to master view', () async {

      await iref.set({
        "text1": "b",
        "text2": "c",
        "text3": "a"
      });

      var s1 = ref.orderByKey().limitToFirst(1).onValue.listen(print);
      var l = ref.orderByKey().startAt("text2").limitToFirst(1).onValue
          .expand((e)=>e.snapshot.val?.values??[]).take(2).toList();

      await wait(500);

      await s1.cancel();

      await iref.child('text2').remove();

      expect(await l, ["c","a"]);
    });

    test('Listen to child after parent', () async {
      await iref.set({
        "text1": "b",
        "text2": "c",
        "text3": "a"
      });

      var s1 = ref.orderByKey().limitToFirst(2).onValue.map((e)=>e.snapshot.val).listen(print);

      await wait(500);

      expect(await ref.child("text2").get(), "c");
      var l = ref.child("text2").onValue
      .map((v){print(v.snapshot.val);return v;})
          .map((e)=>e.snapshot.val).take(3).toList();

      await iref.child('text2').set("x");

      await wait(500);
      await s1.cancel();

      await iref.child('text2').remove();

      expect(await l, ["c","x",null]);

    });

    test('startAt increasing', () async {
      await iref.set({
        "10": 10,
        "20": 20,
        "30": 30
      });

      var s = new Stream.periodic(new Duration(milliseconds: 20), (i)=>i).take(30);

      await for (var i in s) {
        await ref.orderByKey().startAt("$i").limitToFirst(1).get();
      }

    });

    test('parent with filter', () async {
      await iref.set({
        "child1": "hello world",
        "child2": {
          "a": 1,
          "b": 2,
          "c": 3
        }
      });


      var sub = ref.orderByKey().limitToFirst(1).onValue.listen(print);

      await new Future.delayed(new Duration(milliseconds: 500));

      var l = ref.child("child2").orderByKey().startAt("b").limitToFirst(1)
      .onValue.map((e)=>e.snapshot.val?.keys?.first).take(2).toList();

      await new Future.delayed(new Duration(milliseconds: 500));

      await iref.child("child2").child("b").remove();

      expect(await l, ["b","c"]);

      await sub.cancel();
    });

    test('complete from parent', () async {
      await iref.set({
        "child1": "hello world",
        "child2": {
          "a": 1,
          "b": 2,
          "c": 3
        }
      });

      var sub = ref.orderByKey().onValue.listen(print);
      var sub2 = ref.child("child2").orderByKey().limitToFirst(1).onValue.listen(print);
      await wait(500);


      var l = ref.child("child2").child("b")
          .onValue.map((e)=>e.snapshot.val).take(3).toList();


      await sub.cancel();
      await wait(200);

      await iref.child("child2").child("b").set(4);
      await wait(200);

      await iref.child("child2").child("b").set(5);
      expect(await l, [2,4,5]);


      await sub2.cancel();
    });

    test('with canceled parent', () async {
      var sub = ref.root.onValue.listen((v)=>print(v.snapshot.val), onError: (e)=>print("error $e"));
      await wait(400);

      await iref.set("hello world");

      expect(await ref.get(), "hello world");



      await iref.set("hello all");
      await wait(400);
      expect(await ref.get(), "hello all");

      await sub.cancel();

    });
  });
}

wait(int millis) async => new Future.delayed(new Duration(milliseconds: millis));


class IsolatedReference {

  final Firebase reference;

  final Future<IsolateRunner> _runner;

  IsolatedReference(this.reference) : _runner = Runners.spawnIsolate();

  IsolatedReference child(String childPath) => new IsolatedReference(reference.child(childPath));

  IsolatedReference get parent => new IsolatedReference(reference.parent);

  Future set(dynamic v) => _sendReceive("set",v);

  Future update(dynamic v) => _sendReceive("update",v);

  Future remove() => _sendReceive("set",null);

  Future authWithCustomToken(String token) => _sendReceive("auth",token);

  Future _sendReceive(String command, dynamic v) async {
    var runner = await _runner;
    await runner.run(_Command.execute,new _Command(reference.url.toString(), command, v));
  }

}



class _Command {
  final String url;
  final String command;
  final dynamic value;

  _Command(this.url,this.command,this.value);

  Future exec() async {
    try {
      print("exec $url $command $value");
      switch (command) {
        case "set":
          await new Firebase(url).set(value);
          break;
        case "update":
          await new Firebase(url).update(value);
          break;
        case "auth":
          await new Firebase(url).authWithCustomToken(value);
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  static Future execute(_Command command) => command.exec();
}


