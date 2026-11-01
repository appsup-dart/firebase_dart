import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

/// Deleting stored cache nodes must not scan the whole box.
void main() {
  const boxName = 'cache-delete';

  late CountingBox box;
  late PersistenceStorageDatabaseImpl database;

  setUp(() async {
    var hiveBox = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName, bytes: Uint8List(0));
    await hiveBox.clear();
    box = CountingBox(hiveBox);
    database = PersistenceStorageDatabaseImpl(KeyValueDatabase(box));
  });

  tearDown(() async {
    await database.close();
  });

  test('removing complete nodes does not read every stored key', () async {
    var cache = IncompleteData.empty();
    for (var i = 0; i < 20; i++) {
      cache = cache.applyOperation(TreeOperation.overwrite(
          _path(i), TreeStructuredData.fromJson({'n': i})));
    }
    await database.applyTransaction(
        PersistenceStorageTransaction()..saveServerCache(cache));

    for (var i = 15; i < 20; i++) {
      cache = cache.removeWrite(_path(i));
    }
    box.gets = 0;
    await database.applyTransaction(
        PersistenceStorageTransaction()..saveServerCache(cache));

    expect(box.gets, lessThanOrEqualTo(5));
    expect(box.containsKey('C:cars/00/'), isTrue);
    expect(box.containsKey('C:cars/15/'), isFalse);
  });
}

Path<Name> _path(int index) =>
    Name.parsePath('cars/${index.toString().padLeft(2, '0')}');

class CountingBox<E> implements Box<E> {
  CountingBox(this._box);

  final Box<E> _box;
  int gets = 0;

  @override
  E? get(dynamic key, {E? defaultValue}) {
    gets++;
    return _box.get(key, defaultValue: defaultValue);
  }

  @override
  Future<int> add(E value) => _box.add(value);

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) => _box.addAll(values);

  @override
  Future<int> clear() => _box.clear();

  @override
  Future<void> close() => _box.close();

  @override
  Future<void> compact() => _box.compact();

  @override
  bool containsKey(dynamic key) => _box.containsKey(key);

  @override
  Future<void> delete(dynamic key) => _box.delete(key);

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) => _box.deleteAll(keys);

  @override
  Future<void> deleteAt(int index) => _box.deleteAt(index);

  @override
  Future<void> deleteFromDisk() => _box.deleteFromDisk();

  @override
  Future<void> flush() => _box.flush();

  @override
  E? getAt(int index) => _box.getAt(index);

  @override
  bool get isEmpty => _box.isEmpty;

  @override
  bool get isNotEmpty => _box.isNotEmpty;

  @override
  bool get isOpen => _box.isOpen;

  @override
  dynamic keyAt(int index) => _box.keyAt(index);

  @override
  Iterable<dynamic> get keys => _box.keys;

  @override
  bool get lazy => _box.lazy;

  @override
  int get length => _box.length;

  @override
  String get name => _box.name;

  @override
  String? get path => _box.path;

  @override
  Future<void> put(dynamic key, E value) => _box.put(key, value);

  @override
  Future<void> putAll(Map<dynamic, E> entries) => _box.putAll(entries);

  @override
  Future<void> putAt(int index, E value) => _box.putAt(index, value);

  @override
  Map<dynamic, E> toMap() => _box.toMap();

  @override
  Iterable<E> get values => _box.values;

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) =>
      _box.valuesBetween(startKey: startKey, endKey: endKey);

  @override
  Stream<BoxEvent> watch({dynamic key}) => _box.watch(key: key);
}
