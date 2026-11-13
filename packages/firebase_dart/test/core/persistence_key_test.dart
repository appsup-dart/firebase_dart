import 'dart:typed_data';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/core/impl/persistence_key.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  setUpAll(FirebaseDart.setup);

  test('storage keys include the app id and the app name', () async {
    final first = await Firebase.initializeApp(
      name: 'one',
      options: getOptions(appId: '1:2:web:abc'),
    );
    final second = await Firebase.initializeApp(
      name: 'two',
      options: getOptions(appId: '1:2:web:abc'),
    );
    addTearDown(() => first.delete());
    addTearDown(() => second.delete());

    expect(firebaseAppStorageKey(first), '1:2:web:abc:one');
    expect(firebaseAppStorageKey(second), '1:2:web:abc:two');
    expect(
      databasePersistenceBoxName(
        host: 'example.firebaseio.com',
        appStorageKey: firebaseAppStorageKey(first),
      ),
      isNot(databasePersistenceBoxName(
        host: 'example.firebaseio.com',
        appStorageKey: firebaseAppStorageKey(second),
      )),
    );
    expect(
      databasePersistenceBoxName(host: 'example.firebaseio.com'),
      'firebase-db-persistence-storage-example.firebaseio.com',
    );
  });

  test('database cache migrates from the host box into the app box', () async {
    final legacy = await Hive.openBox('legacy-db', bytes: Uint8List(0));
    final scoped = await Hive.openBox('scoped-db', bytes: Uint8List(0));
    addTearDown(legacy.close);
    addTearDown(scoped.close);
    await legacy.put('serverCache:/', 'old');

    await claimLegacyBox(scoped, legacy);

    expect(scoped.get('serverCache:/'), 'old');
    expect(legacy.isEmpty, isTrue);

    final other = await Hive.openBox('other-db', bytes: Uint8List(0));
    addTearDown(other.close);
    await claimLegacyBox(other, legacy);
    expect(other.isEmpty, isTrue);
  });
}
