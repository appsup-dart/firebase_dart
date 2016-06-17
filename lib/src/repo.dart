// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'protocol.dart';
import 'dart:async';
import 'treestructureddata.dart';
import 'synctree.dart';
import 'firebase.dart' as firebase;
import 'events/value.dart';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:quiver/core.dart' as quiver;
import 'package:sortedmap/sortedmap.dart';
import 'tree.dart';
import 'dart:math';

final _logger = new Logger("firebase-repo");

class QueryFilter extends Filter<Pair<Name,TreeStructuredData>> {

  final String orderBy;
  final Pair<Name,TreeStructuredData> startAt;
  final Pair<Name,TreeStructuredData> endAt;


  const QueryFilter({this.orderBy, this.startAt, this.endAt, int limit, bool reverse}) :
      super(
          limit: limit,
          reverse: reverse
          );

  factory QueryFilter.fromQuery(Query query) {
    if (query==null) return new QueryFilter();
    return new QueryFilter(
        limit: query.limit,
        reverse: query.isViewFromRight,
        orderBy: query.index,
        startAt: _toNameValue(query.startName, query.startValue),
        endAt: _toNameValue(query.endName, query.endValue)
    );
  }

  static _toNameValue(String key, dynamic value) =>
      key==null&&value==null ? null : new Pair(new Name(key), new TreeStructuredData(value: new Value(value)));

  QueryFilter copyWith({String orderBy, String startAtKey, dynamic startAtValue,
  String endAtKey, dynamic endAtValue, int limit, bool reverse}) =>
      new QueryFilter(
          orderBy: orderBy ?? this.orderBy,
          startAt: _toNameValue(startAtKey, startAtValue) ?? this.startAt,
          endAt: _toNameValue(endAtKey, endAtValue) ?? this.endAt,
          limit: limit ?? this.limit,
          reverse: reverse ?? this.reverse
      );

  Query toQuery() => new Query(limit: limit, isViewFromRight: this.reverse,
      index: orderBy,
      endName: endAt?.key?.asString(), endValue: endAt?.value?.value?.value,
      startName: startAt?.key?.asString(), startValue: startAt?.value?.value?.value
      );

  Pair<Name,Comparable> _extract(Pair<Name,TreeStructuredData> p) {
    switch (orderBy ?? ".priority") {
      case ".value":
        return new Pair(p.key, p.value);
      case ".key":
        return new Pair(p.key, p.key);
      case ".priority":
        return new Pair(p.key, p.value.priority);
      default:
        return new Pair(p.key, p.value.children[new Name(orderBy)]);
    }
  }

  int _compareValue(Comparable a, Comparable b) {
    if (a==null) return b==null ? 0 : -1;
    if (b==null) return 1;
    return Comparable.compare(a,b);
  }
  int _compareKey(Name a, Name b) {
    if (a.asString()==null||b.asString()==null) return 0;
    return Comparable.compare(a,b);
  }
  int _comparePair(Pair<Name,Comparable> a, Pair<Name,Comparable> b) {
    int cmp = _compareValue(a.value, b.value);
    if (cmp!=0) return cmp;
    return _compareKey(a.key, b.key);
  }

  @override
  get isValid => (p) {
    p = _extract(p);
    if (startAt!=null&&_comparePair(startAt,p)>0) return false;
    if (endAt!=null&&_comparePair(p,endAt)>0) return false;
    return true;
  };

  @override
  Comparator<Pair<Name,TreeStructuredData>> get compare => (a,b) =>
      _comparePair(_extract(a),_extract(b));

  toString() => "QueryFilter[${toQuery().toJson()}]";


  int get hashCode => quiver.hash4(orderBy,startAt,endAt,
      quiver.hash2(limit, reverse));

  bool operator==(other) => other is QueryFilter&&
    other.orderBy==orderBy&&other.startAt==startAt&&other.endAt==endAt&&
      other.limit==limit&&other.reverse==reverse;

}


class Repo {

  final Connection _connection;
  final Uri url;

  firebase.Firebase get rootRef => new firebase.Firebase(url.toString());

  static final Map<Uri,Repo> _repos = {};

  final SyncTree _syncTree = new SyncTree();

  final pushIds = new PushIdGenerator();

  final Map<QueryFilter, int> _queryToTag = {};
  final Map<int, QueryFilter> _tagToQuery = {};
  int _nextTag = 0;
  int _nextWriteId = 0;
  TransactionsTree _transactions;

