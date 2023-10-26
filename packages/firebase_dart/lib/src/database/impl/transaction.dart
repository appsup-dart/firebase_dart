part of 'repo.dart';

enum TransactionStatus {
  /// The transaction is ready to be run. It has not applied any local writes.
  readyToRun,

  /// The transaction is running and waiting for the user code to finish.
  running,

  /// The transaction ran and applied the result locally.
  runComplete,

  /// The result of the transaction has been sent to the server, now waiting for
  /// confirmation of the server.
  sent,

  /// The transaction has completed, either successfully or it failed. All
  /// writes have been acknowledged, so the transaction can be removed safely
  /// from the tree.
  completed,

  /// The transaction result was sent to the server, but the write was
  /// subsequently cancelled or overriden by the user. The transaction should
  /// complete successfully when the server confirms the sent data and be
  /// canceled otherwise.
  sentNeedsAbort
}

class Transaction implements Comparable<Transaction> {
  final Path<Name> path;
  final TransactionHandler update;
  final bool applyLocally;
  final Repo repo;
  final int order;
  final Completer<TreeStructuredData?> completer = Completer();

  static int _order = 0;

  static const int maxRetries = 25;

  int retryCount = 0;
  FirebaseDatabaseException? abortReason;
  final int currentWriteId;
  TreeStructuredData? currentInputSnapshot;
  TreeStructuredData? currentOutputSnapshotRaw;
  TreeStructuredData? currentOutputSnapshotResolved;

  TransactionStatus status = TransactionStatus.readyToRun;

  Transaction(this.repo, this.path, this.update, this.applyLocally)
      : order = _order++,
        currentWriteId = repo._nextWriteId++ {
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

  /// Run the transaction and apply the result to the sync tree if
  /// [applyLocally] is true.
  Future<void> run(TreeStructuredData currentState) async {
    assert(status == TransactionStatus.readyToRun);
    status = TransactionStatus.running;
    if (retryCount >= maxRetries) {
      fail(FirebaseDatabaseException.maxRetries());
      return;
    }

    currentInputSnapshot = currentState;
    MutableData? data = MutableData(
        path.isEmpty ? null : path.last.toString(), currentState.toJson());

    try {
      data = await update(data);
    } catch (e) {
      fail(FirebaseDatabaseException.userCodeException());
      return;
    }

    if (data == null) {
      fail(null);
      return;
    }
    status = TransactionStatus.runComplete;

    var newNode =
        TreeStructuredData.fromJson(data.value, currentState.priority);
    currentOutputSnapshotRaw = newNode;
    currentOutputSnapshotResolved =
        ServerValueX.resolve(newNode, repo._connection.serverValues);

    if (applyLocally) {
      repo._syncTree.applyUserOverwrite(
          path, currentOutputSnapshotResolved!, currentWriteId);
    }
  }

  /// Completes this transaction as failed.
  ///
  /// When the result of the transaction was applied locally, the local write
  /// is canceled.
  void fail(FirebaseDatabaseException? e) {
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

  /// Resets this transaction to the [TransactionStatus.readyToRun] state.
  ///
  /// If the transaction has run before and therefore changes were applied
  /// locally (if [applyLocally] is true), these changes are canceled.
  void reset() {
    switch (status) {
      case TransactionStatus.readyToRun:
        return;
      case TransactionStatus.runComplete:
      case TransactionStatus.sent:
      case TransactionStatus.sentNeedsAbort:
        status = TransactionStatus.readyToRun;
        if (applyLocally) repo._syncTree.applyAck(path, currentWriteId, false);
        return;
      case TransactionStatus.running:
        throw StateError('Cannot reset transaction while running');
      case TransactionStatus.completed:
        throw StateError('Connot reset transaction when completed');
    }
  }

  /// Mark this transaction as sent.
  void markSent() {
    assert(status == TransactionStatus.runComplete);
    status = TransactionStatus.sent;
    retryCount++;
  }

  /// Cancels and fails the transaction when it was not yet sent to the server
  /// or marks the transaction for abort later when response received from
  /// server. In the latter case, the transaction will fail when the server
  /// responds with a failure or succeed when the server responds with a success.
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
      case TransactionStatus.runComplete:
        fail(reason);
        break;
      case TransactionStatus.completed:
        throw StateError('Cannot abort transaction when completed');
    }
  }

