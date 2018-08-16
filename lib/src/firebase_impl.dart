import 'firebase.dart';
import 'treestructureddata.dart';
import 'repo.dart';
import 'dart:async';

class DataSnapshotImpl extends DataSnapshot {
  final TreeStructuredData treeStructuredData;

  DataSnapshotImpl(Firebase ref, this.treeStructuredData) : super(ref);

  @override
  dynamic get val => treeStructuredData?.toJson();

  @override
  bool get exists => treeStructuredData != null && !treeStructuredData.isNil;

  @override
  DataSnapshot child(String c) => new DataSnapshotImpl(
      ref.child(c), treeStructuredData?.subtree(Name.parsePath(c)));

  @override
  void forEach(cb(DataSnapshot snapshot)) =>
      treeStructuredData.children.forEach((key, value) =>
          cb(new DataSnapshotImpl(ref.child(key.toString()), value)));

  @override
  bool hasChild(String path) =>
      treeStructuredData.hasChild(Name.parsePath(path));

  @override
  bool get hasChildren => treeStructuredData.children.isNotEmpty;

  @override
  int get numChildren => treeStructuredData.children.length;

  @override
  dynamic get priority => treeStructuredData.priority.toJson();

  @override
  dynamic exportVal() => treeStructuredData.toJson(true);
}

class QueryImpl extends Query {
  final List<String> _pathSegments;
  final String _path;
  final FirebaseDatabase _db;
  final QueryFilter filter;
  final Repo _repo;

  QueryImpl._(this._db, this._pathSegments, this.filter)
      : _path = _pathSegments.map(Uri.encodeComponent).join("/"),
        _repo = new Repo(_db);

  @override
  Stream<Event> on(String eventType) =>
      _repo.createStream(ref, filter, eventType);

  Query _withFilter(QueryFilter filter) =>
      new QueryImpl._(_db, _pathSegments, filter);

  @override
  Query orderByChild(String child) {
    if (child == null || child.startsWith(r"$"))
      throw new ArgumentError("'$child' is not a valid child");

    return _withFilter(filter.copyWith(orderBy: child));
  }

  @override
  Query orderByKey() => _withFilter(filter.copyWith(orderBy: r".key"));

  @override
  Query orderByValue() => _withFilter(filter.copyWith(orderBy: r".value"));

  @override
  Query orderByPriority() =>
      _withFilter(filter.copyWith(orderBy: r".priority"));

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
  Firebase get ref => new FirebaseImpl(_db, _pathSegments);
}

class FirebaseImpl extends QueryImpl with Firebase {
  Disconnect _onDisconnect;

  FirebaseImpl(FirebaseDatabase db, List<String> path)
      : super._(db, path, const QueryFilter()) {
    _onDisconnect = new DisconnectImpl(this);
  }

  @override
  Disconnect get onDisconnect => _onDisconnect;

  @override
  Future<Map> authWithCustomToken(String token) => _repo.auth(token);

  @override
  dynamic get auth => _repo.authData;

  @override
  Stream<Map> get onAuth => _repo.onAuth;

  @override
  Future unauth() => _repo.unauth();

  @override
  Uri get url => _repo.url.replace(path: _path);

  @override
  Future set(dynamic value) => _repo.setWithPriority(_path, value, null);

  @override
  Future update(Map<String, dynamic> value) => _repo.update(_path, value);

  @override
  Future<Firebase> push(dynamic value) =>
      _repo.push(_path, value).then<Firebase>((n) => child(n));

  @override
  Future<Null> setWithPriority(dynamic value, dynamic priority) =>
      _repo.setWithPriority(_path, value, priority);

  @override
  Future setPriority(dynamic priority) =>
      _repo.setWithPriority("$_path/.priority", priority, null);

  @override
  Future<DataSnapshot> transaction(dynamic update(dynamic currentVal),
          {bool applyLocally: true}) =>
      _repo
          .transaction(_path, update, applyLocally)
          .then<DataSnapshot>((v) => new DataSnapshotImpl(this, v));

  @override
  Firebase child(String c) => new FirebaseImpl(_db,
      []..addAll(_pathSegments)..addAll(c.split("/").map(Uri.decodeComponent)));

  @override
  Firebase get parent => _pathSegments.isEmpty
      ? null
      : new FirebaseImpl(
          _db, []..addAll(_pathSegments.sublist(0, _pathSegments.length - 1)));

  @override
  Firebase get root => new FirebaseImpl(_db, []);
}

class DisconnectImpl extends Disconnect {
  final FirebaseImpl _ref;

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
