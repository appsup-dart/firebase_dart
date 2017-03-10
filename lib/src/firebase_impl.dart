
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
  DataSnapshot child(String c) =>
      new DataSnapshotImpl(ref.child(c), treeStructuredData?.subtree(Name.parsePath(c)));


  @override
  void forEach(cb(DataSnapshot snapshot)) => treeStructuredData.children.forEach(
          (key, value) => cb(new DataSnapshotImpl(ref.child(key.toString()), value)));

  @override
  bool hasChild(String path) => treeStructuredData.hasChild(Name.parsePath(path));

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
  final Uri _url;
  final QueryFilter filter;
  final Repo _repo;

  QueryImpl(Uri url, [QueryFilter filter = const QueryFilter()]) : this._(url,filter);

  QueryImpl._(this._url, this.filter) : _repo = new Repo(_url.resolve("/"));

  @override
  Stream<Event> on(String eventType) =>
      _repo.createStream(ref, filter, eventType);

  Query _withFilter(QueryFilter filter) => new QueryImpl(_url, filter);


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
  Firebase get ref => new Firebase(_url.toString());

}

class FirebaseImpl extends QueryImpl with Firebase {
  Disconnect _onDisconnect;

  FirebaseImpl(String url)
      : super._(url.endsWith("/")
      ? Uri.parse(url.substring(0, url.length - 1))
      : Uri.parse(url), const QueryFilter()) {
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
  Uri get url => _url;

  @override
  Future set(dynamic value) => _repo.setWithPriority(_url.path, value, null);

  @override
  Future update(Map<String, dynamic> value) => _repo.update(_url.path, value);

  @override
  Future<Firebase> push(dynamic value) =>
      _repo.push(_url.path, value).then<Firebase>((n) => child(n));

  @override
  Future<Null> setWithPriority(dynamic value, dynamic priority) =>
      _repo.setWithPriority(_url.path, value, priority);

  @override
  Future setPriority(dynamic priority) =>
      _repo.setWithPriority(childUri(_url, ".priority").path, priority, null);

  @override
  Future<DataSnapshot> transaction(dynamic update(dynamic currentVal),
      {bool applyLocally: true}) =>
      _repo
          .transaction(_url.path, update, applyLocally)
          .then<DataSnapshot>((v) => new DataSnapshotImpl(this, v));

}


class DisconnectImpl extends Disconnect {
  final FirebaseImpl _ref;

  DisconnectImpl(this._ref);

  @override
  Future setWithPriority(dynamic value, dynamic priority) =>
      _ref._repo.onDisconnectSetWithPriority(_ref._url.path, value, priority);

  @override
  Future update(Map<String, dynamic> value) =>
      _ref._repo.onDisconnectUpdate(_ref._url.path, value);

  @override
  Future cancel() => _ref._repo.onDisconnectCancel(_ref._url.path);


}

Uri childUri(Uri url, String c) => url.replace(pathSegments:
new List.from(url.pathSegments)..addAll(c.split("/").map(Uri.decodeComponent)));