  /// Completes the transaction successfully.
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

  Future<TreeStructuredData?> startTransaction(Path<Name> path,
      TransactionHandler transactionUpdate, bool applyLocally) {
    var transaction = Transaction(repo, path, transactionUpdate, applyLocally);
    var node = root.subtree(path, (a, b) => TransactionsNode());

    if (node.value.isEmpty) {
      var current = getLatestValue(repo._syncTree, path);
      node.input = current;
    }
    node.addTransaction(transaction);
    execute();

    return transaction.completer.future;
  }

  Future<void>? _executeFuture;

  /// Executes all transactions
  void execute() {
    _executeFuture ??= Future(() async {
      await repo._syncTree.waitForAllProcessed();
      var finished = await root.execute();
      _executeFuture = null;
      if (!finished) {
        await Future.delayed(Duration(milliseconds: 20));
        execute();
      }
    });
  }

  /// Aborts all transactions at [path] with reason [exception]
  void abort(Path<Name> path, FirebaseDatabaseException exception) {
    for (var n in root.nodesOnPath(path)) {
      n.abort(exception);
    }
    var n = root.subtreeNullable(path);
    if (n == null) return;

    for (var n in n.childrenDeep) {
      n.abort(exception);
    }
  }

  Future<void> close() async {
    abort(Path(), FirebaseDatabaseException.appDeleted());
    await _executeFuture;
  }
}

class TransactionsNode extends ModifiableTreeNode<Name, List<Transaction>> {
  TransactionsNode() : super([], SortedMap<Name, TransactionsNode>());

  @override
  Map<Name, TransactionsNode> get children =>
      super.children as Map<Name, TransactionsNode>;

  @override
  TransactionsNode? subtreeNullable(Path<Name> path) =>
      super.subtreeNullable(path) as TransactionsNode?;

  @override
  TransactionsNode subtree(
          Path<Name> path,
          ModifiableTreeNode<Name, List<Transaction>> Function(
                  List<Transaction> parent, Name childName)
              newInstance) =>
      super.subtree(path, newInstance) as TransactionsNode;

  /// All transactions in this node and child nodes are ready to be sent, in
  /// other words, they have run.
  bool get isReadyToSend =>
      value.every((t) => t.status == TransactionStatus.runComplete) &&
      children.values.every((n) => n.isReadyToSend);

  /// Some transactions of this node or child nodes have not run yet.
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
    for (var m in value) {
      m.reset();
    }

    // repeat for all children
    for (var n in children.values) {
      n.complete();
    }
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
    value.where((t) => !t.isAborted).forEach((m) => m.reset());

