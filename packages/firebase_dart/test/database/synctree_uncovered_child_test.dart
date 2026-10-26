import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/query_spec.dart';
import 'package:firebase_dart/src/database/impl/repo.dart';
import 'package:firebase_dart/src/database/impl/synctree.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:test/test.dart';

/// Answers every listen with an empty node.
///
/// [SyncTree] moves a query to `registered` when [register] completes and to
/// `unregistered` when [unregister] completes, so the test does not drive
/// those transitions itself.
class _DataRegistrar extends QueryRegistrar {
  SyncTree? tree;

  bool _paused = false;

  final List<_QueryTurn> _pending = [];

  int get pending => _pending.length;

  /// Later [register] and [unregister] calls wait until [next] or [resume].
  void pause() {
    _paused = true;
  }

  /// Stops pausing and lets every queued call finish, in order.
  void resume() {
    _paused = false;
    var queued = _pending.toList();
    _pending.clear();
    for (var turn in queued) {
      turn.gate.complete();
    }
  }

  /// Lets the oldest queued call finish and returns its query.
  QuerySpec next() {
    if (_pending.isEmpty) {
      throw StateError('No paused query to release');
    }
    var turn = _pending.removeAt(0);
    turn.gate.complete();
    return turn.query;
  }

  Future<T> _afterTurn<T>(QuerySpec query, T Function() action) {
    if (!_paused) return Future<T>.value(action());
    var turn = _QueryTurn(query);
    _pending.add(turn);
    return turn.gate.future.then((_) => action());
  }

  @override
  Future<bool> register(QuerySpec query,
      {required String hash, required int priority}) {
    return _afterTurn(query, () {
      tree!.applyServerOperation(
          TreeOperation.overwrite(query.path, TreeStructuredData()), query);
      return true;
    });
  }

  @override
  Future<void> unregister(QuerySpec query) {
    return _afterTurn(query, () {});
  }

  @override
  Future<void> close() async {}

  @override
  void revoke(QuerySpec query) {}
}

class _QueryTurn {
  final QuerySpec query;

  final Completer<void> gate = Completer<void>();

  _QueryTurn(this.query);
}

