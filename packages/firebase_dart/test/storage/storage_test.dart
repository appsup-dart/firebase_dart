import 'dart:typed_data';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/backend/memory_backend.dart';
import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/src/storage/metadata.dart';
import 'package:test/test.dart';

void main() {
  return runStorageTests(isolated: false);
}

void runStorageTests({bool isolated = false}) async {
  var tester = await Tester.create(isolated: isolated);
  var app = tester.app;
  var storage = FirebaseStorage.instanceFor(app: app);
  var root = storage.ref();
  var child = root.child('hello');

  group('FirebaseStorage', () {
    group('FirebaseStorage.refFromURL', () {
      test('FirebaseStorage.refFromURL: root', () {
        var ref = storage.refFromURL('gs://test-bucket/');
        expect(ref.toString(), 'gs://test-bucket/');
      });
      test(
          'FirebaseStorage.refFromURL: keeps characters after ? on a gs:// string',
          () {
        var ref = storage.refFromURL('gs://test-bucket/this/ismyobject?hello');
        expect(ref.toString(), 'gs://test-bucket/this/ismyobject?hello');
      });
      test('FirebaseStorage.refFromURL: doesn\'t URL-decode on a gs:// string',
          () {
        var ref = storage.refFromURL('gs://test-bucket/%3F');
        expect(ref.toString(), 'gs://test-bucket/%3F');
      });
      test(
          'FirebaseStorage.refFromURL: ignores URL params and fragments on an http URL',
          () {
        var ref = storage.refFromURL(
            'http://firebasestorage.googleapis.com/v0/b/test-bucket/o/my/object.txt?ignoreme#please');
        expect(ref.toString(), 'gs://test-bucket/my/object.txt');
      });
      test(
          'FirebaseStorage.refFromURL: URL-decodes and ignores fragment on an http URL',
          () {
        var ref = storage.refFromURL(
            'http://firebasestorage.googleapis.com/v0/b/test-bucket/o/%3F?ignore');
        expect(ref.toString(), 'gs://test-bucket/?');
      });
      test(
          'FirebaseStorage.refFromURL: ignores URL params and fragments on an https URL',
          () {
        var ref = storage.refFromURL(
            'http://firebasestorage.googleapis.com/v0/b/test-bucket/o/my/object.txt?ignoreme#please');
        expect(ref.toString(), 'gs://test-bucket/my/object.txt');
      });
      test(
          'FirebaseStorage.refFromURL: URL-decodes and ignores fragment on an https URL',
          () {
        var ref = storage.refFromURL(
            'http://firebasestorage.googleapis.com/v0/b/test-bucket/o/%3F?ignore');
        expect(ref.toString(), 'gs://test-bucket/?');
      });
      test('FirebaseStorage.refFromURL: Strips trailing slash', () {
        var ref = storage.refFromURL('gs://test-bucket/foo/');
        expect(ref.toString(), 'gs://test-bucket/foo');
      });
    });
  });

  group('StorageReference', () {
    group('StorageReference.getParent', () {
      test('StorageReference.getParent: Returns null at root', () {
        expect(root.parent, isNull);
      });
      test('StorageReference.getParent: Returns root one level down', () {
        expect(child.parent, root);
        expect(child.parent.toString(), 'gs://test-bucket/');
      });
      test('StorageReference.getParent: Works correctly with empty levels', () {
        var ref = storage.refFromURL('gs://test-bucket/a///');
        expect(ref.parent.toString(), 'gs://test-bucket/a/');
      });
    });

    group('StorageReference.getRoot', () {
      test('StorageReference.getRoot: Returns self at root', () {
        expect(root.root, root);
      });
      test('StorageReference.getRoot: Returns root multiple levels down', () {
        var ref = storage.refFromURL('gs://test-bucket/a/b/c/d');
        expect(ref.root, root);
      });
    });
    group('StorageReference.getBucket', () {
      test('StorageReference.getBucket: Returns bucket name', () {
        expect(root.bucket, 'test-bucket');
      });
    });
    group('StorageReference.path', () {
      test('StorageReference.path: Returns full path without leading slash',
          () {
        var ref = storage.refFromURL('gs://test-bucket/full/path');
        expect(ref.fullPath, 'full/path');
      });
    });
    group('StorageReference.getName', () {
      test('StorageReference.getName: Works at top level', () {
        var ref = storage.refFromURL('gs://test-bucket/toplevel.txt');
        expect(ref.name, 'toplevel.txt');
      });
      test('StorageReference.getName: Works at not the top level', () {
        var ref = storage.refFromURL('gs://test-bucket/not/toplevel.txt');
        expect(ref.name, 'toplevel.txt');
      });
    });
    group('StorageReference.child', () {
      test('StorageReference.child: works with a simple string', () {
        expect(root.child('a').toString(), 'gs://test-bucket/a');
      });
      test('StorageReference.child: drops a trailing slash', () {
        expect(root.child('ab/').toString(), 'gs://test-bucket/ab');
      });
      test('StorageReference.child: compresses repeated slashes', () {
        expect(root.child('//a///b/////').toString(), 'gs://test-bucket/a/b');
      });
      test(
          'StorageReference.child: works chained multiple times with leading slashes',
          () {
        expect(root.child('a').child('/b').child('c').child('d/e').toString(),
            'gs://test-bucket/a/b/c/d/e');
      });
    });
    group('StorageReference.getDownloadUrl', () {
      var ref = child.child('world.txt');
      tester.backend.putData(
          Location.fromUrl(ref.toString()), Uint8List(0), SettableMetadata());

      test('StorageReference.getDownloadUrl: file exists', () async {
        var url = await ref.getDownloadURL();
        var token = Uri.parse(url).queryParameters['token'];
        expect(url.toString(),
            'https://firebasestorage.googleapis.com/v0/b/test-bucket/o/hello%2Fworld.txt?alt=media&token=$token');
      });
      test('StorageReference.getDownloadUrl: file does not exist', () async {
        var ref = child.child('everyone.txt');
        expect(() => ref.getDownloadURL(),
            throwsA(StorageException.objectNotFound(ref.fullPath)));
      });
    });

    group('StorageReference.putString', () {
      test('Uses metadata.contentType for RAW format', () async {
        var t = await child.child('hello.txt').putString('hello',
            format: PutStringFormat.raw,
            metadata: SettableMetadata(contentType: 'lol/wut'));
        expect(t.metadata!.contentType, 'lol/wut');
      });

      test('Uses embedded content type in DATA_URL format', () async {
        var t = await child.child('hello.txt').putString(
            'data:lol/wat;base64,aaaa',
            format: PutStringFormat.dataUrl);
        expect(t.metadata!.contentType, 'lol/wat');
      });

      test(
          'Lets metadata.contentType override embedded content type in DATA_URL format',
          () async {
        var t = await child.child('hello.txt').putString(
            'data:ignore/me;base64,aaaa',
            format: PutStringFormat.dataUrl,
            metadata: SettableMetadata(contentType: 'tomato/soup'));

        expect(t.metadata!.contentType, 'tomato/soup');
      });
    });

    group('StorageReference.putData', () {
      test('Uses metadata.contentType', () async {
        var t = await child
            .child('hello.bin')
            .putData(Uint8List(0), SettableMetadata(contentType: 'lol/wut'));
        expect(t.metadata!.contentType, 'lol/wut');
      });

      test('uploads without error', () async {
        var blob = Uint8List.fromList([97]);
        var ref = child.child('hello.bin');
        var result = await ref.putData(blob);
        expect(result.ref, ref);
        expect(result.metadata!.contentType, 'application/octet-stream');
        expect(result.metadata!.size, 1);
      });
    });

    group('Argument verification', () {
      group('StorageReference.list', () {
        test('throws on invalid maxResults', () async {
          expect(() => child.list(ListOptions(maxResults: 0)),
              throwsArgumentError);
          expect(() => child.list(ListOptions(maxResults: -4)),
              throwsArgumentError);
          expect(() => child.list(ListOptions(maxResults: 1001)),
              throwsArgumentError);
        });
      });
    });

    group('root operations', () {
      test('StorageReference.putData throws', () {
        expect(() => root.putData(Uint8List(0)),
            throwsA(StorageException.invalidRootOperation('putData')));
      });
      test('StorageReference.putString throws', () {
        expect(() => root.putString('raw'),
            throwsA(StorageException.invalidRootOperation('putString')));
      });
      test('StorageReference.delete throws', () {
        expect(() => root.delete(),
            throwsA(StorageException.invalidRootOperation('delete')));
      });
      test('StorageReference.getMetadata throws', () {
        expect(() => root.getMetadata(),
            throwsA(StorageException.invalidRootOperation('getMetadata')));
      });
      test('StorageReference.updateMetadata throws', () {
        expect(() => root.updateMetadata(SettableMetadata()),
            throwsA(StorageException.invalidRootOperation('updateMetadata')));
      });
      test('StorageReference.getDownloadURL throws', () {
        expect(() => root.getDownloadURL(),
            throwsA(StorageException.invalidRootOperation('getDownloadURL')));
      });
    });
  });
}

FirebaseOptions getOptions(
    {String appId = 'my_app_id',
    String apiKey = 'apiKey',
    String projectId = 'my_project',
    String storageBucket = 'test-bucket'}) {
  return FirebaseOptions(
      appId: appId,
      apiKey: apiKey,
      projectId: projectId,
      messagingSenderId: 'ignore',
      storageBucket: storageBucket,
      authDomain: '$projectId.firebaseapp.com');
}

class Tester {
  final MemoryStorageBackend backend;

  final FirebaseApp app;

  Tester._(this.app, this.backend);

  static Future<Tester> create({bool isolated = false}) async {
    await FirebaseTesting.setup(isolated: isolated);

    var app = await Firebase.initializeApp(options: getOptions());

    var backend = FirebaseTesting.getBackend(app.options);
    return Tester._(app, backend.storageBackend as MemoryStorageBackend);
  }
}
