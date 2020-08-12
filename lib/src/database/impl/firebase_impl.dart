import '../../database.dart';
import 'treestructureddata.dart';
import 'repo.dart';
import 'dart:async';

class DataSnapshotImpl extends DataSnapshot {
  @override
  final String key;

  final TreeStructuredData treeStructuredData;

  DataSnapshotImpl(DatabaseReference ref, this.treeStructuredData)
      : key = ref.key;

  @override
  dynamic get value => treeStructuredData?.toJson();
}

extension QueryExtensionForTesting on Query {
  FirebaseDatabase get database => (this as QueryImpl)._db;
}

class QueryImpl extends Query {
  final List<String> _pathSegments;
  final String _path;
  final FirebaseDatabase _db;
  final QueryFilter filter;
  final Repo _repo;

  QueryImpl._(this._db, this._pathSegments, this.filter)
      : _path = _pathSegments.map(Uri.encodeComponent).join('/'),
        _repo = Repo(_db);

  @override
  Stream<Event> on(String eventType) =>
      _repo.createStream(reference(), filter, eventType);

  Query _withFilter(QueryFilter filter) =>
      QueryImpl._(_db, _pathSegments, filter);

  @override
  Query orderByChild(String child) {
    if (child == null || child.startsWith(r'$')) {
      throw ArgumentError("'$child' is not a valid child");
    }

    return _withFilter(filter.copyWith(orderBy: child));
  }

  @override
  Query orderByKey() => _withFilter(filter.copyWith(orderBy: r'.key'));

  @override
  Query orderByValue() => _withFilter(filter.copyWith(orderBy: r'.value'));

  @override
  Query orderByPriority() =>
      _withFilter(filter.copyWith(orderBy: r'.priority'));

  @override
  Query startAt(dynamic value, [String key]) =>
      _withFilter(filter.copyWith(startAtKey: key, startAtValue: value));

  @override
  Query endAt(dynamic value, [String key]) =>
      _withFilter(filter.copyWith(endAtKey: key, endAtValue: value));

  @override
  Query limitToFirst(int limit) =>
      _withFilter(filter.copyWith(limit: limit, reverse: false));

  @override
  Query limitToLast(int limit) =>
      _withFilter(filter.copyWith(limit: limit, reverse: true));

  @override
  DatabaseReference reference() => ReferenceImpl(_db, _pathSegments);
}

class ReferenceImpl extends QueryImpl with DatabaseReference {
  Disconnect _onDisconnect;

  ReferenceImpl(FirebaseDatabase db, List<String> path)
      : super._(db, path, const QueryFilter()) {
    _onDisconnect = DisconnectImpl(this);
  }

  @override
  Disconnect get onDisconnect => _onDisconnect;

  @override
  Uri get url => _repo.url.replace(path: _path);

  @override
  Future<void> set(dynamic value, {dynamic priority}) =>
      _repo.setWithPriority(_path, value, priority);

  @override
  Future<void> update(Map<String, dynamic> value) => _repo.update(_path, value);

  @override
  DatabaseReference push() => child(_repo.generateId());

  @override
  Future<void> setPriority(dynamic priority) =>
      _repo.setWithPriority('$_path/.priority', priority, null);

  @override
  Future<TransactionResult> runTransaction(
      TransactionHandler transactionHandler,
      {Duration timeout = const Duration(seconds: 5),
      bool fireLocalEvents = true}) async {
    try {
      var v =
          await _repo.transaction(_path, transactionHandler, fireLocalEvents);
      if (v == null) {
        return TransactionResultImpl.abort();
      }
      var s = DataSnapshotImpl(this, v);
      return TransactionResultImpl.success(s);
    } on FirebaseDatabaseException catch (e) {
      return TransactionResultImpl.error(e);
    }
  }

  @override
  DatabaseReference child(String c) => ReferenceImpl(
      _db, [..._pathSegments, ...c.split('/').map(Uri.decodeComponent)]);

  @override
  DatabaseReference parent() => _pathSegments.isEmpty
      ? null
      : ReferenceImpl(
          _db, [..._pathSegments.sublist(0, _pathSegments.length - 1)]);

  @override
  DatabaseReference root() => ReferenceImpl(_db, []);
}

extension LegacyAuthExtension on DatabaseReference {
  Repo get repo => (this as ReferenceImpl)._repo;

  Future<void> authWithCustomToken(String token) => authenticate(token);

  dynamic get auth => repo.authData;

  Stream<Map> get onAuth => repo.onAuth;

  Future unauth() => repo.unauth();

  Future<void> authenticate(String token) => repo.auth(token);
}

class DisconnectImpl extends Disconnect {
  final ReferenceImpl _ref;

  DisconnectImpl(this._ref);

  @override
  Future setWithPriority(dynamic value, dynamic priority) =>
      _ref._repo.onDisconnectSetWithPriority(_ref._path, value, priority);

  @override
  Future update(Map<String, dynamic> value) =>
      _ref._repo.onDisconnectUpdate(_ref._path, value);

  @override
  Future cancel() => _ref._repo.onDisconnectCancel(_ref._path);
}

class TransactionResultImpl implements TransactionResult {
  @override
  final FirebaseDatabaseException error;
  @override
  final bool committed;
  @override
  final DataSnapshot dataSnapshot;

  const TransactionResultImpl({this.error, this.committed, this.dataSnapshot});

  const TransactionResultImpl.success(DataSnapshot snapshot)
      : this(dataSnapshot: snapshot, committed: true);

  const TransactionResultImpl.error(FirebaseDatabaseException error)
      : this(error: error, committed: false);
  const TransactionResultImpl.abort() : this(committed: false);
}
