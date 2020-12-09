import 'package:firebase_dart/src/database/impl/persistence/compound_write.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

void main() {
  group('CompoundWrite', () {
    var leafNode = TreeStructuredData.fromJson('leaf-node');
    var prioNode = TreeStructuredData.fromJson('prio');
    var priorityPath = Path.from([NameX.priorityKey]);

    test('empty merge is empty', () {
      expect(CompoundWrite.empty().isEmpty, true);
    });
    test('compound write with priority update is not empty', () {
      expect(CompoundWrite.empty().addWrite(priorityPath, prioNode).isEmpty,
          false);
    });

    test('compound write with update is not empty', () {
      expect(
          CompoundWrite.empty()
              .addWrite(Name.parsePath('foo/bar'), leafNode)
              .isEmpty,
          false);
    });
    test('compound write with root update is not empty', () {
      expect(CompoundWrite.empty().addWrite(Path(), leafNode).isEmpty, false);
    });
    test('compound write with empty root update is not empty', () {
      expect(
          CompoundWrite.empty().addWrite(Path(), TreeStructuredData()).isEmpty,
          false);
    });
    test(
        'compound write with root priority update and child merge is not empty',
        () {
      var compoundWrite =
          CompoundWrite.empty().addWrite(priorityPath, prioNode);
      expect(
          compoundWrite.childCompoundWrite(Name.parsePath('.priority')).isEmpty,
          false);
    });

    test('applies leaf overwrite', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(Path(), leafNode);
      expect(compoundWrite.apply(TreeStructuredData()), leafNode);
    });

    test('applies children overwrite', () {
      var compoundWrite = CompoundWrite.empty();
      var childNode =
          TreeStructuredData().updateChild(Name.parsePath('child'), leafNode);
      compoundWrite = compoundWrite.addWrite(Path(), childNode);
      expect(compoundWrite.apply(TreeStructuredData()), childNode);
    });

    test('adds child node', () {
      var compoundWrite = CompoundWrite.empty();
      var childKey = Name.parsePath('child');
      var expected = TreeStructuredData().updateChild(childKey, leafNode);
      compoundWrite = compoundWrite.addWrite(childKey, leafNode);
      expect(compoundWrite.apply(TreeStructuredData()), expected);
    });

    test('adds deep child node', () {
      var compoundWrite = CompoundWrite.empty();
      var path = Name.parsePath('deep/deep/node');
      var expected = TreeStructuredData().updateChild(path, leafNode);
      compoundWrite = compoundWrite.addWrite(path, leafNode);
      expect(compoundWrite.apply(TreeStructuredData()), expected);
    });

    test('overwrites existing child', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1');
      compoundWrite = compoundWrite.addWrite(path, leafNode);
      expect(compoundWrite.apply(baseNode),
          baseNode.updateChild(Path.from([path.first]), leafNode));
    });

    test('updates existing child', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1/foo');
      compoundWrite = compoundWrite.addWrite(path, leafNode);
      expect(
          compoundWrite.apply(baseNode), baseNode.updateChild(path, leafNode));
    });

    test('doesn\'t update priority on empty node', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(priorityPath, prioNode);
      assertNodeGetsCorrectPriority(compoundWrite, TreeStructuredData(), null);
    });

    test('updates priority on node', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(priorityPath, prioNode);
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(compoundWrite, node, prioNode.value);
    });

    test('updates priority of child', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1/.priority');
      compoundWrite = compoundWrite.addWrite(path, prioNode);
      expect(
          compoundWrite.apply(baseNode), baseNode.updateChild(path, prioNode));
    });

    test('doesn\'t update priority of non existent child', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-3/.priority');
      compoundWrite = compoundWrite.addWrite(path, prioNode);
      expect(compoundWrite.apply(baseNode), baseNode);
    });

    test('priority update on previous empty child write is ignored', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child'), TreeStructuredData());
      var path = Name.parsePath('child/.priority');
      compoundWrite = compoundWrite.addWrite(path, prioNode);
      var applied = compoundWrite.apply(TreeStructuredData());
      expect(applied.getChild(Name.parsePath('child')).priority, null);
      expect(compoundWrite.getCompleteNode(Name.parsePath('child')).priority,
          null);
      for (var node in compoundWrite.getCompleteChildren()) {
        expect(node.value.priority, null);
      }
    });

    test('deep update existing updates', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne =
          TreeStructuredData.fromJson({'foo': 'foo-value', 'bar': 'bar-value'});
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1'), updateOne);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/baz'), updateTwo);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/foo'), updateThree);
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value'
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(compoundWrite.apply(baseNode), expected);
    });

    test('shallow update removes deep update', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson('new-foo-value');
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree =
          TreeStructuredData.fromJson({'foo': 'foo-value', 'bar': 'bar-value'});
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/foo'), updateOne);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/baz'), updateTwo);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1'), updateThree);
      var expectedChildOne = {
        'foo': 'foo-value',
        'bar': 'bar-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(compoundWrite.apply(baseNode), expected);
    });

    test('child priority doesn\'t update empty node priority on child merge',
        () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/.priority'), prioNode);
      assertNodeGetsCorrectPriority(
          compoundWrite.childCompoundWrite(Name.parsePath('child-1')),
          TreeStructuredData(),
          null);
    });

    test('child priority updates priority on child merge', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/.priority'), prioNode);
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(
          compoundWrite.childCompoundWrite(Name.parsePath('child-1')),
          node,
          prioNode.value);
    });

    test('child priority updates empty priority on child merge', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(
          Name.parsePath('child-1/.priority'), TreeStructuredData());
      var node = TreeStructuredData.leaf(Value.string('foo'), prioNode.value);
      assertNodeGetsCorrectPriority(
          compoundWrite.childCompoundWrite(Name.parsePath('child-1')),
          node,
          null);
    });

    test('deep priority set works on empty node when other set is available',
        () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('foo/.priority'), prioNode);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('foo/child'), leafNode);
      var node = compoundWrite.apply(TreeStructuredData());
      expect(node.getChild(Name.parsePath('foo')).priority, prioNode.value);
    });

    test('child merge looks into update node', () {
      var compoundWrite = CompoundWrite.empty();
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      compoundWrite = compoundWrite.addWrite(Path(), update);
      expect(
          compoundWrite
              .childCompoundWrite(Name.parsePath('foo'))
              .apply(TreeStructuredData()),
          TreeStructuredData.fromJson('foo-value'));
    });

    test('child merge removes node on deeper paths', () {
      var compoundWrite = CompoundWrite.empty();
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      compoundWrite = compoundWrite.addWrite(Path(), update);
      expect(
          compoundWrite
              .childCompoundWrite(Name.parsePath('foo/not/existing'))
              .apply(leafNode),
          TreeStructuredData());
    });

    test('child merge with empty path is same merge', () {
      var compoundWrite = CompoundWrite.empty();
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      compoundWrite = compoundWrite.addWrite(Path(), update);
      expect(compoundWrite.childCompoundWrite(Path()), same(compoundWrite));
    });

    test('root update removes root priority', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('.priority'), prioNode);
      compoundWrite =
          compoundWrite.addWrite(Path(), TreeStructuredData.fromJson('foo'));
      expect(compoundWrite.apply(TreeStructuredData()),
          TreeStructuredData.fromJson('foo'));
    });

    test('deep update removes priority there', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('foo/.priority'), prioNode);
      compoundWrite = compoundWrite.addWrite(
          Name.parsePath('foo'), TreeStructuredData.fromJson('bar'));
      var expected = TreeStructuredData.fromJson({
        'foo': 'bar',
      });
      expect(compoundWrite.apply(TreeStructuredData()), expected);
    });

    test('adding updates at path works', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name('foo'): TreeStructuredData.fromJson('foo-value'),
        Name('bar'): TreeStructuredData.fromJson('bar-value'),
      };
      compoundWrite = compoundWrite.addWrites(
          Name.parsePath('child-1'), CompoundWrite.fromChildMerge(updates));

      var baseNode = TreeStructuredData.fromJson(base);
      var expectedChildOne = {
        'foo': 'foo-value',
        'bar': 'bar-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(compoundWrite.apply(baseNode), expected);
    });

    test('adding updates at root works', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name('child-1'): TreeStructuredData.fromJson('new-value-1'),
        Name('child-2'): TreeStructuredData(),
        Name('child-3'): TreeStructuredData.fromJson('value-3')
      };
      compoundWrite = compoundWrite.addWrites(
          Path(), CompoundWrite.fromChildMerge(updates));

      var baseNode = TreeStructuredData.fromJson(base);
      var expected = {
        'child-1': 'new-value-1',
        'child-3': 'value-3',
      };
      expect(
          compoundWrite.apply(baseNode), TreeStructuredData.fromJson(expected));
    });

    test('child merge of root priority works', () {
      var compoundWrite =
          CompoundWrite.empty().addWrite(Name.parsePath('.priority'), prioNode);
      expect(
          compoundWrite
              .childCompoundWrite(Name.parsePath('.priority'))
              .apply(TreeStructuredData()),
          prioNode);
    });

    test('complete children only returns complete overwrites', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1'), leafNode);
      expect(Map.fromEntries(compoundWrite.getCompleteChildren()),
          {Name('child-1'): leafNode});
    });

    test('complete children only returns empty overwrites', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(
          Name.parsePath('child-1'), TreeStructuredData());
      expect(Map.fromEntries(compoundWrite.getCompleteChildren()),
          {Name('child-1'): TreeStructuredData()});
    });

    test('complete children doesn\'t return deep overwrites', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/deep/path'), leafNode);
      expect(compoundWrite.getCompleteChildren(), isEmpty);
    });

    test('complete children return all complete children but no incomplete',
        () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/deep/path'), leafNode);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-2'), leafNode);
      compoundWrite = compoundWrite.addWrite(
          Name.parsePath('child-3'), TreeStructuredData());
      var expected = {
        Name('child-2'): leafNode,
        Name('child-3'): TreeStructuredData()
      };
      var actual = Map.fromEntries(compoundWrite.getCompleteChildren());
      expect(actual, expected);
    });

    test('complete children return all children for root set', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      compoundWrite = compoundWrite.addWrite(Path(), baseNode);

      var expected = {
        Name('child-1'): TreeStructuredData.fromJson('value-1'),
        Name('child-2'): TreeStructuredData.fromJson('value-2')
      };

      var actual = Map.fromEntries(compoundWrite.getCompleteChildren());
      expect(actual, expected);
    });

    test('empty merge has no shadowing write', () {
      expect(CompoundWrite.empty().hasCompleteWrite(Path()), false);
    });

    test('compound write with empty root has shadowing write', () {
      var compoundWrite =
          CompoundWrite.empty().addWrite(Path(), TreeStructuredData());
      expect(compoundWrite.hasCompleteWrite(Path()), true);
      expect(compoundWrite.hasCompleteWrite(Name.parsePath('child')), true);
    });

    test('compound write with root has shadowing write', () {
      var compoundWrite = CompoundWrite.empty().addWrite(Path(), leafNode);
      expect(compoundWrite.hasCompleteWrite(Path()), true);
      expect(compoundWrite.hasCompleteWrite(Name.parsePath('child')), true);
    });

    test('compound write with deep update has shadowing write', () {
      var compoundWrite = CompoundWrite.empty()
          .addWrite(Name.parsePath('deep/update'), leafNode);
      expect(compoundWrite.hasCompleteWrite(Path()), false);
      expect(compoundWrite.hasCompleteWrite(Name.parsePath('deep')), false);
      expect(
          compoundWrite.hasCompleteWrite(Name.parsePath('deep/update')), true);
    });

    test('compound write with prioriy update has shadowing write', () {
      var compoundWrite =
          CompoundWrite.empty().addWrite(Name.parsePath('.priority'), prioNode);
      expect(compoundWrite.hasCompleteWrite(Path()), false);
      expect(compoundWrite.hasCompleteWrite(Name.parsePath('.priority')), true);
    });

    test('updates can be removed', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      compoundWrite = compoundWrite.addWrite(Name.parsePath('child-1'), update);
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('child-1'));
      expect(compoundWrite.apply(baseNode), baseNode);
    });

    test('deep removes has no effect on overlaying set', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1'), updateOne);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/baz'), updateTwo);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/foo'), updateThree);
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('child-1/foo'));
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(compoundWrite.apply(baseNode), expected);
    });

    test('remove at path without set is without effect', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1'), updateOne);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/baz'), updateTwo);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/foo'), updateThree);
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('child-2'));
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(compoundWrite.apply(baseNode), expected);
    });

    test('can remove priority', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('.priority'), prioNode);
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('.priority'));
      assertNodeGetsCorrectPriority(compoundWrite, leafNode, null);
    });

    test('removing only affects removed path', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name('child-1'): TreeStructuredData.fromJson('new-value-1'),
        Name('child-2'): TreeStructuredData(),
        Name('child-3'): TreeStructuredData.fromJson('value-3')
      };
      compoundWrite = compoundWrite.addWrites(
          Path(), CompoundWrite.fromChildMerge(updates));
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('child-2'));

      var baseNode = TreeStructuredData.fromJson(base);
      var expected = {
        'child-1': 'new-value-1',
        'child-2': 'value-2',
        'child-3': 'value-3',
      };
      expect(
          compoundWrite.apply(baseNode), TreeStructuredData.fromJson(expected));
    });

    test('remove removes all deeper sets', () {
      var compoundWrite = CompoundWrite.empty();
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/baz'), updateTwo);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child-1/foo'), updateThree);
      compoundWrite = compoundWrite.removeWrite(Name.parsePath('child-1'));
      expect(compoundWrite.apply(baseNode), baseNode);
    });

    test('remove at root also removes priority', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(
          Path(), TreeStructuredData.leaf(Value.string('foo'), prioNode.value));
      compoundWrite = compoundWrite.removeWrite(Path());
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(compoundWrite, node, null);
    });

    test('updating priority doesn\'t overwrite leaf node', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(Path(), leafNode);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child/.priority'), prioNode);
      expect(compoundWrite.apply(TreeStructuredData()), leafNode);
    });

    test('updating empty node doesn\'t overwrite leaf node', () {
      var compoundWrite = CompoundWrite.empty();
      compoundWrite = compoundWrite.addWrite(Path(), leafNode);
      compoundWrite =
          compoundWrite.addWrite(Name.parsePath('child'), TreeStructuredData());
      expect(compoundWrite.apply(TreeStructuredData()), leafNode);
    });
  });
}

void assertNodeGetsCorrectPriority(
    CompoundWrite compoundWrite, TreeStructuredData node, Value priority) {
  if (node.isEmpty) {
    expect(compoundWrite.apply(node), isEmpty);
  } else {
    expect(compoundWrite.apply(node), node.updatePriority(Path(), priority));
  }
}
