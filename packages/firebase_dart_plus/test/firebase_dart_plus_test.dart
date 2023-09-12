import 'package:firebase_dart/firebase_dart.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart_plus/firebase_dart_plus.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await FirebaseTesting.setup();
  });

  group('WriteBatch', () {
    late FirebaseDatabase db;
    late FirebaseApp app;

    setUp(() async {
      var options = FirebaseOptions(
          apiKey: 'apiKey',
          appId: 'my_app_id',
          projectId: 'my_project',
          messagingSenderId: 'ignore',
          databaseURL: 'mem://my_project.firebaseio.com/');

      app = await Firebase.initializeApp(name: 'app1', options: options);

      db = FirebaseDatabase(app: app);

      await db.reference().set(null);
    });

    tearDown(() async {
      await app.delete();
    });

    test('Should write to database after commit', () async {
      var batch = db.batch();

      await batch.reference().child('test').set('test');

      expect(await batch.reference().child('test').get(), 'test');
      expect(await db.reference().child('test').get(), isNull);

      await batch.commit();

      expect(await db.reference().child('test').get(), 'test');
    });

    test('Should write multiple operations', () async {
      var batch = db.batch();

      var ref = batch.reference().child('some/path');

      await ref.child('test1').set('test');
      await ref.child('test2').set('test');
      await ref.child('test3/child').set('test');

      expect(await ref.get(), {
        'test1': 'test',
        'test2': 'test',
        'test3': {'child': 'test'}
      });
      expect(await db.reference().child(ref.path).get(), isNull);

      await batch.commit();

      expect(await db.reference().child(ref.path).get(), {
        'test1': 'test',
        'test2': 'test',
        'test3': {'child': 'test'}
      });
    });

    test('Should combine commited and uncommited operations', () async {
      await db.reference().set({
        'test1': 'test',
      });
      var batch = db.batch();

      await batch.reference().child('test2').set('test');

      expect(await batch.reference().get(), {
        'test1': 'test',
        'test2': 'test',
      });
    });

    test('Should combine commited and uncommited operations with queries',
        () async {
      await db.reference().set({
        'test1': 'test',
        'test3': 'test',
      });
      var batch = db.batch();

      await batch.reference().child('test2').set('test');

      expect(await batch.reference().orderByKey().startAt('test2').get(), {
        'test2': 'test',
        'test3': 'test',
      });

      expect(
          await batch
              .reference()
              .orderByKey()
              .startAt('test2')
              .limitToFirst(1)
              .get(),
          {
            'test2': 'test',
          });
    });

    test(
        'Should get more results from server when local changes remove items from the query result',
        () async {
      await db.reference().set({
        'test1': 'test',
        'test2': 'test',
      });
      var batch = db.batch();

      await batch.reference().child('test1').remove();

      expect(
          await batch
              .reference()
              .orderByKey()
              .startAt('test1')
              .limitToFirst(1)
              .get(),
          {
            'test2': 'test',
          });
    }, skip: 'Not handled yet');

    test('Should throw when trying to commit twice', () {
      var batch = db.batch();

      batch.commit();

      expect(() => batch.commit(), throwsA(isA<StateError>()));
    });

    test('Should throw when writing to a committed batch', () {
      var batch = db.batch();

      batch.commit();

      expect(() => batch.reference().child('test').set('test'),
          throwsA(isA<StateError>()));
    });

    test('onValue should get updates from server and batch', () async {
      await db.reference().child('test').set({'hello': 'world'});

      var batch = db.batch();

      dynamic w;
      var s = batch.reference().child('test').onValue.listen((v) {
        w = v.snapshot.value;
      });

      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'world'});

      await batch.reference().child('test').child('message').set('hello');
      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'world', 'message': 'hello'});

      await db.reference().child('test').child('hello').set('hello');
      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'hello', 'message': 'hello'});

      await s.cancel();
    });

    test('onValue should not be called multiple times with same value',
        () async {
      await db.reference().child('test').set({'hello': 'world'});

      var batch = db.batch();

      dynamic w;
      int count = 0;
      var s = batch.reference().child('test').onValue.listen((v) {
        w = v.snapshot.value;
        count++;
      });

      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'world'});
      expect(count, 1);

      await batch.reference().child('test').child('message').set('hello');
      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'world', 'message': 'hello'});
      expect(count, 2);

      await db.reference().child('test').child('message').set('hello');
      await Future.delayed(Duration(milliseconds: 10));
      expect(w, {'hello': 'world', 'message': 'hello'});
      expect(count, 2);

      await s.cancel();
    });
  });
}
