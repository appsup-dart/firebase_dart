import '../tree.dart';
import '../treestructureddata.dart';
import '../utils.dart';

/// This class holds a collection of writes that can be applied to nodes in
/// unison.
///
/// It abstracts away the logic with dealing with priority writes and multiple
/// nested writes.
///
/// At any given path there is only allowed to be one write modifying that path.
/// Any write to an existing path or shadowing an existing path will modify that
/// existing write to reflect the write added.
class CompoundWrite {
  final TreeNode<Name, TreeStructuredData> _writeTree;

  CompoundWrite._(this._writeTree);
  CompoundWrite.empty() : this._(TreeNode());

  factory CompoundWrite.fromValue(Map<String, dynamic> merge) {
    return CompoundWrite.fromChildMerge(
        merge.map((k, v) => MapEntry(Name(k), TreeStructuredData.fromJson(v))));
  }

  factory CompoundWrite.fromChildMerge(Map<Name, TreeStructuredData> merge) {
    return CompoundWrite.fromPathMerge(
        merge.map((k, v) => MapEntry(Path.from([k]), v)));
  }

  factory CompoundWrite.fromPathMerge(
      Map<Path<Name>, TreeStructuredData> merge) {
    var writeTree = TreeNode<Name, TreeStructuredData>();
    for (var entry in merge.entries) {
      var tree = TreeNode<Name, TreeStructuredData>(entry.value);
      writeTree = writeTree.setPath(entry.key, tree);
    }
    return CompoundWrite._(writeTree);
  }

  CompoundWrite addWrite(Path<Name> path, TreeStructuredData node) {
    print('addWrite $path $node');
    if (path.isEmpty) {
      return CompoundWrite._(TreeNode(node));
    } else {
      Path rootMostPath = _writeTree.findRootMostPathWithValue(path);
      print('rootMostPath $rootMostPath');
      if (rootMostPath != null) {
        var relativePath = path.skip(rootMostPath.length);
        var value = _writeTree.subtree(rootMostPath).value;
        print('relativePath $relativePath $value');
        var back = relativePath.last;
        if (back != null &&
            back.isPriorityChildName &&
            value.getChild(relativePath.parent).isEmpty) {
          // Ignore priority updates on empty nodes
          return this;
        } else {
          value = value.updateChild(relativePath, node);
          print('new value $value');
          return CompoundWrite._(_writeTree.setValue(rootMostPath, value));
        }
      } else {
        var subtree = TreeNode<Name, TreeStructuredData>(node);
        var newWriteTree = _writeTree.setPath(path, subtree);
        print('new tree $newWriteTree');
        return CompoundWrite._(newWriteTree);
      }
    }
  }

  CompoundWrite addWrites(Path<Name> path, CompoundWrite updates) {
    var accum = this;
    updates._writeTree.forEachNode((relativePath, value) {
      accum = accum.addWrite(Path.from([...path, ...relativePath]), value);
    });
    return accum;
  }

  /// Will remove a write at the given path and deeper paths.
  ///
  /// This will *not* modify a write at a higher location, which must be removed
  /// by calling this method with that path.
  CompoundWrite removeWrite(Path<Name> path) {
    if (path.isEmpty) {
      return CompoundWrite.empty();
    } else {
      var newWriteTree = _writeTree.setPath(path, TreeNode());
      return CompoundWrite._(newWriteTree);
    }
  }

  /// Returns whether this CompoundWrite will fully overwrite a node at a given
  /// location and can therefore be considered "complete".
  bool hasCompleteWrite(Path<Name> path) {
    return getCompleteNode(path) != null;
  }

  TreeStructuredData rootWrite() {
    return _writeTree.value;
  }

  /// Returns a node for a path if and only if the node is a "complete"
  /// overwrite at that path.
  ///
  /// This will not aggregate writes from deeper paths, but will return child
  /// nodes from a more shallow path.
  TreeStructuredData getCompleteNode(Path<Name> path) {
    Path rootMost = _writeTree.findRootMostPathWithValue(path);
    if (rootMost != null) {
      return _writeTree
          .subtree(rootMost)
          .value
          .getChild(path.skip(rootMost.length));
    } else {
      return null;
    }
  }

  /// Returns all children that are guaranteed to be a complete overwrite.
  ///
  /// @return A list of all complete children.
  Iterable<MapEntry<Name, TreeStructuredData>> getCompleteChildren() {
    if (_writeTree.value != null) {
      return _writeTree.value.children.entries;
    } else {
      return _writeTree.children.entries
          .where((v) => v.value.value != null)
          .map((e) => MapEntry(e.key, e.value.value));
    }
  }

  CompoundWrite childCompoundWrite(Path<Name> path) {
    if (path.isEmpty) {
      return this;
    } else {
      var shadowingNode = getCompleteNode(path);
      if (shadowingNode != null) {
        return CompoundWrite._(TreeNode(shadowingNode));
      } else {
        // let the constructor extract the priority update
        return CompoundWrite._(_writeTree.subtree(path));
      }
    }
  }

  Map<Name, CompoundWrite> childCompoundWrites() {
    var children = <Name, CompoundWrite>{};
    for (var entries in _writeTree.children.entries) {
      children[entries.key] = CompoundWrite._(entries.value);
    }
    return children;
  }

  /// Returns true if this CompoundWrite is empty and therefore does not modify
  /// any nodes.
  bool get isEmpty => _writeTree.isEmpty && _writeTree.value == null;

  TreeStructuredData _applySubtreeWrite(Path<Name> relativePath,
      TreeNode<Name, TreeStructuredData> writeTree, TreeStructuredData node) {
    if (writeTree.value != null) {
      // Since there a write is always a leaf, we're done here
      return node.updateChild(relativePath, writeTree.value);
    } else {
      TreeStructuredData priorityWrite;
      for (var childTreeEntry in writeTree.children.entries) {
        var childTree = childTreeEntry.value;
        var childKey = childTreeEntry.key;
        if (childKey.isPriorityChildName) {
          // Apply priorities at the end so we don't update priorities for either empty nodes or
          // forget to apply priorities to empty nodes that are later filled
          assert(
              childTree.isEmpty, 'Priority writes must always be leaf nodes');
          priorityWrite = childTree.value;
        } else {
          node =
              _applySubtreeWrite(relativePath.child(childKey), childTree, node);
        }
      }
      // If there was a priority write, we only apply it if the node is not empty
      if (!node.getChild(relativePath).isEmpty && priorityWrite != null) {
        node = node.updateChild(
            relativePath.child(NameX.priorityKey), priorityWrite);
      }
      return node;
    }
  }

  /// Applies this CompoundWrite to a node.
  ///
  /// The node is returned with all writes from this CompoundWrite applied to
  /// the node
  TreeStructuredData apply(TreeStructuredData node) {
    return _applySubtreeWrite(Path(), _writeTree, node);
  }

  /// Returns a serializable version of this CompoundWrite
  Map<String, dynamic> getValue(bool exportFormat) {
    var writes = <String, dynamic>{};
    _writeTree.forEachNode((relativePath, value) {
      writes[relativePath.join('/')] = value?.toJson(exportFormat);
    });
    return writes;
  }

  void forEach(void Function(Path<Name> key, TreeStructuredData value) f) =>
      _writeTree.forEachNode(f);

  @override
  int get hashCode => const TreeNodeEquality().hash(_writeTree);

  @override
  bool operator ==(o) {
    if (identical(o, this)) {
      return true;
    }
    return o is CompoundWrite &&
        const TreeNodeEquality().equals(_writeTree, o._writeTree);
  }

  @override
  String toString() => 'CompoundWrite{${getValue(true)}}';
}
