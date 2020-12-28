// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/core.dart' hide Firebase;
import 'package:firebase_dart/core.dart' as core;
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../secrets.dart'
    if (dart.library.html) '../secrets.dart'
    if (dart.library.io) '../secrets_io.dart' as s;
import '../util.dart';

void main() async {
  await FirebaseTesting.setup();

  StreamSubscription logSubscription;
  setUp(() {
    Logger.root.level = Level.ALL;
    logSubscription = Logger.root.onRecord.listen(print);
  });
  tearDown(() async {
    await logSubscription.cancel();
  });

  group('mem', () {
    testsWith({'host': 'mem://test/', 'secret': 'x'});
  });

  group('https', () {
    testsWith(s.secrets);
  });

  group('FirebaseDatabase.delete', () {
    var testUrl = 'mem://test2';
    test('FirebaseDatabase.delete should trigger onDone on streams', () async {
      var app = await core.Firebase.initializeApp(
          name: 'my_app', options: getOptions());

      var db = FirebaseDatabase(app: app, databaseURL: testUrl);

      var ref = db.reference().child('test/some-key');

      var isDone = false;
      ref.onValue.listen((_) => null, onDone: () => isDone = true);

      await app.delete();

      expect(isDone, true);
    });

    test('FirebaseDatabase.delete should close transports', () async {
      var app = await core.Firebase.initializeApp(
          name: 'my_app', options: getOptions());

      var db = FirebaseDatabase(app: app, databaseURL: testUrl);
      var ref = db.reference().child('test/some-key');
      await ref.once();

      expect(
          Transport.openTransports
              .any((v) => v.url.host == Uri.parse(testUrl).host),
          isTrue);

      await app.delete();

      expect(
          Transport.openTransports
              .any((v) => v.url.host == Uri.parse(testUrl).host),
          isFalse);
    });

    test('FirebaseDatabase.delete should remove Repo', () async {
      var app = await core.Firebase.initializeApp(
          name: 'my_app', options: getOptions());

      var db = FirebaseDatabase(app: app, databaseURL: testUrl);
      var ref = db.reference().child('test/some-key');
      await ref.once();

      expect(Repo.hasInstance(db), isTrue);

      await app.delete();

      expect(Repo.hasInstance(db), isFalse);
    });

    test(
        'FirebaseDatabase.delete should not create a Repo when not already exists',
        () async {
      var app = await core.Firebase.initializeApp(
          name: 'my_app', options: getOptions());

      var db = FirebaseDatabase(app: app, databaseURL: testUrl);

      await app.delete();

      expect(Repo.hasInstance(db), isFalse);
    });

    test('FirebaseDatabase.delete should stop all timers', () async {
      var timers = <Timer, StackTrace>{};

      await runZoned(() async {
        var app = await core.Firebase.initializeApp(
            name: 'my_app', options: getOptions());

        var db = FirebaseDatabase(app: app, databaseURL: testUrl);
        var ref = db.reference().child('test/some-key');
        await ref.once();

        await app.delete();
      },
          zoneSpecification: ZoneSpecification(
            createTimer: (self, parent, zone, duration, f) {
              var timer = parent.createTimer(zone, duration, f);
              timers[timer] = StackTrace.current;
              return timer;
            },
            createPeriodicTimer: (self, parent, zone, duration, f) {
              var timer = parent.createPeriodicTimer(zone, duration, f);
              timers[timer] = StackTrace.current;
              return timer;
            },
          ));

      timers.forEach((key, value) {
        if (key.isActive) {
          fail('Timer still active: created here $value');
        }
      });
    });
  });
}

