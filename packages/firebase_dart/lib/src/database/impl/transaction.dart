// @dart=2.9

part of 'repo.dart';

enum TransactionStatus {
  readyToRun,
  running,
  run,
  sent,
  completed,
  sentNeedsAbort
}

class Transaction implements Comparable<Transaction> {
  final Path<Name> path;
  final TransactionHandler update;
  final bool applyLocally;
  final Repo repo;
  final int order;
  final Completer<TreeStructuredData> completer = Completer();

  static int _order = 0;

  static const int maxRetries = 25;

  int retryCount = 0;
  FirebaseDatabaseException abortReason;
  int currentWriteId;
  TreeStructuredData currentInputSnapshot;
  TreeStructuredData currentOutputSnapshotRaw;
  TreeStructuredData currentOutputSnapshotResolved;

  TransactionStatus status = TransactionStatus.readyToRun;

  Transaction(this.repo, this.path, this.update, this.applyLocally)
      : order = _order++ {
    _watch();
  }

  bool get isSent =>
      status == TransactionStatus.sent ||
      status == TransactionStatus.sentNeedsAbort;

  bool get isComplete => status == TransactionStatus.completed;

  bool get isAborted => status == TransactionStatus.sentNeedsAbort;

  void _onValue(Event _) {}

  void _watch() {
    repo.listen(path.join('/'), null, 'value', _onValue);
  }

  void _unwatch() {
    repo.unlisten(path.join('/'), null, 'value', _onValue);
  }

  void run(TreeStructuredData currentState) {
    assert(status == TransactionStatus.readyToRun);
    status = TransactionStatus.running;
    if (retryCount >= maxRetries) {
      fail(FirebaseDatabaseException.maxRetries());
      return;
    }

    currentInputSnapshot = currentState;
    var data = MutableData(
        path.isEmpty ? null : path.last.toString(), currentState.toJson());

    try {
      data = update(data);
    } catch (e) {
      fail(FirebaseDatabaseException.userCodeException());
      return;
    }

    if (data == null) {
      fail(null);
      return;
    }
    status = TransactionStatus.run;

    var newNode =
        TreeStructuredData.fromJson(data.value, currentState.priority);
    currentOutputSnapshotRaw = newNode;
    currentOutputSnapshotResolved =
        ServerValueX.resolve(newNode, repo._connection.serverValues);
    currentWriteId = repo._nextWriteId++;

    if (applyLocally) {
      repo._syncTree.applyUserOverwrite(
          path, currentOutputSnapshotResolved, currentWriteId);
    }
  }

  void fail(FirebaseDatabaseException e) {
    _unwatch();
    currentOutputSnapshotRaw = null;
    currentOutputSnapshotResolved = null;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
    status = TransactionStatus.completed;

    if (e == null) {
      // aborted by user
      completer.complete(null);
    } else {
      completer.completeError(e);
    }
  }

  void stale() {
    assert(status != TransactionStatus.completed);
    status = TransactionStatus.readyToRun;
    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
  }

  void send() {
    assert(status == TransactionStatus.run);
    status = TransactionStatus.sent;
    retryCount++;
  }

  void abort(FirebaseDatabaseException reason) {
    switch (status) {
      case TransactionStatus.sentNeedsAbort:
        break;
      case TransactionStatus.sent:
        status = TransactionStatus.sentNeedsAbort;
        abortReason = reason;
        break;
      case TransactionStatus.readyToRun:
      case TransactionStatus.running:
      case TransactionStatus.run:
        fail(reason);
        break;
      default:
        throw StateError('Unable to abort transaction in state $status');
    }
  }

  void complete() {
    assert(isSent);
    status = TransactionStatus.completed;

    if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, true);

    completer.complete(currentOutputSnapshotResolved);

    _unwatch();
  }

  @override
  int compareTo(Transaction other) => Comparable.compare(order, other.order);
}