  Repo._(Uri url) : _connection = new Connection(url.host), url = url {
    _transactions = new TransactionsTree(this);
    _connection.output.listen((r) {
      switch (r.message.action) {
        case DataMessage.action_set:
          var filter = _tagToQuery[r.message.body.tag];
          _syncTree.applyServerOverwrite(
              Name.parsePath(r.message.body.path), filter,
              new TreeStructuredData.fromJson(r.message.body.data)
          );
          break;
        case DataMessage.action_merge:
          var filter = _tagToQuery[r.message.body.tag];
          _syncTree.applyServerMerge(
              Name.parsePath(r.message.body.path), filter,
              new TreeStructuredData.fromJson(r.message.body.data).children
          );
          break;
        case DataMessage.action_auth_revoked:
          _onAuth.add(null);
          break;
        case DataMessage.action_listen_revoked:
          var filter = new QueryFilter.fromQuery(r.message.body.query); //TODO test query revoke
          _syncTree.applyListenRevoked(
              Name.parsePath(r.message.body.path), filter
          );
          break;
        case DataMessage.action_security_debug:
          var msg = r.message.body.message;
          _logger.fine("security debug: $msg");
          break;
        default:
          throw new UnimplementedError("Cannot handle message with action ${r.message.action}");
      }
    });
    onAuth.listen((v)=>_authData=v);
  }

  factory Repo(Uri url) {
    return _repos.putIfAbsent(url, ()=>new Repo._(url));
  }

  var _authData;
  final StreamController _onAuth = new StreamController.broadcast();


  /**
   * Generates the special server values
   */
  Map<ServerValue, dynamic> get serverValues => {
    ServerValue.timestamp: _connection.serverTime
  };

  /**
   * The current authData
   */
  get authData => _authData;

  /**
   * Stream of auth data.
   *
   * When a user is logged in, its auth data is posted. When logged of, [null]
   * is posted.
   */
  Stream get onAuth => _onAuth.stream;

  /**
   * Tries to authenticate with [token].
   *
   * Returns a future that completes with the auth data on success, or fails
   * otherwise.
   */
  Future auth(String token) => _connection.auth(token).then((v)=>v["auth"])
      .then((auth) {
    _onAuth.add(auth);
    _authData = auth;
    return auth;
  });


  /**
   * Unauthenticates.
   *
   * Returns a future that completes on success, or fails otherwise.
   */
  Future unauth() => _connection.unauth().then((_) {
    _onAuth.add(null);
    _authData = null;
  });

  /**
   * Writes data [value] to the location [path] and sets the [priority].
   *
   * Returns a future that completes when the data has been written to the
   * server and fails when data could not be written.
   */
  Future setWithPriority(String path, value, priority) {
    var newValue = new TreeStructuredData.fromJson(value, priority, serverValues);
    var writeId = _nextWriteId++;
    _syncTree.applyUserOverwrite(Name.parsePath(path), newValue, writeId);
    _transactions.abort(Name.parsePath(path));
    return _connection.put(path, newValue.toJson(true))
        ..then((_) {
          _syncTree.applyAck(Name.parsePath(path), writeId, true);
        }, onError: (e) {
          _syncTree.applyAck(Name.parsePath(path), writeId, false);
        });
  }

  /**
   * Writes the children in [value] to the location [path].
   *
   * Returns a future that completes when the data has been written to the
   * server and fails when data could not be written.
   */
  Future update(String path, Map<String, dynamic> value) {
    var changedChildren = new Map.fromIterables(
        value.keys.map((c)=>new Name(c)),
        value.values.map((v)=>new TreeStructuredData.fromJson(v, null, serverValues))
    );
    if (value.isNotEmpty) {
      int writeId = _nextWriteId++;
      _syncTree.applyUserMerge(Name.parsePath(path), changedChildren, writeId);
      return _connection.merge(path, value)
        ..then((_) {
          _syncTree.applyAck(Name.parsePath(path), writeId, true);
        }, onError: (e) {
          _syncTree.applyAck(Name.parsePath(path), writeId, false);
        });
    }
    return new Future.value();
  }

  /**
   * Adds [value] to the location [path] for which a unique id is generated.
   *
   * Returns a future that completes with the generated key when the data has
   * been written to the server and fails when data could not be written.
   */
  Future push(String path, dynamic value) async {
    var name = pushIds.next(_connection.serverTime);
    var pushedPath = "$path/$name";
    if (value!=null) {
      await setWithPriority(pushedPath, value, null);
    }
    return name;
  }

