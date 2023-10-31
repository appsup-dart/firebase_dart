import 'dart:convert';

import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/persistence/prune_forest.dart';
import 'package:firebase_dart/src/database/impl/persistence/tracked_query.dart';
import 'package:hive/hive.dart';
import 'package:synchronized/extension.dart';

import '../data_observer.dart';
import '../tree.dart';
import '../utils.dart';
import '../treestructureddata.dart';
import 'engine.dart';

class PersistenceStorageTransaction {
  final Map<int, TrackedQuery?> _trackedQueries = {};
  final Map<int, TreeOperation?> _userOperations = {};
  IncompleteData? _serverCache;

  PersistenceStorageTransaction();

  bool get isEmpty =>
      _trackedQueries.isEmpty &&
      _userOperations.isEmpty &&
      _serverCache == null;

  void deleteTrackedQuery(int trackedQueryId) {
    _trackedQueries[trackedQueryId] = null;
  }

  void saveTrackedQuery(TrackedQuery trackedQuery) {
    _trackedQueries[trackedQuery.id] = trackedQuery;
  }

  void deleteUserOperation(int writeId) {
    _userOperations[writeId] = null;
  }

  void saveUserOperation(TreeOperation operation, int writeId) {
    _userOperations[writeId] = operation;
  }

  void saveServerCache(IncompleteData value) {
    _serverCache = value;
  }

  void addTransaction(PersistenceStorageTransaction transaction) {
    _trackedQueries.addAll(transaction._trackedQueries);
    _userOperations.addAll(transaction._userOperations);
    _serverCache = transaction._serverCache ?? _serverCache;
  }
}

abstract class PersistenceStorageDatabase {
  IncompleteData loadServerCache();

  List<TrackedQuery> loadTrackedQueries();

  Map<int, TreeOperation> loadUserOperations();

  Future<void> applyTransaction(PersistenceStorageTransaction transaction);

  Future<void> close();

  bool get isOpen;
}

class PersistenceStorageDatabaseImpl extends PersistenceStorageDatabase {
  static const _serverCachePrefix = 'C';
  static const _trackedQueryPrefix = 'Q';
  static const _userWritesPrefix = 'W';

  final KeyValueDatabase database;

  late IncompleteData _lastWrittenServerCache = _loadServerCache();

  PersistenceStorageDatabaseImpl(this.database);

  @override
  IncompleteData loadServerCache() {
    assert(isOpen);
    return _lastWrittenServerCache;
  }

  IncompleteData _loadServerCache() {
    var keys = database.keysBetween(
      startKey: '$_serverCachePrefix:',
      endKey: '$_serverCachePrefix;',
    );

    return IncompleteData.fromLeafs({
      for (var k in keys)
        Name.parsePath(k.substring('$_serverCachePrefix:'.length)):
            TreeStructuredData.fromExportJson(database.box.get(k))
    });
  }

  @override
  List<TrackedQuery> loadTrackedQueries() {
    assert(isOpen);
    return [
      ...database
          .valuesBetween(
              startKey: '$_trackedQueryPrefix:',
              endKey: '$_trackedQueryPrefix;')
          .map((v) => TrackedQuery.fromJson(v))
    ]..sort((a, b) => Comparable.compare(a.id, b.id));
  }

  @override
  Map<int, TreeOperation> loadUserOperations() {
    assert(isOpen);
    return {
      for (var k in database.keysBetween(
          startKey: '$_userWritesPrefix:', endKey: '$_userWritesPrefix;'))
        int.parse(k.substring('$_userWritesPrefix:'.length)):
            TreeOperationX.fromJson(database.box.get(k))
    };
  }

  @override
  Future<void> applyTransaction(
      PersistenceStorageTransaction transaction) async {
    assert(isOpen);
    database.beginTransaction();

    for (var e in transaction._trackedQueries.entries) {
      var trackedQueryId = e.key;
      var trackedQuery = e.value;
      if (trackedQuery == null) {
        database.delete('$_trackedQueryPrefix:$trackedQueryId');
      } else {
        database.put(
            '$_trackedQueryPrefix:${trackedQuery.id}', trackedQuery.toJson());
      }
    }

    for (var e in transaction._userOperations.entries) {
      var writeId = e.key;
      var operation = e.value;
      if (operation == null) {
        database.delete('$_userWritesPrefix:$writeId');
      } else {
        database.put('$_userWritesPrefix:$writeId', operation.toJson());
      }
    }

    var serverCache = transaction._serverCache;

    if (serverCache != null) {
      void write(Path<Name> path, TreeNode<Name, TreeStructuredData?> value,
          TreeNode<Name, TreeStructuredData?> lastWritten) {
        if (value.value != null && lastWritten.value == value.value) return;

        if (value.value != null || lastWritten.value != null) {
          var p = path.join('/');
          database.deleteAll(database.keysBetween(
            startKey: '$_serverCachePrefix:$p/',
            endKey: '$_serverCachePrefix:${p}0',
          ));
        }

        if (value.value != null) {
          var p = path.join('/');
          var v = value.value!;
          // we will read back the data as if it were ordered/filtered with default, so we should also write it like that
          assert(v.filter == const QueryFilter());

          database.put('$_serverCachePrefix:$p/', v.toJson(true));
        } else {
          var allChildren = [
            ...lastWritten.children.keys,
            ...value.children.keys
          ];

          for (var k in allChildren) {
            write(path.child(k), value.children[k] ?? const LeafTreeNode(null),
                lastWritten.children[k] ?? const LeafTreeNode(null));
          }
        }
      }

      write(Path(), serverCache.writeTree, _lastWrittenServerCache.writeTree);

      _lastWrittenServerCache = serverCache;
    }

    await database.endTransaction();
  }

