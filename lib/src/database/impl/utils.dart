import 'package:collection/collection.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:quiver/core.dart';

typedef Predicate<T> = bool Function(T);

extension TreeNodeX<T> on TreeNode<Name, T> {
  bool containsMatchingValue(Predicate<T> predicate) {
    if (value != null && predicate(value)) {
      return true;
    } else {
      for (var subtree in children.values) {
        if (subtree.containsMatchingValue(predicate)) {
          return true;
        }
      }
      return false;
    }
  }

  T leafMostValue(Path<Name> relativePath) {
    // TODO: isn't this the value at relativePath
    return leafMostValueMatching(relativePath, (_) => true);
  }

  /// Returns the deepest value found between the root and the specified path
  /// that matches the predicate.
  T leafMostValueMatching(Path<Name> path, Predicate<T> predicate) {
    var currentValue = (value != null && predicate(value)) ? value : null;
    var currentTree = this;
    for (var key in path) {
      currentTree = currentTree.children[key];
      if (currentTree == null) {
        return currentValue;
      } else {
        if (currentTree.value != null && predicate(currentTree.value)) {
          currentValue = currentTree.value;
        }
      }
    }
    return currentValue;
  }

  T rootMostValue(Path<Name> relativePath) {
    // TODO: isn't this the root?
    return rootMostValueMatching(relativePath, (_) => true);
  }

  T rootMostValueMatching(Path<Name> relativePath, Predicate<T> predicate) {
    if (value != null && predicate(value)) {
      return value;
    } else {
      var currentTree = this;
      for (var key in relativePath) {
        currentTree = currentTree.children[key];
        if (currentTree == null) {
          return null;
        } else if (currentTree.value != null && predicate(currentTree.value)) {
          return currentTree.value;
        }
      }
      return null;
    }
  }

  Path<Name> findRootMostPathWithValue(Path<Name> relativePath) =>
      findRootMostMatchingPath(relativePath, (v) => v != null);

  Path<Name> findRootMostMatchingPath(
      Path<Name> relativePath, Predicate<T> predicate) {
    if (value != null && predicate(value)) {
      return Path();
    } else {
      if (relativePath.isEmpty) {
        return null;
      } else {
        var front = relativePath.first;
        var child = children[front];
        if (child != null) {
          Path path =
              child.findRootMostMatchingPath(relativePath.skip(1), predicate);
          if (path != null) {
            // TODO: this seems inefficient
            return Path<Name>.from([front, ...path]);
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
    }
  }

  TreeNode<Name, T> setPath(Path<Name> path, TreeNode<Name, T> subtree) {
    if (path.isEmpty) return subtree;

    var c = children[path.first] ?? TreeNode();

    return TreeNode(
        value, {...children, path.first: c.setPath(path.skip(1), subtree)});
  }

  TreeNode<Name, T> setValue(Path<Name> path, T value) {
    if (path.isEmpty) return TreeNode(value, children);

    var c = children[path.first] ?? TreeNode();

    return TreeNode(
        this.value, {...children, path.first: c.setValue(path.skip(1), value)});
  }

  TreeNode<Name, T> removePath(Path<Name> path) {
    if (path.isEmpty) return null;

    var c = this.children[path.first] ?? TreeNode();

    c = c.removePath(path.skip(1));
    var children = {...this.children, path.first: c};
    if (c == null) children.remove(path.first);
    if (value == null && children.isEmpty) return null;
    return TreeNode(value, children);
  }

  Iterable<T> get allNonNullValues sync* {
    if (value != null) yield value;
    for (var c in children.values) {
      yield* c.allNonNullValues;
    }
  }
}

class TreeNodeEquality<K extends Comparable, V>
    implements Equality<TreeNode<K, V>> {
  static const _childrenEquality = MapEquality(values: TreeNodeEquality());
  const TreeNodeEquality();

  @override
  bool equals(TreeNode<K, V> e1, TreeNode<K, V> e2) {
    return e1.value == e2.value &&
        _childrenEquality.equals(e1.children, e2.children);
  }

  @override
  int hash(TreeNode<K, V> e) {
    return hash2(_childrenEquality.hash(e.children), e.value);
  }

  @override
  bool isValidKey(Object o) {
    return o is TreeNode<K, V>;
  }
}

extension NameX on Name {
  static const priorityKey = Name('.priority');

  bool get isPriorityChildName => this == priorityKey;
}

extension TreeStructuredDataX on TreeStructuredData {
  TreeStructuredData getChild(Path<Name> path) {
    return subtree(path) ?? TreeStructuredData();
  }

  TreeStructuredData updateChild(Path<Name> path, TreeStructuredData value) {
    if (path.isEmpty) return value;
    if (path.last.isPriorityChildName) {
      return updatePriority(path.parent, value.value);
    }

    var c = children[path.first] ?? TreeStructuredData();

    var newChild = c.updateChild(path.skip(1), value);
    var newChildren = {...children, path.first: newChild};
    if (newChild.isNil) newChildren.remove(path.first);

    if (newChildren.isEmpty) {
      return TreeStructuredData.leaf(this.value, priority);
    }
    return TreeStructuredData.nonLeaf(newChildren, priority);
  }

  TreeStructuredData updatePriority(Path<Name> path, Value priority) {
    var c = getChild(path);
    if (c.isNil) return this;
    if (c.isEmpty) {
      c = TreeStructuredData.leaf(c.value, priority);
    } else {
      c = TreeStructuredData.nonLeaf(c.children, priority);
    }
    return updateChild(path, c);
  }
}