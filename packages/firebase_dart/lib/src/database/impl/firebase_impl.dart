import 'dart:async';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:hive/hive.dart';
import 'package:quiver/core.dart' as quiver;

import '../../database.dart';
import 'repo.dart';
import 'treestructureddata.dart';

mixin BaseFirebaseDatabase implements FirebaseDatabase {
  AuthTokenProvider? get authTokenProvider;

  @override
  DatabaseReference reference() => ReferenceImpl(this, <String>[]);

  @override
  Future<void> goOnline() async {
    var repo = Repo(this);
    repo.resume();
  }

  @override
  Future<void> goOffline() async {
    var repo = Repo(this);
    repo.interrupt();
  }

  @override
  Future<void> purgeOutstandingWrites() async {
    var repo = Repo(this);
    repo.purgeOutstandingWrites();
  }

  bool _persistenceManagerInitialized = false;

  String get _persistenceStorageName =>
      'firebase-db-persistence-storage-${Uri.parse(databaseURL).host}';

  late final PersistenceManager persistenceManager =
      DelegatingPersistenceManager(() {
    _persistenceManagerInitialized = true;
    return _persistenceEnabled
        ? DefaultPersistenceManager(
            HivePersistenceStorageEngine(
                KeyValueDatabase(Hive.box(_persistenceStorageName))),
            LRUCachePolicy(_persistenceCacheSize))
        : NoopPersistenceManager();
  });

  int _persistenceCacheSize = 10 * 1024 * 1024;

  bool _persistenceEnabled = false;

  @override
  Future<bool> setPersistenceEnabled(bool enabled) async {
    if (_persistenceManagerInitialized) return false;
    if (_persistenceEnabled == enabled) return true;
    if (enabled) {
      await PersistenceStorage.openBox(_persistenceStorageName);
      if (_persistenceManagerInitialized) {
        await Hive.box(_persistenceStorageName).close();
        return false;
      }
    } else if (Hive.isBoxOpen(_persistenceStorageName)) {
      await Hive.box(_persistenceStorageName).close();
    }
    _persistenceEnabled = enabled;
    return true;
  }

  static String normalizeUrl(String? url) {
    if (url == null) {
      throw ArgumentError.notNull('databaseURL');
    }
    var uri = Uri.parse(url);

    if (!['http', 'https', 'mem'].contains(uri.scheme)) {
      throw ArgumentError.value(
          url, 'databaseURL', 'Only http, https or mem scheme allowed');
    }
    if (uri.pathSegments.isNotEmpty) {
      throw ArgumentError.value(url, 'databaseURL', 'Paths are not allowed');
    }
    return Uri.parse(url).replace(path: '').toString();
  }

  Future<void> _doDelete() async {
    if (Repo.hasInstance(this)) {
      await Repo(this).close();
    }
    if (Hive.isBoxOpen(_persistenceStorageName)) {
      await Hive.box(_persistenceStorageName).close();
    }
  }

  @override
  Future<bool> setPersistenceCacheSizeBytes(int cacheSizeInBytes) async {
    if (_persistenceManagerInitialized) return false;
    _persistenceCacheSize = cacheSizeInBytes;
    return true;
  }
}

class FirebaseDatabaseImpl extends FirebaseService
    with BaseFirebaseDatabase
    implements FirebaseDatabase {
  @override
  final String databaseURL;

  FirebaseDatabaseImpl({required FirebaseApp app, String? databaseURL})
      : databaseURL = BaseFirebaseDatabase.normalizeUrl(
            databaseURL ?? app.options.databaseURL),
        super(app);

  @override
  Future<void> delete() async {
    await _doDelete();
    return super.delete();
  }

  @override
  late final int hashCode = quiver.hash2(databaseURL, app);

  @override
  bool operator ==(Object other) =>
      other is FirebaseDatabase &&
      other.app == app &&
      other.databaseURL == databaseURL;

  @override
  AuthTokenProvider get authTokenProvider =>
      AuthTokenProvider.fromFirebaseAuth(FirebaseAuth.instanceFor(app: app));
}

abstract class StandaloneFirebaseDatabase implements FirebaseDatabase {
  factory StandaloneFirebaseDatabase(String databaseURL,
          {AuthTokenProvider? authTokenProvider}) =>
      StandaloneFirebaseDatabaseImpl(databaseURL,
          authTokenProvider: authTokenProvider);

  Future<void> delete();

  Future<void> authenticate(FutureOr<String> token);

  Future<void> unauthenticate();

  Stream<Map<String, dynamic>?> get onAuthChanged;

  Map<String, dynamic>? get currentAuth;
}

class StandaloneFirebaseDatabaseImpl
    with BaseFirebaseDatabase
    implements StandaloneFirebaseDatabase {
  @override
  final AuthTokenProvider? authTokenProvider;

  @override
  FirebaseApp get app => throw UnsupportedError(
      'A stand-alone database does not have an associated app');

  @override
  final String databaseURL;

  StandaloneFirebaseDatabaseImpl(String databaseURL, {this.authTokenProvider})
      : databaseURL = BaseFirebaseDatabase.normalizeUrl(databaseURL);

  @override
  Future<void> delete() async {
    await _doDelete();
  }

  @override
  Future<void> authenticate(FutureOr<String> token) async {
    await Repo(this).auth(token);
  }

  @override
  Future<void> unauthenticate() async {
    await Repo(this).unauth();
  }

  @override
  Stream<Map<String, dynamic>?> get onAuthChanged => Repo(this).onAuth;

  @override
  Map<String, dynamic>? get currentAuth => Repo(this).authData;
}

