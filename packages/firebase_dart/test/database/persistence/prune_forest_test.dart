import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('PruneForest', () {
    test('Empty does not affect any paths', () {
      var forest = PruneForest();

      expect(forest.affectsPath(Path()), false);
      expect(forest.affectsPath(Name.parsePath('foo')), false);
    });

    test('prune affects path', () {
      var forest = PruneForest();
      forest = forest.prune(Name.parsePath('foo/bar'));
      forest = forest.keep(Name.parsePath('foo/bar/baz'));
      expect(forest.affectsPath(Name.parsePath('foo')), true);
      expect(forest.affectsPath(Name.parsePath('baz')), false);
      expect(forest.affectsPath(Name.parsePath('baz/bar')), false);
      expect(forest.affectsPath(Name.parsePath('foo/bar')), true);
      expect(forest.affectsPath(Name.parsePath('foo/bar/baz')), true);
      expect(forest.affectsPath(Name.parsePath('foo/bar/qux')), true);
    });

    test('prunes anything works', () {
      var empty = PruneForest();
      expect(empty.prunesAnything(), false);
      expect(empty.prune(Name.parsePath('foo')).prunesAnything(), true);

      expect(
          empty
              .prune(Name.parsePath('foo/bar'))
              .keep(Name.parsePath('foo'))
              .prunesAnything(),
          false);

      expect(
          empty
              .prune(Name.parsePath('foo'))
              .keep(Name.parsePath('foo/bar'))
              .prunesAnything(),
          true);
    });

    test('keep under prune works', () {
      var forest = PruneForest();
      forest = forest.prune(Name.parsePath('foo/bar'));
      forest = forest.keep(Name.parsePath('foo/bar/baz'));
      forest =
          forest.keepAll(Name.parsePath('foo/bar'), {Name('qux'), Name('quu')});
    });

    test('prune under keep throws', () {
      var forest = PruneForest();
      forest = forest.prune(Name.parsePath('foo'));
      forest = forest.keep(Name.parsePath('foo/bar'));
      expect(() => forest.prune(Name.parsePath('foo/bar/baz')),
          throwsArgumentError);
      expect(
          () => forest
              .pruneAll(Name.parsePath('foo/bar'), {Name('qux'), Name('quu')}),
          throwsArgumentError);
    });

    test('child keeps prune info', () {
      var forest = PruneForest();
      forest = forest.keep(Name.parsePath('foo/bar'));
      expect(
          forest
              .child(Name.parsePath('foo'))
              .affectsPath(Name.parsePath('bar')),
          true);
      expect(
          forest
              .child(Name.parsePath('foo'))
              .child(Name.parsePath('bar'))
              .affectsPath(Name.parsePath('')),
          true);
      expect(
          forest
              .child(Name.parsePath('foo'))
              .child(Name.parsePath('bar'))
              .child(Name.parsePath('baz'))
              .affectsPath(Name.parsePath('')),
          true);

      forest = PruneForest().prune(Name.parsePath('foo/bar'));
      expect(
          forest
              .child(Name.parsePath('foo'))
              .affectsPath(Name.parsePath('bar')),
          true);
      expect(
          forest
              .child(Name.parsePath('foo'))
              .child(Name.parsePath('bar'))
              .affectsPath(Name.parsePath('')),
          true);
      expect(
          forest
              .child(Name.parsePath('foo'))
              .child(Name.parsePath('bar'))
              .child(Name.parsePath('baz'))
              .affectsPath(Name.parsePath('')),
          true);

      expect(
          forest
              .child(Name.parsePath('non-existent'))
              .affectsPath(Name.parsePath('')),
          false);
    });

    test('should prune works', () {
      var forest = PruneForest();
      forest = forest.prune(Name.parsePath('foo'));
      forest = forest.keep(Name.parsePath('foo/bar/baz'));
      expect(forest.shouldPruneUnkeptDescendants(Name.parsePath('foo')), true);
      expect(
          forest.shouldPruneUnkeptDescendants(Name.parsePath('foo/bar')), true);
      expect(forest.shouldPruneUnkeptDescendants(Name.parsePath('foo/bar/baz')),
          false);
      expect(forest.shouldPruneUnkeptDescendants(Name.parsePath('qux')), false);
    });

    test('fold keep visits all kept nodes', () {
      var forest = PruneForest();
      forest = forest.prune(Name.parsePath('foo'));
      forest =
          forest.keepAll(Name.parsePath('foo/bar'), {Name('qux'), Name('quu')});
      forest = forest.keep(Name.parsePath('foo/baz'));
      forest = forest.keep(Name.parsePath('bar'));
      var actualPaths = <Path>{};
      forest.foldKeptNodes(null, (relativePath, value, dynamic _) {
        actualPaths.add(relativePath);
        return null;
      });
      var expected = {
        Name.parsePath('foo/bar/qux'),
        Name.parsePath('foo/bar/quu'),
        Name.parsePath('foo/baz'),
        Name.parsePath('bar')
      };
      expect(expected, actualPaths);
    });
  });
}