void main() {
  group('SyncTree: child of an uncovered parent', () {
    // After a query on an ancestor that covered the parent goes
    // away, the parent keeps an observer-less view in state `unregistered`.
    // registrationStateForChild() then reports `unregistered` (non-null) to
    // the child, so the child thinks it is complete from its parent,
    // minimalSetOfQueries returns [] and the child is never registered again.
    final list = Name.parsePath('list');
    final parent = Name.parsePath('list/parent');
    final child = Name.parsePath('list/parent/child');
    void noop(event) {}

    test('child query is registered again after grandparent query is removed',
        () {
      fakeAsync((async) {
        var registrar = _DataRegistrar();
        var syncTree = SyncTree('mem:///', queryRegistrar: registrar);
        registrar.tree = syncTree;

        // 1. child registered on its own
        syncTree.addEventListener('value', child, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.stateFor(child), QueryRegistrationState.registered);

        // 2. parent registered -> child is covered and unregisters
        syncTree.addEventListener('value', parent, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.isCompleteFromParent(child), isTrue);

        // 3. grandparent query registers -> parent view unregisters
        //    but keeps its (still listening) observer
        syncTree.addEventListener('value', list, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.stateFor(parent), QueryRegistrationState.unregistered);

        // 4. Both listeners go away; the grandparent one first. After
        //    keepQueriesSyncedDuration its observer is pruned and the
        //    registrar finishes unregistering that query. SyncTree waits 1ms
        //    before applying registration changes and the registrar waits
        //    another 4ms before running the unlisten, so the ack lands 5ms
        //    after the prune. The parent listener is removed 5.5ms after the
        //    grandparent one: its observer is still there when the parent is
        //    uncovered (the view is kept), and is pruned in the 1ms before
        //    the next registration pass.
        syncTree.removeEventListener('value', list, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 5, microseconds: 500));
        syncTree.removeEventListener(
            'value', parent, const QueryFilter(), noop);
        async.elapse(Repo.databaseConfiguration.keepQueriesSyncedDuration +
            const Duration(milliseconds: 20));

        // 5. the child still has a listener and nothing covers it any more, so
        //    it must be registered again.
        expect(syncTree.isCompleteFromParent(child), isFalse,
            reason:
                'nothing covers the child any more:${dump(syncTree, child)}');
        expect(syncTree.stateFor(child), QueryRegistrationState.registered,
            reason:
                'child query must be re-registered:${dump(syncTree, child)}');
      });
    });

    test(
        'child query is registered again when the parent listener is removed while its query is unregistering',
        () {
      fakeAsync((async) {
        var registrar = _DataRegistrar();
        var syncTree = SyncTree('mem:///', queryRegistrar: registrar);
        registrar.tree = syncTree;

        // 1. child registered on its own
        syncTree.addEventListener('value', child, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));

        // 2. parent registered
        syncTree.addEventListener('value', parent, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.stateFor(parent), QueryRegistrationState.registered);

        // 3. acks paused. The list listen is released first, which queues the
        //    parent unlisten. The parent view is unregistering and still has
        //    its listener.
        registrar.pause();
        syncTree.addEventListener('value', list, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(registrar.next(), QuerySpec(list));
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.stateFor(parent), QueryRegistrationState.unregistering);
        expect(registrar.pending, 1);

        // 4. list listener removed, then the parent listener 5.5ms later. The
        //    list unlisten is not sent until the keep window, so the queued
        //    ack is still the parent unlisten. The parent observer stays
        //    because the view is still unregistering.
        syncTree.removeEventListener('value', list, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 5, microseconds: 500));
        syncTree.removeEventListener(
            'value', parent, const QueryFilter(), noop);
        expect(syncTree.stateFor(parent), QueryRegistrationState.unregistering);
        expect(syncTree.viewFor(parent).observers.length, 1);
        expect(registrar.pending, 1);

        // 5. parent unlisten ack is released. After the keep window the list
        //    unlisten ack uncovers the parent in the 1ms before the parent's
        //    keep-window prune and the next registration pass.
        registrar.resume();
        async.elapse(Repo.databaseConfiguration.keepQueriesSyncedDuration +
            const Duration(milliseconds: 20));

        // 6. the child still has a listener and nothing covers it any more, so
        //    it must be registered again.
        expect(syncTree.isCompleteFromParent(child), isFalse,
            reason:
                'nothing covers the child any more:${dump(syncTree, child)}');
        expect(syncTree.stateFor(child), QueryRegistrationState.registered,
            reason:
                'child query must be re-registered:${dump(syncTree, child)}');
      });
    });

    test(
        'child query is registered again when the parent listener is removed just after the parent is uncovered',
        () {
      fakeAsync((async) {
        var registrar = _DataRegistrar();
        var syncTree = SyncTree('mem:///', queryRegistrar: registrar);
        registrar.tree = syncTree;

        // 1. child registered on its own
        syncTree.addEventListener('value', child, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));

        // 2. parent registered -> child is covered and unregisters
        syncTree.addEventListener('value', parent, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));

        // 3. grandparent query registers -> parent view unregisters
        //    but keeps its (still listening) observer
        syncTree.addEventListener('value', list, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 100));
        expect(syncTree.stateFor(parent), QueryRegistrationState.unregistered);

        // 4. grandparent listener removed. After keepQueriesSyncedDuration its
        //    unlisten ack lands while the parent listener is still attached,
        //    so uncover keeps the parent view and schedules a registration
        //    pass 1ms later.
        syncTree.removeEventListener('value', list, const QueryFilter(), noop);
        async.elapse(Repo.databaseConfiguration.keepQueriesSyncedDuration +
            const Duration(milliseconds: 5));
        expect(syncTree.isCompleteFromParent(parent), isFalse);
        expect(syncTree.stateFor(parent), QueryRegistrationState.unregistered);
        expect(syncTree.viewFor(parent).observers.length, 1);

        // 5. parent listener removed in that gap: the view is already
        //    uncovered and still unregistered.
        syncTree.removeEventListener(
            'value', parent, const QueryFilter(), noop);
        async.elapse(const Duration(milliseconds: 20));

        // 6. the child still has a listener and nothing covers it any more, so
        //    it must be registered again.
        expect(syncTree.isCompleteFromParent(child), isFalse,
            reason:
                'nothing covers the child any more:${dump(syncTree, child)}');
        expect(syncTree.stateFor(child), QueryRegistrationState.registered,
            reason:
                'child query must be re-registered:${dump(syncTree, child)}');
      });
    });
  });
}

extension on SyncTree {
  MasterView viewFor(Path<Name> path) {
    return root.subtreeNullable(path)!.value.views[const QueryFilter()]!;
  }

  QueryRegistrationState stateFor(Path<Name> path) {
    return viewFor(path).state;
  }

  bool isCompleteFromParent(Path<Name> path) {
    return root.subtreeNullable(path)!.value.isCompleteFromParent;
  }
}

String dump(SyncTree t, Path<Name> path) {
  var b = StringBuffer();
  var node = t.root;
  void p(String n, SyncPoint sp) => b.writeln(
      '\n  [$n] complParent=${sp.isCompleteFromParent} views=${sp.views.entries.map((e) => '${e.key.limits ? 'filtered' : 'default'}:${e.value.state.name},obs=${e.value.observers.length},inSync=${e.value.isInSync}').toList()}');
  p('/', node.value);
  var cur = '';
  for (var n in path) {
    var c = node.children[n];
    if (c == null) break;
    node = c;
    cur = '$cur/$n';
    p(cur, node.value);
  }
  return b.toString();
}