  /**
   * Listens to changes of [type] at location [path] for data matching [filter].
   *
   * Returns a future that completes when the listener has been successfully
   * registered at the server.
   *
   */
  Future listen(String path, QueryFilter filter, String type, cb) {
    var isFirst = _syncTree.addEventListener(type, Name.parsePath(path), filter, cb);
    if (!isFirst) return new Future.value();
    if (filter==null) return _connection.listen(path);
    var tag = _nextTag++;
    _queryToTag[filter] = tag;
    _tagToQuery[tag] = filter;
    // TODO: listen only when no containing complete listener, unlisten others
    // TODO: listen and send hash
    return _connection.listen(path, query: filter.toQuery(), tag: tag)
        .then((MessageBody r)  {
      for (var w in r.warnings ?? const []) {
        _logger.warning(w);
      }
    });
  }

  /**
   * Unlistens to changes of [type] at location [path] for data matching [filter].
   *
   * Returns a future that completes when the listener has been successfully
   * unregistered at the server.
   *
   */
  Future unlisten(String path, QueryFilter filter, String type, cb) {
    var isLast = _syncTree.removeEventListener(type, Name.parsePath(path), filter, cb);
    if (!isLast) return new Future.value();
    if (filter==null) return _connection.unlisten(path);
    var tag = _queryToTag.remove(filter);
    _tagToQuery.remove(tag);
    // TODO: listen to others when necessary
    return _connection.unlisten(path, query: filter.toQuery(), tag : tag);
  }

  /**
   * Gets the current cached value at location [path] with [filter].
   */
  TreeStructuredData cachedValue(String path, QueryFilter filter) {
    var tree = _syncTree.root.subtree(Name.parsePath(path));
    if (tree=null) return null;
    return tree.value.views[filter].currentValue.localVersion;
  }

  /**
   * Helper function to create a new stream for a particular event type.
   */
  Stream<firebase.Event> createStream(firebase.Firebase ref, QueryFilter filter, String type) {
    return new _Stream(()=>new StreamFactory(this, ref, filter, type)());
  }




  Future<TreeStructuredData> transaction(String path, Function update, bool applyLocally) =>
      _transactions.startTransaction(Name.parsePath(path), update, applyLocally);


  Future onDisconnectSetWithPriority(String path, value, priority) {
    throw new UnimplementedError("onDisconnect not implemented"); //TODO: implement onDisconnect
  }

  Future onDisconnectUpdate(String path, value) {
    throw new UnimplementedError("onDisconnect not implemented"); //TODO: implement onDisconnect
  }

  Future onDisconnectCancel(String path) {
    throw new UnimplementedError("onDisconnect not implemented"); //TODO: implement onDisconnect
  }
}

class _Stream<T> extends Stream<T> {

  final Function factory;

  _Stream(this.factory);