  @override
  Future<void> close() {
    assert(isOpen);
    return database.close();
  }

  @override
  bool get isOpen => database.box.isOpen;
}

class DebouncedPersistenceStorageDatabase
    implements PersistenceStorageDatabase {
  final PersistenceStorageDatabase delegateTo;

  PersistenceStorageTransaction _transaction = PersistenceStorageTransaction();

  DelayedCancellableFuture<void>? _writeToDatabaseFuture;

  DebouncedPersistenceStorageDatabase(this.delegateTo);

  @override
  Future<void> applyTransaction(
      PersistenceStorageTransaction transaction) async {
    assert(isOpen);
    _transaction.addTransaction(transaction);
    _scheduleWriteToDatabase();
  }

  @override
  Future<void> close() async {
    assert(isOpen);
    _writeToDatabaseFuture?.cancel();
    await _writeToDatabase();
    await delegateTo.close();
  }

  @override
  IncompleteData loadServerCache() {
    assert(isOpen);
    return _transaction._serverCache ?? delegateTo.loadServerCache();
  }

  @override
  List<TrackedQuery> loadTrackedQueries() {
    assert(isOpen);
    return [
      ...delegateTo
          .loadTrackedQueries()
          .where((v) => !_transaction._trackedQueries.containsKey(v.id)),
      ..._transaction._trackedQueries.values.whereType()
    ];
  }

  @override
  Map<int, TreeOperation> loadUserOperations() {
    assert(isOpen);
    return ({
      ...delegateTo.loadUserOperations(),
      ..._transaction._userOperations,
    }..removeWhere((key, value) => value == null))
        .cast();
  }

  void _scheduleWriteToDatabase() {
    _writeToDatabaseFuture ??=
        DelayedCancellableFuture(const Duration(milliseconds: 500), () {
      if (_writeToDatabaseFuture == null) return;
      synchronized(_writeToDatabase);
    });
  }

  Future<void> _writeToDatabase() async {
    assert(isOpen);
    _writeToDatabaseFuture = null;

    if (_transaction.isEmpty) return;

    await delegateTo.applyTransaction(_transaction);
    _transaction = PersistenceStorageTransaction();
  }

  @override
  bool get isOpen => delegateTo.isOpen;
}

class HivePersistenceStorageEngine extends PersistenceStorageEngine {
  final PersistenceStorageDatabase database;

  PersistenceStorageTransaction? _transaction;

  HivePersistenceStorageEngine(KeyValueDatabase database)
      : database = DebouncedPersistenceStorageDatabase(
            PersistenceStorageDatabaseImpl(database));

  @override
  void beginTransaction() {
    assert(_transaction == null);
    _transaction = PersistenceStorageTransaction();
  }

  @override
  void deleteTrackedQuery(int trackedQueryId) {
    assert(_transaction != null);
    _transaction!.deleteTrackedQuery(trackedQueryId);
  }

  @override
  void endTransaction() {
    assert(_transaction != null);
    database.applyTransaction(_transaction!);
    _transaction = null;
  }

  @override
  List<TrackedQuery> loadTrackedQueries() {
    return database.loadTrackedQueries();
  }

  @override
  Map<int, TreeOperation> loadUserOperations() {
    return database.loadUserOperations();
  }

  @override
  void overwriteServerCache(TreeOperation operation) {
    _saveServerCache(database.loadServerCache().applyOperation(operation));
  }

  void _saveServerCache(IncompleteData serverCache) {
    assert(_transaction != null);
    _transaction!.saveServerCache(serverCache);
  }

  @override
  void pruneCache(PruneForest pruneForest) {
    assert(_transaction != null);
    if (!pruneForest.prunesAnything()) {
      return;
    }

    var serverCache = database.loadServerCache();

    serverCache.forEachCompleteNode((dataPath, value) {
      final dataNode = value;

      if (pruneForest.shouldPruneUnkeptDescendants(dataPath)) {
        var newCache = pruneForest
            .child(dataPath)
            .foldKeptNodes<IncompleteData>(IncompleteData.empty(),
                (keepPath, value, accum) {
          var value = dataNode.getChild(keepPath);
          if (!value.isNil) {
            var op = TreeOperation.overwrite(
                Path.from([...dataPath, ...keepPath]),
                dataNode.getChild(keepPath));
            accum = accum.applyOperation(op);
          }
          return accum;
        });
        serverCache = serverCache
            .removeWrite(dataPath)
            .applyOperation(newCache.toOperation());
      }
    });

    _saveServerCache(serverCache);
  }

