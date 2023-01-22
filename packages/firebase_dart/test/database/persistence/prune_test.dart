import 'dart:typed_data';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  group('PersistenceStorageEngine.pruneCache', () {
    late PersistenceStorageEngine engine;

    setUp(() async {
      var box = await Hive.openBox('test', bytes: Uint8List(0));
      engine = HivePersistenceStorageEngine(KeyValueDatabase(box));
    });

    final emptyNode = TreeStructuredData();
    final abcNode = TreeStructuredData.fromJson({
      'a': {'aa': 1.1, 'ab': 1.2},
      'b': 2,
      'c': 3
    });
    final bcNode = abcNode.updateChild(Name.parsePath('a'), emptyNode);
    final defNode = TreeStructuredData.fromJson({'d': 4, 'e': 5, 'f': 6});
    final dNode = emptyNode.updateChild(
        Name.parsePath('d'), defNode.getChild(Name.parsePath('d')));
    final aNode = emptyNode.updateChild(
        Name.parsePath('a'), abcNode.getChild(Name.parsePath('a')));
    final largeNode = TreeStructuredData.fromJson(
        Iterable.generate(5 * 1024 * 1024, (i) => 'a').join());

    void write(Path<Name> path, TreeStructuredData value) {
      engine.beginTransaction();
      engine.overwriteServerCache(TreeOperation.overwrite(path, value));
      engine.endTransaction();
    }

    void prune(PruneForest forest) {
      engine.beginTransaction();
      engine.pruneCache(forest);
      engine.endTransaction();
    }

    test('Write document at root, prune it', () {
      write(Path(), abcNode);
      prune(PruneForest().prune(Path()));
      expect(engine.serverCache(Path()).value, emptyNode);
    });

    test('Write document at /x, prune it via PruneForest for /x', () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      prune(PruneForest().prune(path));
      expect(engine.serverCache(path).value, emptyNode);
    });

    test('Write document at /x, prune it via PruneForest for root', () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      prune(PruneForest().prune(Path()));
      expect(engine.serverCache(path).value, emptyNode);
    });

    test(
        'Write abc at /x/y, prune /x/y except b,c via PruneForest for /x/y -b,c',
        () {
      var path = Name.parsePath('x/y');
      write(path, abcNode);

      prune(PruneForest()
          .prune(path)
          .keep(Name.parsePath('x/y/b'))
          .keep(Name.parsePath('x/y/c')));
      expect(engine.serverCache(path).value, bcNode);
    });

    test(
        'Write abc at /x/y, prune /x/y except not-there via PruneForest for /x/y -d',
        () {
      var path = Name.parsePath('x/y');
      write(path, abcNode);

      prune(PruneForest().prune(path).keep(Name.parsePath('x/y/not-there')));
      expect(engine.serverCache(path).value, emptyNode);
    });

    test('Write abc at / and def at /a, prune all via PruneForest for /', () {
      var path = Name.parsePath('');
      write(path, abcNode);
      write(Name.parsePath('a'), abcNode);

      prune(PruneForest().prune(path));
      expect(engine.serverCache(path).value, emptyNode);
    });

    test(
        'Write abc at / and def at /a, prune all except b,c via PruneForest for root -b,c',
        () {
      var path = Name.parsePath('');
      write(path, abcNode);
      write(Name.parsePath('a'), abcNode);

      prune(PruneForest()
          .prune(path)
          .keep(Name.parsePath('b'))
          .keep(Name.parsePath('c')));
      expect(engine.serverCache(path).value, bcNode);
    });

    test(
        'Write abc at /x and def at /x/a, prune /x except b,c via PruneForest for /x -b,c',
        () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      write(Name.parsePath('x/a'), defNode);

      prune(PruneForest()
          .prune(path)
          .keep(Name.parsePath('x/b'))
          .keep(Name.parsePath('x/c')));
      expect(engine.serverCache(path).value, bcNode);
    });

    test(
        'Write abc at /x and def at /x/a, prune /x except a via PruneForest for /x -a',
        () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      write(Name.parsePath('x/a'), defNode);
      expect(engine.serverCache(path).value,
          abcNode.updateChild(Name.parsePath('a'), defNode));

      prune(PruneForest().prune(path).keep(Name.parsePath('x/a')));
      expect(engine.serverCache(path).value,
          emptyNode.updateChild(Name.parsePath('a'), defNode));
    });

    test(
        'Write abc at /x and def at /x/a, prune /x except a/d via PruneForest for /x -a/d',
        () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      write(Name.parsePath('x/a'), defNode);

      prune(PruneForest().prune(path).keep(Name.parsePath('x/a/d')));
      expect(engine.serverCache(path).value,
          emptyNode.updateChild(Name.parsePath('a'), dNode));
    });

    test(
        'Write abc at /x and def at /x/a/aa, prune /x except a via PruneForest for /x -a',
        () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      write(Name.parsePath('x/a/aa'), defNode);

      prune(PruneForest().prune(path).keep(Name.parsePath('x/a')));
      expect(engine.serverCache(path).value,
          aNode.updateChild(Name.parsePath('a/aa'), defNode));
    });

    test(
        'Write abc at /x and def at /x/a/aa, prune /x except a/aa via PruneForest for /x -a/aa',
        () {
      var path = Name.parsePath('x');
      write(path, abcNode);
      write(Name.parsePath('x/a/aa'), defNode);

      prune(PruneForest().prune(path).keep(Name.parsePath('x/a/aa')));
      expect(engine.serverCache(path).value,
          emptyNode.updateChild(Name.parsePath('a/aa'), defNode));
    });

    test('Write large node at /x, prune x via PruneForest for x', () {
      var path = Name.parsePath('x');
      write(path, largeNode);

      prune(PruneForest().prune(path));
      expect(engine.serverCache(path).value, emptyNode);
    });
  });
}
