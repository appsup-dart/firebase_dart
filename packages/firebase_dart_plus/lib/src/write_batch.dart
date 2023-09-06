// ignore_for_file: implementation_imports

import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/impl/data_observer.dart';
import 'package:firebase_dart/src/database/impl/view.dart';
import 'package:firebase_dart/src/database/impl/tree.dart';
import 'package:firebase_dart/src/database/impl/operations/tree.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/implementation/isolate/database.dart';

import 'package:sortedmap/sortedmap.dart';
import 'package:firebase_dart/database.dart';

extension FirebaseDatabaseWithWriteBatch on FirebaseDatabase {
  WriteBatch batch() => WriteBatch(this);
}

/// A WriteBatch is a series of write operations to be performed as one unit.
///
/// Operations done on a WriteBatch do not take effect until you commit().
///
/// Once committed, no further operations can be performed on the WriteBatch,
/// nor can it be committed again.
///
/// Operations are added to a WriteBatch through a [DatabaseReference] object
/// that is returned from [WriteBatch.reference]. The [DatabaseReference]
/// object behaves similarly to the [DatabaseReference] instance that is returned
/// from [FirebaseDatabase.reference]. All writes performed on that reference
/// through the [DatabaseReference.set], [DatabaseReference.update], and
/// [DatabaseReference.remove] methods are recorded on the WriteBatch. None of
/// these writes are visible to other clients until [WriteBatch.commit] is
/// called. They are however immediataley visible to all [DatabaseReference] and
/// [Query] objects that are created from [WriteBatch.reference].
///
/// Note that in some cases, queries might not return the results you expect
/// when used with a [WriteBatch]. This can happen when you write to a location
/// that was not part of the query result, but should be after the write. Or the
/// other way around. For example, if you query the first 2 children of a
/// location, but the write batch contains a removal of the first child, the
/// query will only return the second child, even when there are actually more
/// than 2 children at that location. This might be fixed in a future version.
///
///
class WriteBatch {
  final FirebaseDatabase _database;

  final List<TreeOperation> _operations = [];

  bool _committed = false;

  WriteBatch(this._database);

  DatabaseReference reference() =>
      TransactionalDatabaseReference(this, _database.reference());

  Future<void> commit() async {
    if (_committed) throw StateError('Batch already committed');

    _committed = true;
    if (_operations.isEmpty) return;

    var updates = _getUpdates();
    if (updates.isEmpty) return;

    if (updates.length == 1) {
      var e = updates.entries.first;
      await _database.reference().child(e.key).set(e.value);
    } else {
      var p = updates.keys.reduce((value, element) {
        var a = Name.parsePath(value);
        var b = Name.parsePath(element);

        for (var i = 0; i < a.length && i < b.length; i++) {
          if (a[i] != b[i]) {
            return a.take(i).join('/');
          }
        }
        return a.length < b.length ? value : element;
      });
      if (p.isEmpty) {
        await _database.reference().update(updates);
      } else {
        updates = {
          for (var e in updates.entries) e.key.substring(p.length + 1): e.value
        };
        await _database.reference().child(p).update(updates);
      }
    }

    _operations.clear();
  }

  void _addOperation(TreeOperation operation) {
    if (_committed) throw StateError('Batch already committed');
    _operations.add(operation);
  }

  Map<String, dynamic> _getUpdates() {
    var ops = SortedMap<int, TreeOperation>()..addAll(_operations.asMap());
    var cache = ViewCache(IncompleteData.empty(), IncompleteData.empty(), ops)
      ..recalcLocalVersion();

    var updates = <String, dynamic>{};
    cache.localVersion.forEachCompleteNode((k, v) {
      updates[k.join('/')] = v.toJson();
    });
    return updates;
  }
}

class TransactionalQuery extends Query {
  final WriteBatch _transaction;

  final Query _query;

  TransactionalQuery(this._transaction, this._query);

  @override
  Query endAt(value, {String? key}) {
    return TransactionalQuery(_transaction, _query.endAt(value, key: key));
  }

  @override
  Query equalTo(value, {String? key}) {
    return startAt(value, key: key).endAt(value, key: key);
  }

  @override
  Future<void> keepSynced(bool value) async {
    await _query.keepSynced(value);
  }