  @override
  StreamSubscription<T> listen(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    Stream<T> stream = factory();
    return stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class StreamFactory {

  final Repo repo;
  final firebase.Firebase ref;
  final QueryFilter filter;
  final String type;

  StreamFactory(this.repo, this.ref, this.filter, this.type);

  StreamController<firebase.Event> controller;

  void addEvent(value) {

    if (value is ValueEvent) {
      new Future.microtask(()=>
          controller
              .add(new firebase.Event(new firebase.DataSnapshot(ref, value.value), null))
      );
    }
  }
  void addError(error) {
    stopListen();
    controller.addError(error);
    controller.close();
  }

  void startListen() {
    repo.listen(ref.url.path, filter, type, addEvent);
    repo.listen(ref.url.path, filter, "cancel", addError);
  }
  void stopListen() {
    repo.unlisten(ref.url.path, filter, type, addEvent);
    repo.unlisten(ref.url.path, filter, "cancel", addError);
  }

  call() {
    controller = new StreamController<firebase.Event>(
        onListen: startListen, onCancel: stopListen, sync: true);
    return controller.stream;
  }

}

class PushIdGenerator {
  static const PUSH_CHARS = "-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz";
  var lastPushTime = 0;
  final lastRandChars = new List(64);
  final Random random = new Random();

  String next(DateTime timestamp) {

    var now = timestamp.millisecondsSinceEpoch;

    var duplicateTime = now == lastPushTime;
    lastPushTime = now;
    var timeStampChars = new List(8);
    for (var i = 7;i >= 0;i--) {
      timeStampChars[i] = PUSH_CHARS[now % 64];
      now = now ~/ 64;
    }
    var id = timeStampChars.join("");
    if (!duplicateTime) {
      for (var i = 0;i < 12;i++) {
        lastRandChars[i] = random.nextInt(64);
      }
    } else {
      var i;
      for (i = 11;i >= 0 && lastRandChars[i] == 63;i--) {
        lastRandChars[i] = 0;
      }
      lastRandChars[i]++;
    }
    for (var i = 0;i < 12;i++) {
      id += PUSH_CHARS[lastRandChars[i]];
    }
    return id;
  }

}


enum TransactionStatus {run, sent, completed, sent_needs_abort}

class Transaction implements Comparable<Transaction> {

  final Path<Name> path;
  final Function update;
  final bool applyLocally;
  final Repo repo;
  final int order;
  final Completer<firebase.TransactionResult> completer = new Completer();

  static int _order = 0;

  static const max_retries = 25;

  int retryCount = 0;
  String abortReason;
  int currentWriteId;
  TreeStructuredData currentInputSnapshot;
  TreeStructuredData currentOutputSnapshot;

  TransactionStatus status;

  Transaction(this.repo, this.path, this.update, this.applyLocally) : order = _order++ {
    _watch();
  }

  bool get isSent => status==TransactionStatus.sent||status==TransactionStatus.sent_needs_abort;
  bool get isComplete => status==TransactionStatus.completed;
  bool get isAborted => status==TransactionStatus.sent_needs_abort;

  _onValue(_) {}

  _watch() {
    repo.listen(path.join("/"), null, "value", _onValue);
  }

  _unwatch() {
    repo.unlisten(path.join("/"), null, "value", _onValue);
  }

  void run(TreeStructuredData currentState) {
    assert(status==null);
    if (retryCount >= max_retries) {
      fail(new Exception("maxretries"));
      return;
    }

    currentInputSnapshot = currentState;
    try {
      var newVal = update(currentState.toJson());

      status = TransactionStatus.run;

      var newNode = new TreeStructuredData.fromJson(newVal, currentState.priority, repo.serverValues);
      currentOutputSnapshot = newNode;
      currentWriteId = repo._nextWriteId++;

      if (applyLocally) repo._syncTree.applyUserOverwrite(path, newNode, currentWriteId);
    } catch (e) {
      fail(e);
    }
  }

  fail(e) {
    _unwatch();
    currentOutputSnapshot = null;
    if (applyLocally)
      repo._syncTree.applyAck(path, currentWriteId, false);
    status = TransactionStatus.completed;

    completer.complete(new firebase.TransactionResult(e, false,
        new firebase.DataSnapshot(repo.rootRef.child(path.join("/")), currentInputSnapshot)));
  }

  stale() {
    status = null;
    if (applyLocally)
      repo._syncTree.applyAck(path, currentWriteId, false);
  }

  void send() {
    assert(status==TransactionStatus.run);
    status = TransactionStatus.sent;
    retryCount++;
  }

  abort(String reason) {
    switch (status) {
      case TransactionStatus.sent_needs_abort:
        break;
      case TransactionStatus.sent:
        status = TransactionStatus.sent_needs_abort;
        abortReason = reason;
        break;
      case TransactionStatus.run:
        fail(new Exception("set"));
        break;
      default:
        throw new StateError(
            "Unable to abort transaction in state ${status}");
    }
  }

  complete() {
    assert(status==TransactionStatus.sent);
    status = TransactionStatus.completed;

    if (applyLocally)
      repo._syncTree.applyAck(path, currentWriteId, true);

    completer.complete(new firebase.TransactionResult(null, true,
        new firebase.DataSnapshot(repo.rootRef.child(path.join("/")), currentOutputSnapshot)));

    _unwatch();
  }

  @override
  int compareTo(Transaction other) => Comparable.compare(order, other.order);


}

updateChild(TreeStructuredData value, Path<Name> path, TreeStructuredData child) {
  if (path.isEmpty) {
    return child;
  } else {
    var k = path.first;
    var c = value.children[k] ?? new TreeStructuredData();
    var newChild = updateChild(c, path.skip(1), child);
    var newValue = value.clone();
    if (newValue.isLeaf&&!newChild.isNil) newValue.value = null;
    if (newChild.isNil) newValue.children.remove(k);
    else newValue.children[k] = newChild;
    return newValue;
  }
}

class TransactionsTree {

  final Repo repo;
  final TransactionsNode root = new TransactionsNode();

  TransactionsTree(this.repo);

  Future<TreeStructuredData> startTransaction(Path<Name> path,
      Function transactionUpdate, bool applyLocally) {

    var transaction = new Transaction(repo, path, transactionUpdate, applyLocally);
    var node = root.subtree(path, ()=>new TransactionsNode());

    var current = getLatestValue(repo, path);
    if (node.value.isEmpty) {
      node.input = current;
    }
    transaction.run(current);
    node.addTransaction(transaction);
    send();

    return transaction.completer.future;
  }


  Future send() async {
    var finished = await root.send(repo, new Path());
    if (!finished) send();
  }

  abort(Path<Name> path) {
    root.nodesOnPath(path).forEach((n)=>n.abort());
  }

}

TreeStructuredData getLatestValue(Repo repo, Path<Name> path) {
  var node = repo._syncTree.root.subtree(path);
  if (node==null) return new TreeStructuredData();
  return node.value.views[null].currentValue.localVersion;
}


class TransactionsNode extends TreeNode<Name,List<Transaction>> {

  TransactionsNode() : super([]);

  Map<Name,TransactionsNode> get children => super.children;

  TransactionsNode subtree(Path<Name> path, [TransactionsNode newInstance()]) =>
  super.subtree(path, newInstance);

  bool get isReadyToSend => value.every((t)=>t.status==TransactionStatus.run)&&
      children.values.every((n)=>n.isReadyToSend);

  bool get needsRerun => value.any((t)=>t.status==null)||
      children.values.any((n)=>n.needsRerun);
  /**
   * Completes all sent transactions
   */
  complete() {
    value.where((t)=>t.isSent).forEach((m)=>m.complete());
    value.where((t)=>!t.isComplete).forEach((m)=>m.status=null);
    value = value.where((t)=>t.status!=TransactionStatus.completed).toList();
    children.values.forEach((n)=>n.complete());
  }

  /**
   * Fails aborted transactions and resets other sent transactions
   */
  stale() {
    value.where((t)=>t.isAborted).forEach((m)=>m.fail(new Exception(m.abortReason)));
    value.where((t)=>!t.isAborted).forEach((m)=>m.stale());
    value = value.where((t)=>t.status!=TransactionStatus.completed).toList();
    children.values.forEach((n)=>n.stale());
  }

  /**
   * Fails all sent transactions
   */
  fail(e) {
    value.where((t)=>t.isSent).forEach((m)=>m.fail(e));
    value = value.where((t)=>t.status!=TransactionStatus.completed).toList();
    children.values.forEach((n)=>n.fail(e));
  }

  _send() {
    value.forEach((m)=>m.send());
    children.values.forEach((n)=>n._send());
  }

  Future<bool> send(Repo repo, Path<Name> path) async {
    if (value.isNotEmpty) {
      if (needsRerun) {
        stale();
        rerun(path, getLatestValue(repo, path));
      }
      if (isReadyToSend) {
        var latestHash = calculateHash(input.toJson(true));
        try {
          _send();
          await repo._connection.put(path.join("/"), output.toJson(true), latestHash);
          complete();
          return false;
        } on ServerError catch(e) {
          if (e.code=="datastale") stale();
          else fail(e);
          return false;
        }
      }
      return true;
    } else {
      var allFinished = true;
      for (var k in children.keys) {
        allFinished = allFinished&&await children[k].send(repo, path.child(k));
      }
      return allFinished;
    }
  }

  Iterable<Transaction> get transactionsInOrder => new List.from(_transactions)..sort();

  Iterable<Transaction> get _transactions sync* {
    yield* value;
    yield* children.values.expand((n)=>n._transactions);
  }

  rerun(Path<Name> path, TreeStructuredData input) {
    this.input = input;

    var v = input;
    for (var t in transactionsInOrder) {
      var p = t.path.skip(path.length);
      t.run(v.subtree(p, ()=>new TreeStructuredData()) ?? new TreeStructuredData());
      if (!t.isComplete) {
        v = updateChild(v, p, t.currentOutputSnapshot);
      }
    }
  }


  TreeStructuredData input;

  int get lastId => max(value.isEmpty ? -1 : value.map((t)=>t.order).reduce(max),
  children.isEmpty ? -1 : children.values.map((n)=>n.lastId).reduce(max) ?? -1);

  TreeStructuredData get output {
    var v = input;
    var lastId = -1;
    if (value.isNotEmpty) {
      v = value.last.currentOutputSnapshot;
      lastId = value.last.order;
    }
    v = v.clone();
    children.forEach((key, node) {
      if (node.lastId>lastId) {
        v.children[key] = node.output;
      }
    });
    return v;
  }

  addTransaction(Transaction transaction) {
    if (transaction.status==TransactionStatus.run) {
      value.add(transaction);
    }
  }



  abort() {
    for (var txn in value) {
      txn.abort("set");
    }
    value = value.where((t)=>!t.isComplete).toList();
  }

}