class TransactionsTree {
  final Repo repo;
  final TransactionsNode root = TransactionsNode();

  TransactionsTree(this.repo);

  Future<TreeStructuredData> startTransaction(Path<Name> path,
      TransactionHandler transactionUpdate, bool applyLocally) {
    var transaction = Transaction(repo, path, transactionUpdate, applyLocally);
    var node = root.subtree(path, (a, b) => TransactionsNode());

    var current = getLatestValue(repo._syncTree, path);
    if (node.value.isEmpty) {
      node.input = current;
    }
    transaction.run(current);
    node.addTransaction(transaction);
    send();

    return transaction.completer.future;
  }

  void send() {
    root.send(repo, Path()).then((finished) {
      if (!finished) send();
    });
  }

  void abort(Path<Name> path, FirebaseDatabaseException exception) {
    for (var n in root.nodesOnPath(path)) {
      n.abort(exception);
    }
    var n = root.subtree(path);
    if (n == null) return;

    for (var n in n.childrenDeep) {
      n.abort(exception);
    }
  }
}

TreeStructuredData getLatestValue(SyncTree syncTree, Path<Name> path) {
  var nodes = syncTree.root.nodesOnPath(path);
  var subpath = path.skip(nodes.length - 1);
  var node = nodes.last;

  var point = node.value;
  for (var n in subpath) {
    point = point.child(n);
  }
  return point.valueForFilter(QueryFilter());
}

class TransactionsNode extends TreeNode<Name, List<Transaction>> {
  TransactionsNode() : super([], SortedMap<Name, TransactionsNode>());

  @override
  Map<Name, TransactionsNode> get children => super.children;

  @override
  TransactionsNode subtree(Path<Name> path,
          [TreeNode<Name, List<Transaction>> Function(
                  List<Transaction> parent, Name childName)
              newInstance]) =>
      super.subtree(path, newInstance);

  bool get isReadyToSend =>
      value.every((t) => t.status == TransactionStatus.run) &&
      children.values.every((n) => n.isReadyToSend);

  bool get needsRerun =>
      value.any((t) => t.status == TransactionStatus.readyToRun) ||
      children.values.any((n) => n.needsRerun);

  @override
  Iterable<TransactionsNode> nodesOnPath(Path<Name> path) =>
      super.nodesOnPath(path).map((v) => v as TransactionsNode);

  /// Completes all sent transactions
  void complete() {
    // complete all transactions that were sent and executed successfully,
    // also when they are marked for abort
    value.where((t) => t.isSent).forEach((m) => m.complete());
    // remove the transactions that are now complete
    value = value.where((t) => !t.isComplete).toList();
    // reset the status of all other transactions
    value.forEach((m) => m.status = TransactionStatus.readyToRun);

    // repeat for all children
    children.values.forEach((n) => n.complete());
  }

  /// Fails aborted transactions and resets other sent transactions
  ///
  /// A stale is executed when an attempt to write data failed, because the hash
  /// did not match, meaning that the data has been changed by another process.
  void stale() {
    // all transactions that were marked for abort, should fail
    value.where((t) => t.isAborted).forEach((m) => m.fail(m.abortReason));
    // and be removed from the list
    value = value.where((t) => !t.isComplete).toList();

    // all non aborted transactions should execute again
    value.where((t) => !t.isAborted).forEach((m) => m.stale());

    // repeat for all children
    children.values.forEach((n) => n.stale());
  }

  /// Fails all sent transactions
  ///
  /// Transactions were sent, but failed with reason other than concurrent write.
  /// The transactions will be stopped and return an error.
  void fail(FirebaseDatabaseException e) {
    // fail all sent transactions
    value.where((t) => t.isSent).forEach((m) => m.fail(e));
    // remove the failed transactions
    value = value.where((t) => !t.isComplete).toList();

    // repeat for children
    children.values.forEach((n) => n.fail(e));
  }

  void _send() {
    value.forEach((m) => m.send());
    children.values.forEach((n) => n._send());
  }