class DataSnapshotImpl extends DataSnapshot {
  @override
  final String? key;

  final TreeStructuredData treeStructuredData;

  DataSnapshotImpl(DatabaseReference ref, this.treeStructuredData)
      : key = ref.key;

  @override
  dynamic get value => treeStructuredData.toJson();
}

class QueryImpl extends Query {
  final List<String> _pathSegments;
  final String _path;
  final BaseFirebaseDatabase db;
  final QueryFilter filter;
  final Repo _repo;

  QueryImpl._(this.db, this._pathSegments, this.filter)
      : _path = _pathSegments.map(Uri.encodeComponent).join('/'),
        _repo = Repo(db);

  @override
  Stream<Event> on(String eventType) =>
      _repo.createStream(reference(), filter, eventType);

  Query _withFilter(QueryFilter filter) =>
      QueryImpl._(db, _pathSegments, filter);

  @override
  Query orderByChild(String child) {
    if (child.startsWith(r'$')) {
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

  Name _parseKey(String? key, String allowedSpecialName) {
    if (key == '[MIN_NAME]' && key == allowedSpecialName) return Name.min;
    if (key == '[MAX_NAME]' && key == allowedSpecialName) return Name.max;
    if (key == null) {
      throw ArgumentError(
          'When ordering by key, the argument passed to startAt(), endAt(),or equalTo() must be a non null string.');
    }
    if (key.contains(RegExp(r'\.\#\$\/\[\]'))) {
      throw ArgumentError(
          'Second argument was an invalid key = "[MIN_VALUE]".  Firebase keys must be non-empty strings and can\'t contain ".", "#", "\$", "/", "[", or "]").');
    }
    return Name(key);
  }

  @override
  Query equalTo(dynamic value, {String? key = '[ANY_NAME]'}) {
    if (filter.orderBy == '.key' || key == '[ANY_NAME]') {
      return endAt(value).startAt(value);
    }
    return endAt(value, key: key).startAt(value, key: key);
  }

  @override
  Query startAt(dynamic value, {String? key = '[MIN_NAME]'}) {
    key ??= '[MIN_NAME]';
    if (filter.orderBy == '.key') {
      if (key != '[MIN_NAME]') {
        throw ArgumentError(
            'When ordering by key, you may only pass one argument to startAt(), endAt(), or equalTo().');
      }
      key = value is String ? value : null;
      value = null;
    }
    return _withFilter(filter.copyWith(
        startAtKey: _parseKey(key, '[MIN_NAME]'),
        startAtValue: TreeStructuredData.fromJson(value)));
  }

  @override
  Query endAt(dynamic value, {String? key = '[MAX_NAME]'}) {
    key ??= '[MAX_NAME]';
    if (filter.orderBy == '.key') {
      if (key != '[MAX_NAME]') {
        throw ArgumentError(
            'When ordering by key, you may only pass one argument to startAt(), endAt(), or equalTo().');
      }
      key = value is String ? value : null;
      value = null;
    }
    return _withFilter(filter.copyWith(
        endAtKey: _parseKey(key, '[MAX_NAME]'),
        endAtValue: TreeStructuredData.fromJson(value)));
  }

  @override
  Query limitToFirst(int limit) =>
      _withFilter(filter.copyWith(limit: limit, reverse: false));

  @override
  Query limitToLast(int limit) =>
      _withFilter(filter.copyWith(limit: limit, reverse: true));

  @override
  DatabaseReference reference() => ReferenceImpl(db, _pathSegments);

  @override
  Future<void> keepSynced(bool value) async {
    // TODO: implement keepSynced: do nothing for now
  }
}

class ReferenceImpl extends QueryImpl with DatabaseReference {
  late OnDisconnect _onDisconnect;

  ReferenceImpl(BaseFirebaseDatabase db, List<String> path)
      : super._(db, path, const QueryFilter()) {
    _onDisconnect = DisconnectImpl(this);
  }

  @override
  OnDisconnect onDisconnect() => _onDisconnect;

  @override
  late final Uri url = _repo.url.replace(path: _path);

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
      db, [..._pathSegments, ...c.split('/').map(Uri.decodeComponent)]);

  @override
  DatabaseReference? parent() => _pathSegments.isEmpty
      ? null
      : ReferenceImpl(
          db, [..._pathSegments.sublist(0, _pathSegments.length - 1)]);

  @override
  DatabaseReference root() => ReferenceImpl(db, []);

  @override
  String get path => '/$_path';

  @override
  String? get key => _pathSegments.isEmpty ? null : _pathSegments.last;
}

class DisconnectImpl extends OnDisconnect {
  final ReferenceImpl _ref;

  DisconnectImpl(this._ref);

  @override
  Future set(dynamic value, {dynamic priority}) =>
      _ref._repo.onDisconnectSetWithPriority(_ref._path, value, priority);

  @override
  Future update(Map<String, dynamic> value) =>
      _ref._repo.onDisconnectUpdate(_ref._path, value);

  @override
  Future cancel() => _ref._repo.onDisconnectCancel(_ref._path);
}

class TransactionResultImpl implements TransactionResult {
  @override
  final FirebaseDatabaseException? error;
  @override
  final bool committed;
  @override
  final DataSnapshot? dataSnapshot;

  const TransactionResultImpl(
      {this.error, required this.committed, this.dataSnapshot});

  const TransactionResultImpl.success(DataSnapshot snapshot)
      : this(dataSnapshot: snapshot, committed: true);

  const TransactionResultImpl.error(FirebaseDatabaseException error)
      : this(error: error, committed: false);
  const TransactionResultImpl.abort() : this(committed: false);
}