  @override
  Query limitToFirst(int limit) {
    return TransactionalQuery(_transaction, _query.limitToFirst(limit));
  }

  @override
  Query limitToLast(int limit) {
    return TransactionalQuery(_transaction, _query.limitToLast(limit));
  }

  @override
  Stream<Event> on(String eventType) {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> get() async {
    var ops = SortedMap<int, TreeOperation>()
      ..addAll(_transaction._operations.asMap());
    var cache = ViewCache(IncompleteData.empty(), IncompleteData.empty(), ops)
      ..recalcLocalVersion();

    var path =
        reference().url.path.substring(reference().root().url.path.length);
    var p = Name.parsePath(path);

    if (!cache.localVersion.isCompleteForPath(p)) {
      var v = await _query.get();
      var serverVersion = IncompleteData.empty().applyOperation(
          TreeOperation.overwrite(p, TreeStructuredData.fromJson(v)));
      cache = cache.updateServerVersion(serverVersion);
    }

    var v =
        cache.localVersion.child(p).completeValue!.withFilter(_query.filter);

    return v.toJson();
  }

  @override
  Query orderByChild(String child) {
    return TransactionalQuery(_transaction, _query.orderByChild(child));
  }

  @override
  Query orderByKey() {
    return TransactionalQuery(_transaction, _query.orderByKey());
  }

  @override
  Query orderByPriority() {
    return TransactionalQuery(_transaction, _query.orderByPriority());
  }

  @override
  Query orderByValue() {
    return TransactionalQuery(_transaction, _query.orderByValue());
  }

  @override
  DatabaseReference reference() {
    return TransactionalDatabaseReference(_transaction, _query.reference());
  }

  @override
  Query startAt(value, {String? key}) {
    return TransactionalQuery(_transaction, _query.startAt(value, key: key));
  }
}

class TransactionalDatabaseReference extends TransactionalQuery
    implements DatabaseReference {
  TransactionalDatabaseReference(WriteBatch transaction, DatabaseReference ref)
      : super(transaction, ref);

  @override
  DatabaseReference get _query => super._query as DatabaseReference;

  @override
  DatabaseReference child(String c) {
    return TransactionalDatabaseReference(_transaction, _query.child(c));
  }

  @override
  String? get key => _query.key;

  @override
  OnDisconnect onDisconnect() {
    throw UnimplementedError();
  }

  @override
  DatabaseReference? parent() {
    var p = _query.parent();
    if (p == null) return null;
    return TransactionalDatabaseReference(_transaction, p);
  }

  @override
  String get path => _query.path;

  @override
  DatabaseReference push() =>
      TransactionalDatabaseReference(_transaction, _query.push());

  @override
  Future<void> remove() => set(null);

  @override
  DatabaseReference root() {
    return TransactionalDatabaseReference(_transaction, _query.root());
  }

  @override
  Future<TransactionResult> runTransaction(
      TransactionHandler transactionHandler,
      {Duration timeout = const Duration(seconds: 5)}) {
    // TODO: implement runTransaction
    throw UnimplementedError();
  }

  Path<Name> get _path => Name.parsePath(_query.path);

  @override
  Future<void> set(value, {priority}) async {
    _transaction._addOperation(TreeOperation.overwrite(
        _path, TreeStructuredData.fromJson(value, priority)));
  }

  @override
  Future<void> setPriority(priority) async {
    _transaction._addOperation(TreeOperation.overwrite(
        _path.child(Name.priorityKey), TreeStructuredData.fromJson(priority)));
  }

  @override
  Future<void> update(Map<String, dynamic> value) async {
    _transaction._addOperation(TreeOperation.merge(_path, {
      for (var e in value.entries)
        Name.parsePath(e.key): TreeStructuredData.fromJson(e.value, null)
    }));
  }

  @override
  Uri get url => Uri.parse(_transaction._database.databaseURL)
      .replace(path: _path.join('/'));
}

extension _QueryX on Query {
  QueryFilter get filter {
    if (this is IsolateQuery) {
      return (this as IsolateQuery).filter;
    } else if (this is QueryImpl) {
      return (this as QueryImpl).filter;
    }
    throw UnimplementedError();
  }
}
