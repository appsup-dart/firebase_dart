import 'dart:async';

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/core/impl/persistence_key.dart';
import 'package:firebase_dart/src/database/impl/persistence/default_manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/hive_engine.dart';
import 'package:firebase_dart/src/database/impl/persistence/manager.dart';
import 'package:firebase_dart/src/database/impl/persistence/policy.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:hive/hive.dart';

import '../../database.dart';
import 'repo.dart';
import 'tree.dart';
import 'treestructureddata.dart';

mixin BaseFirebaseDatabase implements FirebaseDatabase {
  AuthTokenProvider? get authTokenProvider;
  AuthTokenProvider? get appCheckTokenProvider;

  @override
  DatabaseReference reference() => ReferenceImpl(this, Path());

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

  /// App id and name for this database, or null for a stand-alone database.
  String? get persistenceAppStorageKey => null;

  String get _persistenceHost => Uri.parse(databaseURL).host;

  String get _persistenceStorageName => databasePersistenceBoxName(
        host: _persistenceHost,
        appStorageKey: persistenceAppStorageKey,
      );

  static final Map<String, MapEntry<PersistenceManager, int>>
      _persistenceManagers = {};

  late final DelegatingPersistenceManager persistenceManager =
      DelegatingPersistenceManager(() {
    _persistenceManagerInitialized = true;
    if (!_persistenceEnabled) return NoopPersistenceManager();

    var m = _persistenceManagers[_persistenceStorageName] ??= MapEntry(
        DefaultPersistenceManager(
            HivePersistenceStorageEngine(
                KeyValueDatabase(Hive.box(_persistenceStorageName))),
            LRUCachePolicy(_persistenceCacheSize)),
        0);

    _persistenceManagers[_persistenceStorageName] =
        MapEntry(m.key, m.value + 1);

    return m.key;
  });

  int _persistenceCacheSize = 10 * 1024 * 1024;

  bool _persistenceEnabled = false;

  @override
  Future<bool> setPersistenceEnabled(bool enabled) async {
    if (_persistenceManagerInitialized) return false;
    if (_persistenceEnabled == enabled) return true;
    if (enabled) {
      await _openPersistenceBox();
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

  Future<void> _openPersistenceBox() async {
    final name = _persistenceStorageName;
    final legacy = legacyDatabasePersistenceBoxName(_persistenceHost);
    await PersistenceStorage.openBox(name);
    if (name == legacy || Hive.isBoxOpen(legacy)) return;

    final box = Hive.box(name);
    if (box.isNotEmpty || !await _legacyBoxExists(legacy)) return;

    final legacyBox = await PersistenceStorage.openBox(legacy);
    if (legacyBox.isEmpty) {
      await legacyBox.close();
      return;
    }
    await claimLegacyBox(box, legacyBox);
    await legacyBox.close();
    try {
      await Hive.deleteBoxFromDisk(legacy);
    } catch (_) {
      // Memory storage has no file to delete.
    }
  }

  Future<bool> _legacyBoxExists(String name) async {
    try {
      return await Hive.boxExists(name);
    } on ArgumentError {
      // Hive has no directory in memory storage, so there is no legacy file.
      return false;
    }
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
    if (_persistenceManagerInitialized) {
      var m = _persistenceManagers.remove(_persistenceStorageName);
      if (m != null && m.key == persistenceManager.delegateTo) {
        if (m.value > 1) {
          _persistenceManagers[_persistenceStorageName] =
              MapEntry(m.key, m.value - 1);
          return;
        }
      }
      await persistenceManager.close();
      if (Hive.isBoxOpen(_persistenceStorageName)) {
        await Hive.box(_persistenceStorageName).close();
      }
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
  String? get persistenceAppStorageKey => firebaseAppStorageKey(app);

  @override
  Future<void> delete() async {
    await _doDelete();
    return super.delete();
  }

  @override
  late final int hashCode = Object.hash(databaseURL, app);

  @override
  bool operator ==(Object other) =>
      other is FirebaseDatabase &&
      other.app == app &&
      other.databaseURL == databaseURL;

  @override
  AuthTokenProvider get authTokenProvider =>
      AuthTokenProvider.fromFirebaseAuth(FirebaseAuth.instanceFor(app: app));

  @override
  AuthTokenProvider? get appCheckTokenProvider =>
      AuthTokenProvider.fromFirebaseAppCheck(
          FirebaseAppCheck.instanceFor(app: app));
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

  @override
  AuthTokenProvider? get appCheckTokenProvider => null;
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
  final Path<Name> _path;
  final BaseFirebaseDatabase db;
  final QueryFilter filter;
  final Repo _repo;

  QueryImpl._(this.db, this._path, this.filter) : _repo = Repo(db);

  @override
  Stream<Event> on(String eventType) =>
      _repo.createStream(reference(), filter, eventType);

  Query _withFilter(QueryFilter filter) => QueryImpl._(db, _path, filter);

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
  ReferenceImpl reference() => ReferenceImpl(db, _path);

  @override
  Future<void> keepSynced(bool value) async {
    // TODO: implement keepSynced: do nothing for now
  }
}

class ReferenceImpl extends QueryImpl with DatabaseReference {
  late OnDisconnect _onDisconnect;

  ReferenceImpl(BaseFirebaseDatabase db, Path<Name> path)
      : super._(db, path, const QueryFilter()) {
    _onDisconnect = DisconnectImpl(this);
  }

  @override
  OnDisconnect onDisconnect() => _onDisconnect;

  @override
  late final Uri url = _repo.url.replace(path: path);

  @override
  Future<void> set(dynamic value, {dynamic priority}) =>
      _repo.setWithPriority(_path, value, priority);

  @override
  Future<void> update(Map<String, dynamic> value) => _repo.update(_path, value);

  @override
  DatabaseReference push() => child(_repo.generateId());

  @override
  Future<void> setPriority(dynamic priority) =>
      _repo.setWithPriority(_path.child(Name.priorityKey), priority, null);

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
  DatabaseReference child(String c) =>
      ReferenceImpl(db, Path.from([..._path, ...Name.parsePath(c)]));

  @override
  DatabaseReference? parent() =>
      _path.isEmpty ? null : ReferenceImpl(db, _path.parent!);

  @override
  DatabaseReference root() => ReferenceImpl(db, Path());

  @override
  String get path => '/${_path.join('/')}';

  @override
  String? get key => _path.isEmpty ? null : _path.last.toString();

  Path<Name> get parsedPath => _path;
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