    // repeat for all children
    for (var n in children.values) {
      n.stale();
    }
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
    for (var n in children.values) {
      n.fail(e);
    }
  }

  void markAllTransactionsSent() {
    for (var m in value) {
      m.markSent();
    }
    for (var n in children.values) {
      n.markAllTransactionsSent();
    }
  }

  /// Executes the transactions in this node and child nodes and sends the
  /// results to the server.
  ///
  /// When this node does not contain own transactions, the children will be
  /// executed in parallel.
  ///
  /// Returns true when there is no additional work to be done for the moment,
  /// either because there are no more transactions or because we are waiting
  /// for user code to finish or for a response of the server.
  Future<bool> execute() async {
    // remove completed (failed) transactions from the list
    value = value.where((t) => !t.isComplete).toList();
    if (value.isNotEmpty) {
      var repo = value.first.repo;
      var path = value.first.path;
      if (needsRerun) {
        return !(await rerun(path));
      }
      if (isReadyToSend) {
        var latestHash = input!.hash;
        try {
          markAllTransactionsSent();
          var out = output!;
          await repo._connection
              .put(path.join('/'), output!.toJson(true), hash: latestHash);
          complete();

          if (out == ServerValueX.resolve(out, repo._connection.serverValues)) {
            // the confirmed value did not contain any server values, so we can reset the input to the confirmed value
            input = out;
          } else {
            // the transactions that ran after the sent, were not based on the correct input data, so we will reset them
            stale();
          }
          return false;
        } on firebase.FirebaseDatabaseException catch (e) {
          if (e.code == 'datastale') {
            stale();
            input = getLatestValue(repo._syncTree, path);
          } else {
            fail(e);
          }
          return false;
        }
      }
      return true;
    } else {
      if (_isRunning) return false;
      var allFinished = true;
      for (var k in children.keys.toList()) {
        allFinished = allFinished && await children[k]!.execute();
      }
      return allFinished;
    }
  }

  /// All transactions of this node and child nodes in chronological order
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

  bool _isRunning = false;

  bool get isRunning => _isRunning || children.values.any((v) => v.isRunning);

  /// Runs the transactions that have not yet run. Transaction that have already
  /// run are skipped if the input did not change. If the input did change and
  /// the result was not yet sent to the server, the transaction is reset and
  /// rerun. Otherwise, this rerun is aborted.
  ///
  /// Returns true if all transactions have run, false if the process was
  /// aborted prematurely.
  Future<bool> rerun(Path<Name> path) async {
    if (isRunning) return false;
    _isRunning = true;
    var v = input;
    for (var t in transactionsInOrder) {
      var p = t.path.skip(path.length);
      switch (t.status) {
        case TransactionStatus.readyToRun:
          await t.run(v!.getChild(p));
          break;
        case TransactionStatus.runComplete:
          if (v!.getChild(p) != t.currentInputSnapshot) {
            t.reset();
            await t.run(v.getChild(p));
          }
          break;
        case TransactionStatus.sent:
        case TransactionStatus.sentNeedsAbort:
          if (v!.getChild(p) != t.currentInputSnapshot) {
            // we cannot continue running and need to wait for the server response
            _isRunning = false;
            return false;
          }
          break;
        case TransactionStatus.running:
          throw StateError(
              'Should not call rerun when transactions are running');
        case TransactionStatus.completed:
          // transaction might be aborted while running
          continue;
      }
      v = v.updateChild(
          p, t.currentOutputSnapshotResolved ?? TreeStructuredData());
    }
    _isRunning = false;
    return true;
  }

  TreeStructuredData? input;

  int get lastId => max(
      value.isEmpty ? -1 : value.map((t) => t.order).reduce(max),
      children.isEmpty ? -1 : children.values.map((n) => n.lastId).reduce(max));

  TreeStructuredData? get output {
    var v = input;
    var lastId = -1;
    if (value.isNotEmpty) {
      v = value.last.currentOutputSnapshotRaw;
      lastId = value.last.order;
    }
    children.forEach((key, node) {
      if (node.lastId > lastId) {
        v = v!.withChild(key, node.output!);
      }
    });
    return v;
  }

  void addTransaction(Transaction transaction) {
    if (transaction.status == TransactionStatus.readyToRun) {
      value.add(transaction);
    }
  }

  void abort(FirebaseDatabaseException exception) {
    for (var txn in value) {
      if (!txn.isComplete) txn.abort(exception);
    }
    value = value.where((t) => !t.isComplete).toList();
  }
}

class SparseSnapshotTree extends ModifiableTreeNode<Name, TreeStructuredData?> {
  SparseSnapshotTree() : super(null, SortedMap<Name, SparseSnapshotTree>());

  @override
  Map<Name, SparseSnapshotTree> get children =>
      super.children as Map<Name, SparseSnapshotTree>;

  void remember(Path<Name> path, TreeStructuredData data) {
    if (path.isEmpty) {
      value = data;
      children.clear();
    } else {
      if (value != null) {
        value = value!.updateChild(path, data);
      } else {
        var childKey = path.first;
        children.putIfAbsent(childKey, () => SparseSnapshotTree());
        var child = children[childKey]!;
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
        if (value!.isLeaf) {
          return false;
        } else {
          var oldValue = value!;
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
          var safeToRemove = children[childKey]!.forget(path);
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