  @override
  void removeUserOperation(int writeId) {
    assert(_transaction != null);
    _transaction!.deleteUserOperation(writeId);
  }

  @override
  void resetPreviouslyActiveTrackedQueries(DateTime lastUse) {
    for (var query in loadTrackedQueries()) {
      if (query.active) {
        query = query.setActiveState(false).updateLastUse(lastUse);
        saveTrackedQuery(query);
      }
    }
  }

  @override
  void saveTrackedQuery(TrackedQuery trackedQuery) {
    assert(_transaction != null);
    _transaction!.saveTrackedQuery(trackedQuery);
  }

  @override
  void saveUserOperation(TreeOperation operation, int writeId) {
    assert(_transaction != null);
    _transaction!.saveUserOperation(operation, writeId);
  }

  @override
  IncompleteData serverCache(Path<Name> path) {
    return database.loadServerCache().child(path);
  }

  @override
  int serverCacheEstimatedSizeInBytes() {
    return _transaction?._serverCache?.estimatedStorageSize ??
        database.loadServerCache().estimatedStorageSize;
  }

  @override
  void setTransactionSuccessful() {}

  @override
  Future<void> close() async {
    await database.close();
  }
}

class KeyValueDatabase {
  final Box box;

  Map<String, dynamic>? _transaction;

  KeyValueDatabase(this.box);

  bool get isInsideTransaction => _transaction != null;

  Iterable<dynamic> valuesBetween(
      {required String startKey, required String endKey}) {
    assert(box.isOpen);
    // TODO merge transaction data
    return keysBetween(startKey: startKey, endKey: endKey)
        .map((k) => box.get(k));
  }

  Iterable<String> keysBetween(
      {required String startKey, required String endKey}) sync* {
    assert(box.isOpen);
    // TODO merge transaction data
    for (var k in box.keys) {
      if (box.get(k) == null) return;
      if (Comparable.compare(k, startKey) < 0) continue;
      if (Comparable.compare(k, endKey) > 0) return;
      yield k as String;
    }
  }

  bool containsKey(String key) {
    assert(box.isOpen);
    return box.containsKey(key);
  }

  void beginTransaction() {
    assert(box.isOpen);
    assert(!isInsideTransaction,
        'runInTransaction called when an existing transaction is already in progress.');
    _transaction = {};
  }

  Future<void> endTransaction() async {
    assert(box.isOpen);
    assert(isInsideTransaction);
    var v = _transaction!;
    _transaction = null;

    _transactionFuture = Future.wait([
      if (_transactionFuture != null) _transactionFuture!,
      box.putAll(v),
      box.deleteAll(v.keys.where((k) => v[k] == null))
    ]);

    await _transactionFuture;
  }

  Future<void>? _transactionFuture;

  Future<void> close() async {
    assert(box.isOpen);
    await _transactionFuture;
    await box.close();
  }

  void delete(String key) {
    _verifyInsideTransaction();
    _transaction![key] = null;
  }

  void deleteAll(Iterable<String> keys) {
    _verifyInsideTransaction();
    for (var k in keys) {
      _transaction![k] = null;
    }
  }

  void put(String key, dynamic value) {
    _verifyInsideTransaction();
    _transaction![key] = value;
  }

  void _verifyInsideTransaction() {
    assert(box.isOpen);
    assert(
        isInsideTransaction, 'Transaction expected to already be in progress.');
  }
}

extension IncompleteDataX on IncompleteData {
  int get estimatedStorageSize {
    var bytes = 0;
    forEachCompleteNode((k, v) {
      bytes +=
          k.join('/').length + json.encode(v.toJson(true)).toString().length;
    });
    return bytes;
  }
}

extension TreeOperationX on TreeOperation {
  static TreeOperation fromJson(Map<String, dynamic> json) {
    if (json.containsKey('s')) {
      return TreeOperation.overwrite(
          Name.parsePath(json['p']), TreeStructuredData.fromJson(json['s']));
    }
    var v = json['m'] as Map;
    return TreeOperation.merge(Name.parsePath(json['p']), {
      for (var k in v.keys) Name.parsePath(k): TreeStructuredData.fromJson(v[k])
    });
  }

  Map<String, dynamic> toJson() {
    var o = nodeOperation;
    return {
      'p': path.join('/'),
      if (o is Overwrite) 's': o.value.toJson(true),
      if (o is Merge)
        'm': {
          for (var c in o.overwrites)
            c.path.join('/'): (c.nodeOperation as Overwrite).value.toJson(true)
        }
    };
  }
}