void testsWith(Map<String, dynamic> secrets) {
  var testUrl = '${secrets['host']}';

  DatabaseReference ref, ref2;

  FirebaseApp app1, app2, appAlt1, appAlt2;

  setUpAll(() async {
    var options = getOptions();
    app1 = await core.Firebase.initializeApp(name: 'app1', options: options);
    app2 = await core.Firebase.initializeApp(name: 'app2', options: options);
    appAlt1 = await core.Firebase.initializeApp(name: 'alt1', options: options);
    appAlt2 = await core.Firebase.initializeApp(name: 'alt2', options: options);
  });

  tearDownAll(() async {
    await app1.delete();
    await app2.delete();
    await appAlt1.delete();
    await appAlt2.delete();
  });

  group('Recover from connection loss', () {
    Future<void> connectionLostTests(
        FutureOr<void> Function(FirebaseDatabase db)
            connectionDestroyer) async {
      var db = FirebaseDatabase(app: app1, databaseURL: testUrl);

      var connectionStates = <bool>[];
      db
          .reference()
          .child('.info/connected')
          .onValue
          .map((s) => s.snapshot.value)
          .skipWhile((v) => !v)
          .take(2)
          .listen(connectionStates.add);
      var ref = db.reference().child('test');

      var db2 = FirebaseDatabase(app: app2, databaseURL: testUrl);
      var ref2 = db2.reference().child('test');

      await ref2.set('hello');
      await wait(200);

      expect(connectionStates, [true]);

      var f = ref.onValue
          .map((v) {
            return v.snapshot.value;
          })
          .take(2)
          .toList();

      await wait(200);

      await connectionDestroyer(db);

      await wait(200);
      expect(connectionStates, [true, false]);

      await ref2.set('world');

      expect(await f, ['hello', 'world']);
    }

    test('Recover when internet connection broken',
        () => connectionLostTests((db) => Repo(db).mockConnectionLost()));
    test('Recover when reset message received',
        () => connectionLostTests((db) => Repo(db).mockResetMessage()));
  });

  group('Reference location', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl).reference();
      ref2 = ref.child('test');
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
      expect(ref.child('test').parent().key, null);
      expect(ref.child('test/hello').parent().key, 'test');
    });
    test('root', () {
      expect(ref.child('test').root().key, null);
      expect(ref.child('test/hello').root().key, null);
    });
  });
  group('Authenticate', () {
    String token, uid;
    setUp(() {
      var host = secrets['host'];
      var secret = secrets['secret'];

      if (host == null || secret == null) {
        print('Cannot test Authenticate: set a host and secret.');
        return;
      }

      uid = 'pub-test-01';
      var authData = {'uid': uid, 'debug': true, 'provider': 'custom'};
      var codec = FirebaseTokenCodec(secret);
      token = codec.encode(FirebaseToken(authData));

      ref = FirebaseDatabase(app: app1, databaseURL: host).reference();
    });

    test('auth/unauth', () async {
      var fromStream = ref.onAuth.first;
      await ref.authWithCustomToken(token);

      expect((await fromStream)['uid'], uid);
      expect(ref.auth['uid'], uid);

      fromStream = ref.onAuth.first;

      await ref.unauth();

      expect((await fromStream), isNull);
      expect(ref.auth, isNull);
    });

    test('permission denied', () async {
      if (ref.url.scheme == 'mem') {
        // TODO
        return;
      }
      ref = ref.child('test-protected');
      ref.onValue.listen((e) => print(e.snapshot.value));
      await ref.authWithCustomToken(token);
      await ref.set('hello world');
      expect(await ref.get(), 'hello world');
      await ref.unauth();
      await expectLater(() => ref.set('hello all'), throwsException);
      expect(await ref.get(), 'hello world');
    });
    test('token', () {
      var token =
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJlbWFpbCI6InJpa0BwYXJ0YWdvLmJlIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJpYXQiOjE0NzIxMjIyMzgsInYiOjAsImQiOnsicHJvdmlkZXIiOiJwYXNzd29yZCIsInVpZCI6IjMzZTc1ZjI0LTE5MTAtNGI1Mi1hZDJjLWNmZGQwYWFjNzI4YiJ9fQ.ZO0zH6xgk58SKDqmqi9gWzsvzoSvPx6QCJizR94rzEc';
      var t = (FirebaseTokenCodec(null).decode(token));
      print(t.toJson());
    });
  });

  group('Snapshot', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test')
          .child('snapshot');
    });

    test('Child', () async {
      await ref.set({'hello': 'world'});

      var e = await ref.onValue.first;

      var s = e.snapshot;
      expect(s.key, 'snapshot');
      expect(s.value, {'hello': 'world'});
    });
  });

  group('Listen', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test')
          .child('listen');
    });

    test('Initial value', () async {
      print(await ref.get());
    });

    test('Value after set', () async {
      var v = 'Hello world ${Random().nextDouble()}';
      await ref.set(v);
      print('set to $v');
      expect(await ref.get(), v);
      print('got value');
      await ref.set('Hello all');
      print('set to Hello all');
      expect(await ref.get(), 'Hello all');
    });

    test('Set object', () async {
      await ref.set({
        'object': {'hello': 'world'}
      });
      ref.onValue.listen((_) {});

      expect(await ref.child('object/hello').get(), 'world');

      await ref.set({
        'object': {'hello': 'all', 'something': 'else'}
      });

      expect(await ref.child('object/hello').get(), 'all');
    });

    test('Multiple listeners on on*-stream', () async {
      await (ref.set('hello world'));

      var onValue = ref.onValue;

      expect((await onValue.first).snapshot.value, 'hello world');
      expect((await onValue.first).snapshot.value, 'hello world');
    });

    test('Child added', () async {
      await (ref.remove());

      var keys = ref.onChildAdded.take(2).map((e) => e.snapshot.key).toList();
      await ref.get();

      await ref.child('hello').set('world');
      await ref.child('hi').set('everyone');

      expect(await keys, ['hello', 'hi']);
    });

    test(
        'Child added/removed when query changes from contained to not contained',
        () async {
      await ref.set({
        'key-001': 1,
        'key-002': 2,
        'key-004': 4,
      });

      var s = ref.orderByKey().limitToFirst(3).onValue.listen((event) {});

      var childrenAdded = [];
      var childrenRemoved = [];
      var s2 = ref
          .orderByKey()
          .startAt('key-002')
          .limitToFirst(2)
          .onChildAdded
          .listen((event) {
        var k = event.snapshot.key;
        expect(childrenAdded.contains(k), false);
        childrenAdded.add(event.snapshot.key);
      });

      var s3 = ref
          .orderByKey()
          .startAt('key-002')
          .limitToFirst(2)
          .onChildRemoved
          .listen((event) {
        childrenRemoved.add(event.snapshot.key);
      });

      await ref.orderByKey().limitToFirst(3).get();
      await Future.value();
      expect(childrenAdded, ['key-002', 'key-004']);
      expect(childrenRemoved, []);

      await ref.child('key-000').set(0);
      await ref.orderByKey().startAt('key-002').limitToFirst(2).get();
      await Future.value();
      expect(childrenAdded, ['key-002', 'key-004']);
      expect(childrenRemoved, []);

      await ref.child('key-003').set(3);

      await ref.orderByKey().startAt('key-002').limitToFirst(2).get();
      await Future.value();
      expect(childrenAdded, ['key-002', 'key-004', 'key-003']);
      expect(childrenRemoved, ['key-004']);

      await s.cancel();
      await s2.cancel();
      await s3.cancel();
    });

    test('Child removed', () async {
      await ref.set({'hello': 'world', 'hi': 'everyone'});

      var keys = ref.onChildRemoved.take(2).map((e) => e.snapshot.key).toList();
      await ref.get();

      await ref.update({'test': 'something', 'hello': null});
      await ref.child('hi').remove();

      expect(await keys, ['hello', 'hi']);
    });

    test('Child changed', () async {
      await ref.set({'hello': 'world', 'hi': 'everyone'});

      var keys = ref.onChildChanged.take(2).map((e) => e.snapshot.key).toList();
      await ref.get();

      await ref.child('hello').set('world2');
      await ref.child('hi').set('everyone2');

      expect(await keys, ['hello', 'hi']);
    });

    test('Child moved', () async {
      await ref.set({
        'hello': 'world',
        'hi': 'everyone',
      });

      var f = ref
          .orderByValue()
          .onChildMoved
          .where((e) => e.prevChild != null)
          .first;

      await ref.get();

      expect((await ref.orderByValue().get()).keys, ['hi', 'hello']);

      await ref.child('hello').set('abc');

      var e = await f;

      expect(e.snapshot.key, 'hi');
      expect(e.prevChild, 'hello');
    });
  });

  group('Push/Merge/Remove', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test')
          .child('push-merge-remove');
    });

    test('Remove', () async {
      await ref.set('hello');
      expect(await ref.get(), 'hello');
      await ref.set(null);
      expect((await ref.once()).value, isNull);
    });

    test('Merge', () async {
      await ref.set({'text1': 'hello1'});
      expect(await ref.get(), {'text1': 'hello1'});
      await ref.update({'text2': 'hello2', 'text3': 'hello3'});

      expect(await ref.get(),
          {'text1': 'hello1', 'text2': 'hello2', 'text3': 'hello3'});

      await ref.child('text1/hello').set('world');

      expect(await ref.get(), {
        'text1': {'hello': 'world'},
        'text2': 'hello2',
        'text3': 'hello3'
      });

      await ref.update({'text1/hello': null});

      expect(await ref.get(), {'text2': 'hello2', 'text3': 'hello3'});
    });

    test('Push', () async {
      await ref.set({'text1': 'hello1'});
      expect(await ref.get(), {'text1': 'hello1'});
      var childRef = ref.push();
      await childRef.set('hello2');
      expect(await childRef.get(), 'hello2');
    });
  });

  group('Special characters', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test')
          .child('special-chars');
    });

    test('colon', () async {
      await ref.child('users').child('facebook:12345').set({'name': 'me'});

      expect(await ref.child('users/facebook:12345/name').get(), 'me');
    });

    test('spaces', () async {
      await ref.child('users').set(null);
      await ref.child('users').child('Jane Doe').set({'name': 'Jane'});

      expect(ref.child('users').child('Jane Doe').key, 'Jane Doe');

      expect(
          await ref.child('users').child('Jane Doe').get(), {'name': 'Jane'});
      expect(await ref.child('users').get(), {
        'Jane Doe': {'name': 'Jane'}
      });
    });
  });

  group('ServerValue', () {
    test('timestamp', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/server-values/timestamp');
      await ref.set(null);
      var events = <Event>[];
      ref.onValue.listen(events.add);

      await ref.get();

      await ref.set(ServerValue.timestamp);

      await Future.delayed(Duration(seconds: 1));
      var values = events.map((e) => e.snapshot.value).toList();
      print(values);
      expect(values.length, 3);
      expect(values[0], null);

      expect(values[1] is num, isTrue);
      expect(values[2] is num, isTrue);
      expect(values[2] - values[1] > 0, isTrue);
      expect(values[2] - values[1] < 1000, isTrue);

      await ref.set({'hello': 'world', 'it is now': ServerValue.timestamp});

      print(await ref.child('it is now').get());
      expect(await ref.child('it is now').get() is num, isTrue);
    });

    test('transaction', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/server-values/transaction');
      await ref.set('hello');

      await Stream.periodic(Duration(milliseconds: 10)).take(10).forEach((_) {
        ref.runTransaction((v) {
          return v..value = ServerValue.timestamp;
        });
      });

      await Future.delayed(Duration(seconds: 1));

      expect(await ref.get() is num, isTrue);
    });
  });

  group('Transaction', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/transactions');
    });

    test('Counter', () async {
      await ref.set(0);

      ref.onValue.listen((e) => print('onValue ${e.snapshot.value}'));
      await ref.onValue.first;
      var f1 = Stream.periodic(Duration(milliseconds: 10))
          .take(10)
          .map((i) => ref.runTransaction((v) => v..value = (v.value ?? 0) + 1))
          .toList();
      var f2 = Stream.periodic(Duration(milliseconds: 50))
          .take(10)
          .map((i) => ref.runTransaction((v) => v..value = (v.value ?? 0) + 1))
          .toList();

      await Future.wait((await f1)..addAll(await f2));

      expect(await ref.get(), 20);
    });

    test('Counter in tree', () async {
      await ref.child('object/count').set(0);

      var f1 = Stream.periodic(Duration(milliseconds: 10))
          .take(10)
          .map((i) => ref
              .child('object/count')
              .runTransaction((v) => v..value = (v.value ?? 0) + 1))
          .toList();
      var f2 = Stream.periodic(Duration(milliseconds: 50))
          .take(10)
          .map((i) => ref.runTransaction((v) {
                v.value ??= {};
                v.value
                    .putIfAbsent('object', () => {})
                    .putIfAbsent('count', () => 0);
                v.value['object']['count']++;
                return v;
              }))
          .toList();
      var f3 = Stream.periodic(Duration(milliseconds: 30))
          .take(10)
          .map((i) => ref.child('object').runTransaction((v) {
                v.value ??= {};
                v.value.putIfAbsent('count', () => 0);
                v.value['count']++;
                return v;
              }))
          .toList();

      await Future.wait((await f1)..addAll(await f2)..addAll(await f3));

      expect(await ref.child('object/count').get(), 30);
    });

    test('Abort', () async {
      await ref.child('object/count').set(0);

      var futures = <Future>[];
      for (var i = 0; i < 10; i++) {
        futures.add(ref.child('object/count').runTransaction((v) {
          print('run $i ${v.value}');
          return v..value = (v.value ?? 0) + 1;
        }).then((v) {
          expect(v.committed, isTrue);
          expect(v.dataSnapshot.value, i + 1);
        }));
      }
      for (var i = 0; i < 10; i++) {
        futures.add(ref.child('object').runTransaction((v) {
          v.value ??= {};
          v.value.putIfAbsent('count', () => 0);
          v.value['count']++;
          return v;
        }).then((v) {
          expect(v.committed, isFalse);
          expect(v.error, FirebaseDatabaseException.overriddenBySet());
        }));
      }
      futures.add(ref.child('object/test').set('hello'));

      await Future.wait(futures);

      await wait(400);

      expect(await ref.child('object/count').get(), 10);
    });
  });

  group('OnDisconnect', () {
    Repo repo;
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/disconnect');
      repo = Repo(FirebaseDatabase(app: app1, databaseURL: testUrl));
    });

    test('put', () async {
      await ref.set('hello');

      await ref.onDisconnect.set('disconnected');

      await repo.triggerDisconnect();

      await Future.delayed(Duration(milliseconds: 200));

      expect(await ref.get(), 'disconnected');
    });
    test('merge', () async {
      await ref.set({'hello': 'world'});
      ref.child('state').onValue.listen((_) {});

      await ref.onDisconnect.update({'state': 'disconnected'});

      await repo.triggerDisconnect();

      await Future.delayed(Duration(milliseconds: 200));

      expect(await ref.child('state').get(), 'disconnected');
    });
    test('cancel', () async {
      await ref.set({'hello': 'world'});

      await ref.onDisconnect.update({'state': 'disconnected'});

      await ref.onDisconnect.cancel();

      await repo.triggerDisconnect();

      await Future.delayed(Duration(milliseconds: 200));

      expect(await ref.child('state').get(), null);
    });
  });

  group('Query', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/query');
    });

    test('Limit', () async {
      await ref.set({'text1': 'hello1', 'text2': 'hello2', 'text3': 'hello3'});

      expect(await ref.limitToFirst(1).get(), {'text1': 'hello1'});

      expect(await ref.limitToFirst(2).get(), {
        'text1': 'hello1',
        'text2': 'hello2',
      });

      expect(await ref.limitToLast(1).get(), {'text3': 'hello3'});

      expect(await ref.limitToLast(2).get(),
          {'text2': 'hello2', 'text3': 'hello3'});
    });

    test('Order by value', () async {
      await ref.set({'text1': 'b', 'text2': 'c', 'text3': 'a'});

      var q = ref.orderByValue();

      expect(await q.limitToFirst(1).get(), {'text3': 'a'});

      expect(await q.limitToFirst(2).get(), {'text3': 'a', 'text1': 'b'});

      expect(await q.limitToLast(1).get(), {'text2': 'c'});

      expect(await q.limitToLast(2).get(), {'text1': 'b', 'text2': 'c'});

      expect(await q.startAt('b').get(), {'text1': 'b', 'text2': 'c'});

      expect(await q.startAt('b', 'text1').get(), {'text1': 'b', 'text2': 'c'});

      expect(await q.startAt('b', 'text2').get(), {'text2': 'c'});
    });

    test('Order by key', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/query-key');
      await ref.set({'text2': 'b', 'text1': 'c', 'text3': 'a'});

      var q = ref.orderByKey();

      expect(await q.limitToFirst(1).get(), {'text1': 'c'});

      expect(await q.limitToFirst(2).get(), {'text1': 'c', 'text2': 'b'});

      expect(await q.limitToLast(1).get(), {'text3': 'a'});

      expect(await q.limitToLast(2).get(), {'text2': 'b', 'text3': 'a'});

      expect(await q.startAt('text2').get(), {'text2': 'b', 'text3': 'a'});
    });

    test('Order by priority', () async {
      await ref.set({'text2': 'b', 'text1': 'c', 'text3': 'a'});
      await ref.child('text1').setPriority(2);
      await ref.child('text2').setPriority(1);
      await ref.child('text3').setPriority(3);

      await wait(500);

      var q = ref.orderByPriority();

      expect(await q.limitToFirst(1).get(), {'text2': 'b'});

      expect(await q.limitToFirst(2).get(), {'text2': 'b', 'text1': 'c'});

      expect(await q.limitToLast(1).get(), {'text3': 'a'});

      expect(await q.limitToLast(2).get(), {'text1': 'c', 'text3': 'a'});

      expect(await q.startAt(2).get(), {'text1': 'c', 'text3': 'a'});

      expect(await q.startAt(2, 'text1').get(), {'text1': 'c', 'text3': 'a'});

      expect(await q.startAt(2, 'text2').get(), {'text3': 'a'});
    });
    test('Order by child', () async {
      await ref.set({
        'text2': {'order': 'b'},
        'text1': {'order': 'c'},
        'text3': {'order': 'a'}
      });

      var q = ref.orderByChild('order');

      expect(await q.limitToFirst(1).get(), {
        'text3': {'order': 'a'}
      });

      expect(await q.limitToFirst(2).get(), {
        'text3': {'order': 'a'},
        'text2': {'order': 'b'}
      });

      expect(await q.limitToLast(1).get(), {
        'text1': {'order': 'c'}
      });

      expect(await q.limitToLast(2).get(), {
        'text2': {'order': 'b'},
        'text1': {'order': 'c'}
      });

      expect(await q.startAt('b').get(), {
        'text2': {'order': 'b'},
        'text1': {'order': 'c'}
      });

      expect(await q.startAt('b', 'text2').get(), {
        'text2': {'order': 'b'},
        'text1': {'order': 'c'}
      });

      expect(await q.startAt('b', 'text3').get(), {
        'text1': {'order': 'c'}
      });
    });
    test('Order by grandchild', () async {
      await ref.set({
        'text2': {
          'order': {'x': 'b'}
        },
        'text1': {
          'order': {'x': 'c'}
        },
        'text3': {
          'order': {'x': 'a'}
        }
      });

      var q = ref.orderByChild('order/x');

      expect(await q.limitToFirst(1).get(), {
        'text3': {
          'order': {'x': 'a'}
        }
      });
    });
    test('Order after remove', () async {
      var iref = FirebaseDatabase(app: appAlt2, databaseURL: testUrl)
          .reference()
          .child(ref.url.path);

      await iref.set({
        'text2': {'order': 'b'},
        'text1': {'order': 'c'},
        'text3': {'order': 'a'}
      });

      await wait(500);

      var q = ref.orderByChild('order');
      var l = q
          .startAt('b')
          .limitToFirst(1)
          .onValue
          .map((e) => e.snapshot.value?.keys?.single)
          .where((v) =>
              v !=
              null) // returns null first when has index on order otherwise not
          .take(2)
          .toList();

      await Future.delayed(Duration(milliseconds: 200));
      await iref.child('text2').remove();
      await Future.delayed(Duration(milliseconds: 500));

      expect(await l, ['text2', 'text1']);
    });

    test('Start/End at', () async {
      await ref.set({
        'text2': {'order': 'b'},
        'text1': {'order': 'c'},
        'text3': {'order': 'a'},
        'text4': {'order': 'e'},
        'text5': {'order': 'd'},
        'text6': {'order': 'b'}
      });

      var q = ref.orderByChild('order');

      expect(await q.startAt('b').endAt('c').get(), {
        'text2': {'order': 'b'},
        'text6': {'order': 'b'},
        'text1': {'order': 'c'}
      });

      expect(await q.startAt('b', 'text6').endAt('c').get(), {
        'text6': {'order': 'b'},
        'text1': {'order': 'c'}
      });

      await ref.set({
        'text2': {'order': 2},
        'text1': {'order': 3},
        'text3': {'order': 1},
        'text4': {'order': 5},
        'text5': {'order': 4},
        'text6': {'order': 2}
      });
      q = ref.orderByChild('order');

      expect((await q.equalTo(2).get()).keys, ['text2', 'text6']);
    });

    test('Ordering', () async {
      await ref.set({
        'b': {'order': true},
        'c': {'x': 1},
        'a': {'order': 4},
        'e': {'order': -2.3},
        'i': {'order': 'def'},
        'g': {'order': 5},
        'j': {
          'order': {'x': 1}
        },
        'd': {'order': 7.1},
        '23a': {'order': 5},
        'h': {'order': 'abc'},
        'f': {'order': 5},
        '25': {'order': 5},
        'k': {'order': false},
      });
      var q = ref.orderByChild('order');
      expect((await q.get()).keys,
          ['c', 'k', 'b', 'e', 'a', '25', '23a', 'f', 'g', 'd', 'h', 'i', 'j']);
    });

    group('local filtering', () {
      test('local filtering by key', () async {
        await ref.set({
          'key-001': 1,
          'key-002': 2,
          'key-003': 3,
        });

        var query = ref.orderByKey();

        var s = query.limitToFirst(2).onValue.listen((event) {});
        await query.limitToFirst(2).get();

        var v = await query.startAt('key-002').limitToFirst(2).get();

        expect(v, {'key-002': 2, 'key-003': 3});

        await s.cancel();
      });
      test('local filtering by child', () async {
        await ref.set({
          'key-001': 1,
          'key-002': 2,
          'key-003': 3,
        });

        var query = ref.orderByChild('child');

        var s = query.limitToFirst(2).onValue.listen((event) {});
        await query.limitToFirst(2).get();

        var v = await query.startAt(null, 'key-002').limitToFirst(2).get();

        expect(v, {'key-002': 2, 'key-003': 3});

        await s.cancel();
      });

      test('local filtering by priority', () async {
        await ref.set({
          'key-001': 1,
          'key-002': 2,
          'key-003': 3,
        });

        var query = ref.orderByPriority();

        var s = query.limitToFirst(2).onValue.listen((event) {});
        await query.limitToFirst(2).get();

        var v = await query.startAt(null, 'key-002').limitToFirst(2).get();

        expect(v, {'key-002': 2, 'key-003': 3});

        await s.cancel();
      });
    });
  });

  group('multiple frames', () {
    setUp(() {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/frames');
    });

    test('Receive large value', () async {
      var random = Random();

      var value =
          base64.encode(List<int>.generate(15000, (i) => random.nextInt(255)));
      await ref.set(value);

      expect(await ref.get(), value);
    });
    test('Send large value', () async {
      var random = Random();

      var value =
          base64.encode(List<int>.generate(50000, (i) => random.nextInt(255)));
      await ref.set(value);

      expect(await ref.get(), value);
    });
  });

  group('Complex operations', () {
    DatabaseReference iref;
    setUp(() async {
      ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/complex');
      iref = FirebaseDatabase(app: appAlt1, databaseURL: testUrl)
          .reference()
          .child('test/complex');
    });

    test('Remove out of view', () async {
      await iref.set({'text1': 'b', 'text2': 'c', 'text3': 'a'});

      await wait(500);

      var l = ref
          .orderByKey()
          .limitToFirst(2)
          .onValue
          .map((e) => e.snapshot.value?.keys?.first)
          .take(4)
          .toList();

      await wait(500);

      await iref.child('text0').set('d');
      await iref.child('text1').remove();
      await iref.child('text0').remove();

      expect(await l, ['text1', 'text0', 'text0', 'text2']);
    });

    test('Upgrade subquery to master view', () async {
      await iref.set({'text1': 'b', 'text2': 'c', 'text3': 'a'});

      var s1 = ref.orderByKey().limitToFirst(1).onValue.listen(print);
      var l = ref
          .orderByKey()
          .startAt('text2')
          .limitToFirst(1)
          .onValue
          .expand((e) => e.snapshot.value?.values ?? [])
          .take(2)
          .toList();

      await wait(500);

      await s1.cancel();

      await iref.child('text2').remove();

      expect(await l, ['c', 'a']);
    });

    test('Listen to child after parent', () async {
      await iref.set({'text1': 'b', 'text2': 'c', 'text3': 'a'});

      var s1 = ref
          .orderByKey()
          .limitToFirst(2)
          .onValue
          .map((e) => e.snapshot.value)
          .listen(print);

      await wait(500);

      expect(await ref.child('text2').get(), 'c');
      var l = ref
          .child('text2')
          .onValue
          .map((v) {
            print(v.snapshot.value);
            return v;
          })
          .map((e) => e.snapshot.value)
          .take(3)
          .toList();

      await iref.child('text2').set('x');

      await wait(500);
      await s1.cancel();

      await iref.child('text2').remove();

      expect(await l, ['c', 'x', null]);
    });

    test('startAt increasing', () async {
      await iref.set({'10': 10, '20': 20, '30': 30});

      var s = Stream.periodic(Duration(milliseconds: 20), (i) => i).take(30);

      await for (var i in s) {
        await ref.orderByKey().startAt('$i').limitToFirst(1).get();
      }
    });

    test('parent with filter', () async {
      await iref.set({
        'child1': 'hello world',
        'child2': {'a': 1, 'b': 2, 'c': 3}
      });

      var sub = ref.orderByKey().limitToFirst(1).onValue.listen(print);

      await Future.delayed(Duration(milliseconds: 500));

      var l = ref
          .child('child2')
          .orderByKey()
          .startAt('b')
          .limitToFirst(1)
          .onValue
          .map((e) => e.snapshot.value?.keys?.first)
          .take(2)
          .toList();

      await Future.delayed(Duration(milliseconds: 500));

      await iref.child('child2').child('b').remove();

      expect(await l, ['b', 'c']);

      await sub.cancel();
    });

    test('complete from parent', () async {
      await iref.set({
        'child1': 'hello world',
        'child2': {'a': 1, 'b': 2, 'c': 3}
      });

      var sub = ref.orderByKey().onValue.listen(print);
      var sub2 = ref
          .child('child2')
          .orderByKey()
          .limitToFirst(1)
          .onValue
          .listen(print);
      await wait(500);

      var l = ref
          .child('child2')
          .child('b')
          .onValue
          .map((e) => e.snapshot.value)
          .take(3)
          .toList();

      await sub.cancel();
      await wait(200);

      await iref.child('child2').child('b').set(4);
      await wait(200);

      await iref.child('child2').child('b').set(5);
      expect(await l, [2, 4, 5]);

      await sub2.cancel();
    });

    test('with canceled parent', () async {
      var sub = ref.root().onValue.listen((v) => print(v.snapshot.value),
          onError: (e) => print('error $e'));
      await wait(400);

      await iref.set('hello world');

      expect(await ref.get(), 'hello world');

      await iref.set('hello all');
      await wait(400);
      expect(await ref.get(), 'hello all');

      await sub.cancel();
    });

    test('Listen, set parent and get child', () async {
      var testUrl = '${s.secrets['host']}';
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test');
      ref
          .child('cars')
          .onValue
          .listen((e) => print('on value ${e.snapshot.value}'));

      var data = {
        'cars': {
          'car001': {'name': 'Car 001'},
          'car002': {'name': 'Car 002'}
        }
      };
      await ref.set(data);

      expect(await ref.child('cars/car001').get(), data['cars']['car001']);
    });

    test('Bugfix: crash when receiving merge', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test')
          .child('some/path');

      ref.parent().orderByKey().equalTo('path').onValue.listen(print);
      ref.child('child1').onValue.listen(print);
      await ref.set({'child1': 'v', 'child2': 3});

      await ref.update({'hello': 'world'});
    });
  });

  group('Bugs', () {
    test('Initial events should not be dispatched to existing observers',
        () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/duplicate-events');

      await ref.set('hello');
      var completer = Completer();

      // register an observer
      ref.onValue.listen((v) {
        // this throws an error when executed multiple times
        completer.complete(v);
      });

      // wait until first event received
      await completer.future;

      // register a new observer -> should not trigger an event for the original observer
      await ref.get();
    });

    test('Server values should resolve once', () async {
      // create a reference with a dedicated connection
      var ref1 = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/duplicate-server-values-write');

      // create another reference with another connection
      var ref2 = FirebaseDatabase(app: app2, databaseURL: testUrl)
          .reference()
          .child('test/bugs/duplicate-server-values-write');

      // set a server value
      await ref1.set(ServerValue.timestamp);

      var v1 = await ref1.get();
      var v2 = await ref2.get();
      // the server value should resolve to the same value
      expect(v1, v2);

      // a third connection should also have the same value
      var ref3 = FirebaseDatabase(app: appAlt1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/duplicate-server-values-write');
      var v3 = await ref3.get();
      expect(v3, v1);
    });

    test('merge in mem', () async {
      // create a reference with a dedicated connection
      var ref1 = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/merge');

      // create another reference with another connection
      var ref2 = FirebaseDatabase(app: app2, databaseURL: testUrl)
          .reference()
          .child('test/bugs/merge');

      var v = {'hello': 'world', 'hi': 'everyone'};
      await ref1.update(v);

      expect(await ref1.get(), v);
      expect(await ref2.get(), v);

      // a third connection should also have the same value
      var ref3 = FirebaseDatabase(app: appAlt1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/merge');
      var v3 = await ref3.get();
      expect(v3, v);
    });

    test('Should receive server value then ack', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/ack');

      await ref.set(null);

      var l = [];
      var s = ref.onValue.listen((v) => l.add(v.snapshot.value));

      await ref.get();
      await ref.runTransaction((v) => v..value = 42);
      await ref.get();
      expect(l, [null, 42]);

      await s.cancel();
    });
    test('Should receive server value then ack: bis', () async {
      var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
          .reference()
          .child('test/bugs/ack');
      await ref.set(null);

      var events = <String>[];

      ref.onChildAdded.map((e) => 'add ${e.snapshot.value}').listen(events.add);
      ref.onChildRemoved
          .map((e) => 'remove ${e.snapshot.value}')
          .listen(events.add);
      await Future.wait([
        ref.push().set('test-value-1'),
        ref.push().set('test-value-2'),
        ref.push().set('test-value-3'),
        ref.push().set('test-value-4'),
        wait(100),
      ]);

      expect(events, [
        'add test-value-1',
        'add test-value-2',
        'add test-value-3',
        'add test-value-4',
      ]);
    });
  });

  group('Tests from firebase-android-sdk', () {
    group('FirebaseDatabase', () {
      core.FirebaseApp app;
      setUp(() async {
        app = await core.Firebase.initializeApp(
            options: FirebaseOptions(
                apiKey: 'apikey',
                appId: 'appid',
                messagingSenderId: 'messagingSenderId',
                projectId: 'projectId',
                databaseURL: null));
      });

      tearDown(() async {
        await app.delete();
      });
      test('get database for invalid urls', () async {
        expect(() => FirebaseDatabase(app: app, databaseURL: null),
            throwsArgumentError);
        expect(() => FirebaseDatabase(app: app, databaseURL: 'not-a-url'),
            throwsArgumentError);
        expect(
            () => FirebaseDatabase(
                app: app,
                databaseURL: 'http://x.fblocal.com:9000/paths/are/not/allowed'),
            throwsArgumentError);
      });
      test('reference equality for database', () async {
        var db1 = FirebaseDatabase(app: app1, databaseURL: testUrl);
        var db2 = FirebaseDatabase(app: app2, databaseURL: testUrl);
        var altDb = FirebaseDatabase(app: appAlt1, databaseURL: testUrl);

        var testRef1 = db1.reference();
        var testRef2 = db1.reference().child('foo');
        var testRef3 = altDb.reference();

        var testRef5 = db2.reference();
        var testRef6 = db2.reference();

        // Referential equality
        expect(testRef2.database, testRef1.database);
        expect(testRef3.database, isNot(testRef1.database));
        expect(testRef5.database, isNot(testRef1.database));
        expect(testRef6.database, isNot(testRef1.database));

        // Same config yields same firebase
        expect(testRef6.database, testRef5.database);
      });

      test('purgeOutstandingWrites purges all writes', () async {
        var db = FirebaseDatabase(app: app1, databaseURL: testUrl);
        var ref = db.reference().child('test/purge');

        await ref.set(null);
        await ref.get();
        await db.goOffline();

        var refs = List.generate(4, (_) => ref.push());

        var events = <String>[];
        refs.forEach((ref) =>
            ref.onValue.map((e) => e.snapshot.value).listen(events.add));

        for (var r in refs) {
          expect(() => r.set('test-value-${refs.indexOf(r)}'),
              throwsFirebaseDatabaseException());
        }
        await Future.microtask(() => null);

        await db.purgeOutstandingWrites();

        await wait(100);
        expect(events, [
          null,
          null,
          null,
          null,
          'test-value-0',
          'test-value-1',
          'test-value-2',
          'test-value-3',
          null,
          null,
          null,
          null
        ]);

        await db.goOnline();
        expect(await ref.get(), null);
      });

      test('purgeOutstandingWrites cancels transactions', () async {
        var db = FirebaseDatabase(app: app1, databaseURL: testUrl);
        var ref = db.reference().child('test/purge');

        var events = <String>[];

        ref.onValue.listen((e) => events.add('value-${e.snapshot.value}'));

        // Make sure the first value event is fired
        expect(await ref.get(), null);

        await db.goOffline();

        var t1 = ref.runTransaction((data) {
          return data..value = 1;
        });
        var t2 = ref.runTransaction((data) {
          return data..value = 2;
        });

        await Future.microtask(() => null);

        expect(events, [
          'value-null',
          'value-1',
          'value-2',
        ]);

        await db.purgeOutstandingWrites();

        await wait(200);

        expect((await t1).error, FirebaseDatabaseException.writeCanceled());
        expect((await t2).error, FirebaseDatabaseException.writeCanceled());

        expect(await ref.get(), null);

        expect(events.last, 'value-null');

        await db.goOnline();
      });
    });
    group('Transaction', () {
      test('new value is immediately visible', () async {
        var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
            .reference()
            .child('test/transaction/foo');

        var r = await ref.runTransaction((currentData) {
          return currentData..value = 42;
        });

        expect(r.committed, true);
        expect(r.error, isNull);

        expect(await ref.get(), 42);
      });

      test('event is raised for new value', () async {
        var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
            .reference()
            .child('test/transaction/foo2');

        await ref.set(null);

        var l = [];
        var s = ref.onValue.listen((v) => l.add(v.snapshot.value));

        await ref.get();

        await ref.runTransaction((currentData) {
          return currentData..value = 42;
        });

        await ref.get();
        expect(l, [null, 42]);
        await s.cancel();
      });
      test('aborted transaction sets commited to false', () async {
        var ref = FirebaseDatabase(app: app1, databaseURL: testUrl)
            .reference()
            .child('test/transaction/foo3');
        await ref.set(null);
        var r = await ref.runTransaction((currentData) => null);

        expect(r.error, isNull);
        expect(r.committed, isFalse);
        expect(r.dataSnapshot, isNull);
      });
    });
  });
}

Matcher throwsFirebaseDatabaseException() =>
    throwsA(TypeMatcher<FirebaseDatabaseException>());

Future wait(int millis) async => Future.delayed(Duration(milliseconds: millis));