  Future<bool> send(Repo repo, Path<Name> path) async {
    if (value.isNotEmpty) {
      if (needsRerun) {
        stale();
        rerun(path, getLatestValue(repo._syncTree, path));
      }
      if (isReadyToSend) {
        var latestHash = input.hash;
        try {
          _send();
          await repo._connection
              .put(path.join('/'), output.toJson(true), hash: latestHash);
          complete();
          return false;
        } on firebase.FirebaseDatabaseException catch (e) {
          if (e.code == 'datastale') {
            stale();
          } else {
            fail(e);
          }
          return false;
        }
      }
      return true;
    } else {
      var allFinished = true;
      for (var k in children.keys.toList()) {
        allFinished =
            allFinished && await children[k].send(repo, path.child(k));
      }
      return allFinished;
    }
  }

  Iterable<Transaction> get transactionsInOrder =>
      List.from(_transactions)..sort();

  Iterable<Transaction> get _transactions sync* {
    yield* value;
    yield* children.values.expand<Transaction>((n) => n._transactions);
  }

  Iterable<TransactionsNode> get childrenDeep sync* {
    yield* children.values;
    yield* children.values.expand((n) => n.childrenDeep);
  }

  void rerun(Path<Name> path, TreeStructuredData input) {
    this.input = input;

    var v = input;
    for (var t in transactionsInOrder) {
      var p = t.path.skip(path.length);
      t.run(v.getChild(p));
      if (!t.isComplete) {
        v = v.updateChild(p, t.currentOutputSnapshotResolved);
      }
    }
  }

  TreeStructuredData input;

  int get lastId => max(
      value.isEmpty ? -1 : value.map((t) => t.order).reduce(max),
      children.isEmpty
          ? -1
          : children.values.map((n) => n.lastId).reduce(max) ?? -1);

  TreeStructuredData get output {
    var v = input;
    var lastId = -1;
    if (value.isNotEmpty) {
      v = value.last.currentOutputSnapshotRaw;
      lastId = value.last.order;
    }
    children.forEach((key, node) {
      if (node.lastId > lastId) {
        v = v.withChild(key, node.output);
      }
    });
    return v;
  }

  void addTransaction(Transaction transaction) {
    if (transaction.status == TransactionStatus.run) {
      value.add(transaction);
    }
  }

  void abort(FirebaseDatabaseException exception) {
    for (var txn in value) {
      txn.abort(exception);
    }
    value = value.where((t) => !t.isComplete).toList();
  }
}

class SparseSnapshotTree extends TreeNode<Name, TreeStructuredData> {
  SparseSnapshotTree() : super(null, SortedMap<Name, SparseSnapshotTree>());

  @override
  Map<Name, SparseSnapshotTree> get children => super.children;

  void remember(Path<Name> path, TreeStructuredData data) {
    if (path.isEmpty) {
      value = data;
      children.clear();
    } else {
      if (value != null) {
        value = value.updateChild(path, data);
      } else {
        var childKey = path.first;
        children.putIfAbsent(childKey, () => SparseSnapshotTree());
        var child = children[childKey];
        path = path.skip(1);
        child.remember(path, data);
      }
    }
  }

  bool forget(Path<Name> path) {
    if (path.isEmpty) {
      value = null;
      children.clear();
      return true;
    } else {
      if (value != null) {
        if (value.isLeaf) {
          return false;
        } else {
          var oldValue = value;
          value = null;
          oldValue.children.forEach((key, tree) {
            remember(Path.from([key]), tree);
          });
          return forget(path);
        }
      } else {
        var childKey = path.first;
        path = path.skip(1);
        if (children.containsKey(childKey)) {
          var safeToRemove = children[childKey].forget(path);
          if (safeToRemove) {
            children.remove(childKey);
          }
        }
        if (children.isEmpty) {
          return true;
        } else {
          return false;
        }
      }
    }
  }
}
