import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  group('firebase core', () => runCoreTests(isolated: false));
}

void runCoreTests({bool isolated = false}) {
  setUpAll(() async {
    await FirebaseTesting.setup(isolated: isolated);
  });

  group('Firebase', () {
    FirebaseApp? app;

    tearDown(() async {
      await app?.delete();
      app = null;
    });

    group('Firebase.initializeApp', () {
      test(
          'Firebase.initializeApp without name should create app with default name',
          () async {
        app = await Firebase.initializeApp(options: getOptions());

        expect(app!.name, '[DEFAULT]');
        expect(app!.options, getOptions());
      });

      test('Firebase.initializeApp should throw when already exists', () async {
        app = await Firebase.initializeApp(options: getOptions());
        expect(() => Firebase.initializeApp(options: getOptions()),
            throwsA(FirebaseCoreException.duplicateApp('[DEFAULT]')));
      });
    });

    group('Firebase.app', () {
      test('Firebase.app should return app when exist', () async {
        app = await Firebase.initializeApp(options: getOptions());
        expect(Firebase.app(), app);
      });
      test('Firebase.app should throw when app does not exist', () async {
        expect(() => Firebase.app(),
            throwsA(FirebaseCoreException.noAppExists('[DEFAULT]')));
      });
    });

    group('Firebase.apps', () {
      test('Firebase.apps should contain all apps', () async {
        expect(Firebase.apps, []);

        var app1 =
            await Firebase.initializeApp(options: getOptions(), name: 'app1');

        expect(Firebase.apps, [app1]);

        var app2 =
            await Firebase.initializeApp(options: getOptions(), name: 'app2');

        expect(Firebase.apps, [app1, app2]);

        await app1.delete();
        expect(Firebase.apps, [app2]);

        await app2.delete();
        expect(Firebase.apps, []);
      });
    });
  });

  group('FirebaseApp', () {
    group('FirebaseApp.delete', () {
      test('FirebaseApp.delete should call delete on services', () async {
        var app = await Firebase.initializeApp(options: getOptions());

        var service = FirebaseService(app);

        expect(service.isDeleted, isFalse);

        await app.delete();

        expect(service.isDeleted, isTrue);
      });
    });
  });

  group('FirebaseService', () {
    group('FirebaseService()', () {
      test('FirebaseService() should fail on deleted app', () async {
        var app = await Firebase.initializeApp(options: getOptions());

        await app.delete();
        expect(() => FirebaseService(app),
            throwsA(FirebaseCoreException.noAppExists(app.name)));
      });
    });
  });
}
