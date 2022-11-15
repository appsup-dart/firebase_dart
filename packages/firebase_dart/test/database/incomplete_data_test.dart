import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';
import 'package:test/test.dart';

void main() {
  group('IncompleteData', () {
    var leafNode = TreeStructuredData.fromJson('leaf-node');
    var prioValue = Value.string('prio');
    var prioNode = TreeStructuredData.leaf(prioValue);
    var priorityPath = Path.from([Name.priorityKey]);

    var empty = IncompleteData.empty();

    test('empty is not complete', () {
      expect(empty.isComplete, false);
      expect(empty.completeValue, null);
    });
    test('set priority update', () {
      var v =
          empty.applyOperation(TreeOperation(Path(), SetPriority(prioValue)));
      expect(v.isComplete, false);
      expect(v.directChild(Name('.priority')).completeValue!.value, prioValue);
      expect(v.isCompleteForPath(priorityPath), true);
      expect(v.toOperation(), isNotNull);
    });
    test('overwrite', () {
      var path = Name.parsePath('foo/bar');
      var v = empty.applyOperation(TreeOperation.overwrite(path, leafNode));
      expect(v.isComplete, false);
      expect(v.completeValue, null);
      expect(v.isCompleteForPath(path), true);
      expect(v.toOperation(), isNotNull);
    });
    test('root overwrite', () {
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), leafNode));
      expect(v.isComplete, true);
      expect(v.completeValue, isNotNull);
      expect(v.toOperation(), isNotNull);
    });
    test('root update with empty node', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Path(), TreeStructuredData()));
      expect(v.isComplete, true);
      expect(v.completeValue!.isNil, true);
      expect(v.toOperation(), isNotNull);
    });

    test('applies leaf overwrite', () {
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), leafNode));
      expect(v.toOperation().apply(TreeStructuredData()), leafNode);
    });

    test('applies children overwrite', () {
      var childNode =
          TreeStructuredData().updateChild(Name.parsePath('child'), leafNode);
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), childNode));
      expect(v.toOperation().apply(TreeStructuredData()), childNode);
    });

    test('adds child node', () {
      var childKey = Name.parsePath('child');
      var v = empty.applyOperation(TreeOperation.overwrite(childKey, leafNode));
      var expected = TreeStructuredData().updateChild(childKey, leafNode);
      expect(v.toOperation().apply(TreeStructuredData()), expected);
    });

    test('adds deep child node', () {
      var path = Name.parsePath('deep/deep/node');
      var v = empty.applyOperation(TreeOperation.overwrite(path, leafNode));
      var expected = TreeStructuredData().updateChild(path, leafNode);
      expect(v.toOperation().apply(TreeStructuredData()), expected);
    });

    test('overwrites existing child', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1');
      var v = empty.applyOperation(TreeOperation.overwrite(path, leafNode));
      expect(v.toOperation().apply(baseNode),
          baseNode.updateChild(Path.from([path.first]), leafNode));
    });

    test('updates existing child', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1/foo');
      var v = empty.applyOperation(TreeOperation.overwrite(path, leafNode));
      expect(v.toOperation().apply(baseNode),
          baseNode.updateChild(path, leafNode));
    });

    test('doesn\'t update priority on empty node', () {
      var v =
          empty.applyOperation(TreeOperation(Path(), SetPriority(prioValue)));
      assertNodeGetsCorrectPriority(v, TreeStructuredData(), null);
    });

    test('updates priority on node', () {
      var v =
          empty.applyOperation(TreeOperation(Path(), SetPriority(prioValue)));
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(v, node, prioValue);
    });

    test('updates priority of child', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-1/.priority');
      var v = empty.applyOperation(TreeOperation.overwrite(path, prioNode));
      expect(v.toOperation().apply(baseNode),
          baseNode.updateChild(path, prioNode));
    });

    test('doesn\'t update priority of non existent child', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var path = Name.parsePath('child-3/.priority');
      var v = empty.applyOperation(TreeOperation.overwrite(path, prioNode));
      expect(v.toOperation().apply(baseNode), baseNode);
    });

    test('priority update on previous empty child write is ignored', () {
      var path = Name.parsePath('child/.priority');
      var v = empty
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child'), TreeStructuredData()))
          .applyOperation(TreeOperation.overwrite(path, prioNode));
      var applied = v.toOperation().apply(TreeStructuredData());
      expect(applied.getChild(Name.parsePath('child')).priority, null);
      expect(v.getCompleteDataAtPath(Name.parsePath('child'))!.priority, null);
      for (var node in v.completeChildren.entries) {
        expect(node.value!.priority, null);
      }
    });

    test('deep update existing updates', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne =
          TreeStructuredData.fromJson({'foo': 'foo-value', 'bar': 'bar-value'});
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1'), updateOne))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/baz'), updateTwo))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-1/foo'), updateThree));
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value'
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(v.toOperation().apply(baseNode), expected);
    });

    test('shallow update removes deep update', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson('new-foo-value');
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree =
          TreeStructuredData.fromJson({'foo': 'foo-value', 'bar': 'bar-value'});
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/foo'), updateOne))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/baz'), updateTwo))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1'), updateThree));
      var expectedChildOne = {
        'foo': 'foo-value',
        'bar': 'bar-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(v.toOperation().apply(baseNode), expected);
    });

    test('child priority doesn\'t update empty node priority on child merge',
        () {
      var v = empty.applyOperation(TreeOperation.overwrite(
          Name.parsePath('child-1/.priority'), prioNode));
      assertNodeGetsCorrectPriority(
          v.directChild(Name('child-1')), TreeStructuredData(), null);
    });

    test('child priority updates priority on child merge', () {
      var v = empty.applyOperation(TreeOperation.overwrite(
          Name.parsePath('child-1/.priority'), prioNode));
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(
          v.directChild(Name('child-1')), node, prioNode.value);
    });

    test('child priority updates empty priority on child merge', () {
      var v = empty.applyOperation(TreeOperation.overwrite(
          Name.parsePath('child-1/.priority'), TreeStructuredData()));
      var node = TreeStructuredData.leaf(Value.string('foo'), prioNode.value);
      assertNodeGetsCorrectPriority(v.directChild(Name('child-1')), node, null);
    });

    test('deep priority set works on empty node when other set is available',
        () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('foo/.priority'), prioNode))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('foo/child'), leafNode));
      var node = v.toOperation().apply(TreeStructuredData());
      expect(node.getChild(Name.parsePath('foo')).priority, prioNode.value);
    });

    test('child merge looks into update node', () {
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), update));
      expect(
          v.directChild(Name('foo')).toOperation().apply(TreeStructuredData()),
          TreeStructuredData.fromJson('foo-value'));
    });

    test('child merge removes node on deeper paths', () {
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), update));
      expect(
          v
              .child(Name.parsePath('foo/not/existing'))
              .toOperation()
              .apply(leafNode),
          TreeStructuredData());
    });

    test('root update removes root priority', () {
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('.priority'), prioNode))
          .applyOperation(TreeOperation.overwrite(
              Path(), TreeStructuredData.fromJson('foo')));
      expect(v.toOperation().apply(TreeStructuredData()),
          TreeStructuredData.fromJson('foo'));
    });

    test('deep update removes priority there', () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('foo/.priority'), prioNode))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('foo'), TreeStructuredData.fromJson('bar')));
      var expected = TreeStructuredData.fromJson({
        'foo': 'bar',
      });
      expect(v.toOperation().apply(TreeStructuredData()), expected);
    });

    test('adding updates at path works', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name.parsePath('foo'): TreeStructuredData.fromJson('foo-value'),
        Name.parsePath('bar'): TreeStructuredData.fromJson('bar-value'),
      };
      var v = empty.applyOperation(
          TreeOperation.merge(Name.parsePath('child-1'), updates));

      var baseNode = TreeStructuredData.fromJson(base);
      var expectedChildOne = {
        'foo': 'foo-value',
        'bar': 'bar-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(v.toOperation().apply(baseNode), expected);
    });

    test('adding updates at root works', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name.parsePath('child-1'): TreeStructuredData.fromJson('new-value-1'),
        Name.parsePath('child-2'): TreeStructuredData(),
        Name.parsePath('child-3'): TreeStructuredData.fromJson('value-3')
      };
      var v = empty.applyOperation(TreeOperation.merge(Path(), updates));

      var baseNode = TreeStructuredData.fromJson(base);
      var expected = {
        'child-1': 'new-value-1',
        'child-3': 'value-3',
      };
      expect(v.toOperation().apply(baseNode),
          TreeStructuredData.fromJson(expected));
    });

    test('child merge of root priority works', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('.priority'), prioNode));
      expect(
          v
              .directChild(Name('.priority'))
              .toOperation()
              .apply(TreeStructuredData()),
          prioNode);
    });

    test('complete children only returns complete overwrites', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('child-1'), leafNode));
      expect(v.completeChildren, {Name('child-1'): leafNode});
    });

    test('complete children only returns empty overwrites', () {
      var v = empty.applyOperation(TreeOperation.overwrite(
          Name.parsePath('child-1'), TreeStructuredData()));
      expect(v.completeChildren, {Name('child-1'): TreeStructuredData()});
    });

    test('complete children doesn\'t return deep overwrites', () {
      var v = empty.applyOperation(TreeOperation.overwrite(
          Name.parsePath('child-1/deep/path'), leafNode));
      expect(v.completeChildren, isEmpty);
    });

    test('complete children return all complete children but no incomplete',
        () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-1/deep/path'), leafNode))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-2'), leafNode))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-3'), TreeStructuredData()));
      var expected = {
        Name('child-2'): leafNode,
        Name('child-3'): TreeStructuredData()
      };
      var actual = v.completeChildren;
      expect(actual, expected);
    });

    test('complete children return all children for root set', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), baseNode));

      var expected = {
        Name('child-1'): TreeStructuredData.fromJson('value-1'),
        Name('child-2'): TreeStructuredData.fromJson('value-2')
      };

      var actual = v.completeChildren;
      expect(actual, expected);
    });

    test('empty merge has no shadowing write', () {
      expect(empty.isCompleteForPath(Path()), false);
    });

    test('compound write with empty root has shadowing write', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Path(), TreeStructuredData()));
      expect(v.isCompleteForPath(Path()), true);
      expect(v.isCompleteForPath(Name.parsePath('child')), true);
    });

    test('compound write with root has shadowing write', () {
      var v = empty.applyOperation(TreeOperation.overwrite(Path(), leafNode));
      expect(v.isCompleteForPath(Path()), true);
      expect(v.isCompleteForPath(Name.parsePath('child')), true);
    });

    test('compound write with deep update has shadowing write', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('deep/update'), leafNode));
      expect(v.isCompleteForPath(Path()), false);
      expect(v.isCompleteForPath(Name.parsePath('deep')), false);
      expect(v.isCompleteForPath(Name.parsePath('deep/update')), true);
    });

    test('compound write with prioriy update has shadowing write', () {
      var v = empty.applyOperation(
          TreeOperation.overwrite(Name.parsePath('.priority'), prioNode));
      expect(v.isCompleteForPath(Path()), false);
      expect(v.isCompleteForPath(Name.parsePath('.priority')), true);
    });

    test('updates can be removed', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var update = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1'), update))
          .removeWrite(Name.parsePath('child-1'));
      expect(v.toOperation().apply(baseNode), baseNode);
    });

    test('deep removes has no effect on overlaying set', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1'), updateOne))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/baz'), updateTwo))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-1/foo'), updateThree))
          .removeWrite(Name.parsePath('child-1/foo'));
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(v.toOperation().apply(baseNode), expected);
    });

    test('remove at path without set is without effect', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateOne = TreeStructuredData.fromJson({
        'foo': 'foo-value',
        'bar': 'bar-value',
      });
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1'), updateOne))
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/baz'), updateTwo))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-1/foo'), updateThree))
          .removeWrite(Name.parsePath('child-2'));
      var expectedChildOne = {
        'foo': 'new-foo-value',
        'bar': 'bar-value',
        'baz': 'baz-value',
      };
      var expected = baseNode.updateChild(Name.parsePath('child-1'),
          TreeStructuredData.fromJson(expectedChildOne));
      expect(v.toOperation().apply(baseNode), expected);
    });

    test('can remove priority', () {
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('.priority'), prioNode))
          .removeWrite(Name.parsePath('.priority'));
      assertNodeGetsCorrectPriority(v, leafNode, null);
    });

    test('removing only affects removed path', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var updates = {
        Name.parsePath('child-1'): TreeStructuredData.fromJson('new-value-1'),
        Name.parsePath('child-2'): TreeStructuredData(),
        Name.parsePath('child-3'): TreeStructuredData.fromJson('value-3')
      };
      var v = empty
          .applyOperation(TreeOperation.merge(Path(), updates))
          .removeWrite(Name.parsePath('child-2'));

      var baseNode = TreeStructuredData.fromJson(base);
      var expected = {
        'child-1': 'new-value-1',
        'child-2': 'value-2',
        'child-3': 'value-3',
      };
      expect(v.toOperation().apply(baseNode),
          TreeStructuredData.fromJson(expected));
    });

    test('remove removes all deeper sets', () {
      var base = {'child-1': 'value-1', 'child-2': 'value-2'};
      var baseNode = TreeStructuredData.fromJson(base);
      var updateTwo = TreeStructuredData.fromJson('baz-value');
      var updateThree = TreeStructuredData.fromJson('new-foo-value');
      var v = empty
          .applyOperation(
              TreeOperation.overwrite(Name.parsePath('child-1/baz'), updateTwo))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child-1/foo'), updateThree))
          .removeWrite(Name.parsePath('child-1'));
      expect(v.toOperation().apply(baseNode), baseNode);
    });

    test('remove at root also removes priority', () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(Path(),
              TreeStructuredData.leaf(Value.string('foo'), prioNode.value)))
          .removeWrite(Path());
      var node = TreeStructuredData.fromJson('value');
      assertNodeGetsCorrectPriority(v, node, null);
    });

    test('updating priority doesn\'t overwrite leaf node', () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(Path(), leafNode))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child/.priority'), prioNode));
      expect(v.toOperation().apply(TreeStructuredData()), leafNode);
    });

    test('updating empty node doesn\'t overwrite leaf node', () {
      var v = empty
          .applyOperation(TreeOperation.overwrite(Path(), leafNode))
          .applyOperation(TreeOperation.overwrite(
              Name.parsePath('child'), TreeStructuredData()));
      expect(v.toOperation().apply(TreeStructuredData()), leafNode);
    });

    test(
        'a merge should remove children that do no longer comply with the filter',
        () {
      var v = empty.withFilter(QueryFilter(
          ordering: TreeStructuredDataOrdering.byChild('isFinished'),
          validInterval: KeyValueInterval(
            Name.min,
            TreeStructuredData.leaf(Value(false)),
            Name.max,
            TreeStructuredData.leaf(Value(false)),
          )));

      v = v.applyOperation(
        TreeOperation.overwrite(
            Path.from([]),
            TreeStructuredData.fromJson({
              'v1': {'isFinished': false, 'isCancelled': false},
              'v2': {'isFinished': false, 'isCancelled': false},
              'v3': {'isFinished': false, 'isCancelled': false},
            })),
      );

      v = v.applyOperation(
        TreeOperation.merge(Name.parsePath('v2'), {
          Name.parsePath('isFinished'): TreeStructuredData.leaf(Value(true)),
          Name.parsePath('isCancelled'): TreeStructuredData.leaf(Value(true)),
        }),
      );

      expect(v.completeValue!.toJson(), {
        'v1': {'isFinished': false, 'isCancelled': false},
        'v3': {'isFinished': false, 'isCancelled': false},
      });
    });
  });
}

void assertNodeGetsCorrectPriority(
    IncompleteData v, TreeStructuredData node, Value? priority) {
  if (node.isEmpty) {
    expect(v.toOperation().apply(node), isEmpty);
  } else {
    expect(v.toOperation().apply(node), node.updatePriority(Path(), priority));
  }
}
