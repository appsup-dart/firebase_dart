import 'package:firebase_dart/src/database/impl/utils.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';

/// Forest of "prune trees" where a prune tree is a location that can be pruned
/// with a tree of descendants that must be excluded from the pruning.
///
/// Internally we store this as a single tree of bools with the following
/// characteristics:
///
/// * 'true' indicates a location that can be pruned, possibly with some
/// excluded descendants.
/// * 'false' indicates a location that we should keep (i.e. exclude from
/// pruning).
/// * 'true' (prune) cannot be a descendant of 'false' (keep). This will trigger
/// an exception.
/// * 'true' cannot be a descendant of 'true' (we'll just keep the more shallow
/// 'true').
/// * 'false' cannot be a descendant of 'false' (we'll just keep the more
/// shallow 'false').
class PruneForest {
  final ModifiableTreeNode<Name, bool?> pruneForest;

  static final Predicate<bool?> KEEP_PREDICATE =
      (prune) => prune != null && !prune;

  static final Predicate<bool?> PRUNE_PREDICATE = (prune) => prune == true;

  static final ModifiableTreeNode<Name, bool?> PRUNE_TREE =
      ModifiableTreeNode(true);
  static final ModifiableTreeNode<Name, bool?> KEEP_TREE =
      ModifiableTreeNode(false);

  PruneForest() : pruneForest = ModifiableTreeNode(null);

  PruneForest._(this.pruneForest);

  bool prunesAnything() => pruneForest.containsMatchingValue(PRUNE_PREDICATE);

  /// Indicates that path is marked for pruning, so anything below it that
  /// didn't have keep() called on it should be pruned.
  bool shouldPruneUnkeptDescendants(Path<Name> path) {
    var shouldPrune = pruneForest.leafMostValueMatching(path, (v) => v != null);
    return shouldPrune != null && shouldPrune;
  }

  bool shouldKeep(Path<Name> path) {
    var shouldPrune = pruneForest.leafMostValueMatching(path, (v) => v != null);
    return shouldPrune != null && !shouldPrune;
  }

  bool affectsPath(Path<Name> path) {
    return pruneForest.rootMostValueMatching(path, (v) => v != null) != null ||
        pruneForest.subtreeNullable(path)?.isEmpty == false;
  }

  PruneForest directChild(Name key) {
    var childPruneTree = pruneForest.children[key];
    if (childPruneTree == null) {
      childPruneTree = ModifiableTreeNode(pruneForest.value);
    } else {
      if (childPruneTree.value == null && pruneForest.value != null) {
        childPruneTree =
            ModifiableTreeNode(pruneForest.value, childPruneTree.children);
      }
    }
    return PruneForest._(childPruneTree);
  }

  PruneForest child(Path<Name> path) {
    if (path.isEmpty) {
      return this;
    } else {
      return directChild(path.first).child(path.skip(1));
    }
  }

  T foldKeptNodes<T>(T startValue, T Function(Path<Name>, bool?, T accum) f) {
    pruneForest.forEachNode((key, value) {
      if (value == false) {
        startValue = f(key, value, startValue);
      }
    });
    return startValue;
  }

  PruneForest prune(Path<Name> path) {
    if (pruneForest.rootMostValueMatching(path, KEEP_PREDICATE) != null) {
      throw ArgumentError("Can't prune path that was kept previously!");
    }
    if (pruneForest.rootMostValueMatching(path, PRUNE_PREDICATE) != null) {
      // This path will already be pruned
      return this;
    } else {
      var newPruneTree = pruneForest.setPath(path, PRUNE_TREE, null);
      return PruneForest._(newPruneTree);
    }
  }

  PruneForest keep(Path<Name> path) {
    if (pruneForest.rootMostValueMatching(path, KEEP_PREDICATE) != null) {
      // This path will already be kept
      return this;
    } else {
      var newPruneTree = pruneForest.setPath(path, KEEP_TREE, null);
      return PruneForest._(newPruneTree);
    }
  }

  PruneForest keepAll(Path<Name> path, Set<Name> children) {
    if (pruneForest.rootMostValueMatching(path, KEEP_PREDICATE) != null) {
      // This path will already be kept
      return this;
    } else {
      return _doAll(path, children, KEEP_TREE);
    }
  }

  PruneForest pruneAll(Path<Name> path, Set<Name> children) {
    if (pruneForest.rootMostValueMatching(path, KEEP_PREDICATE) != null) {
      throw ArgumentError("Can't prune path that was kept previously!");
    }

    if (pruneForest.rootMostValueMatching(path, PRUNE_PREDICATE) != null) {
      // This path will already be kept
      return this;
    } else {
      return _doAll(path, children, PRUNE_TREE);
    }
  }

  PruneForest _doAll(Path<Name> path, Set<Name> children,
      ModifiableTreeNode<Name, bool?> keepOrPruneTree) {
    var subtree =
        pruneForest.subtree(path, (_, __) => ModifiableTreeNode(null));
    var childrenMap = {
      ...subtree.children,
      for (var key in children) key: keepOrPruneTree
    };
    return PruneForest._(pruneForest.setPath(
        path, ModifiableTreeNode(subtree.value, childrenMap), null));
  }

  @override
  bool operator ==(o) {
    if (identical(this, o)) {
      return true;
    }

    return o is PruneForest &&
        const TreeNodeEquality().equals(o.pruneForest, pruneForest);
  }

  @override
  int get hashCode => const TreeNodeEquality().hash(pruneForest);

  @override
  String toString() => '{PruneForest:$pruneForest}';
}
