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
import 'package:collection/collection.dart' show ListEquality;
import 'package:sortedmap/sortedmap.dart';

final _logger = new Logger("firebase-repo");

class QueryFilter extends Filter<Pair<Name,TreeStructuredData>> {

  final String orderBy;
  final List<dynamic> startAt;
  final List<dynamic> endAt;


  const QueryFilter({this.orderBy, this.startAt, this.endAt, int limit, bool reverse}) :
      super(
          limit: limit,
          reverse: reverse
          );



  QueryFilter copyWith({String orderBy, List<dynamic> startAt, List<dynamic> endAt, int limit, bool reverse}) =>
      new QueryFilter(
          orderBy: orderBy ?? this.orderBy,
          startAt: startAt ?? this.startAt,
          endAt: endAt ?? this.endAt,
          limit: limit ?? this.limit,
          reverse: reverse ?? this.reverse
      );

  Query toQuery() => new Query(limit: limit, isViewFromRight: this.reverse, index: orderBy);

  // TODO: isValid -> startAt/endAt

  @override
  Comparator<Pair<Name,TreeStructuredData>> get compare {
    // TODO: check ordering
    switch(orderBy) {
      case ".value":
        return (Pair a, Pair b) {
          int cmp = Comparable.compare(a.value, b.value);
          if (cmp!=0) return cmp;
          return Comparable.compare(a.key, b.key);
        };
      case ".key":
        return (Pair a, Pair b) => Comparable.compare(a.key, b.key);
      case ".priority":
        return (Pair<Name,TreeStructuredData> a, Pair<Name,TreeStructuredData> b) {
          int cmp = Comparable.compare(a.value.priority, b.value.priority);
          if (cmp!=0) return cmp;
          return Comparable.compare(a.key, b.key);
        };
      default:
        return (Pair<Name,TreeStructuredData> a, Pair<Name,TreeStructuredData> b) {
          var c1 = a.value.children[new Name(orderBy)];
          var c2 = b.value.children[new Name(orderBy)];
          if (c1==null) return c2==null ? Comparable.compare(a.key, b.key) : -1;
          if (c2==null) return 1;
          int cmp = Comparable.compare(c1.value,c2.value);
          if (cmp!=0) return cmp;
          return Comparable.compare(a.key, b.key);
        };
    }
  }

  toString() => "QueryFilter[${toQuery().toJson()}";


  int get hashCode => quiver.hash4(orderBy,
      startAt!=null ? quiver.hashObjects(startAt) : null,
      endAt!=null ? quiver.hashObjects(endAt) : null,
      quiver.hash2(limit, reverse));

  bool operator==(other) => other is QueryFilter&&
    other.orderBy==orderBy&&const ListEquality().equals(other.startAt,startAt)&&
      const ListEquality().equals(other.endAt,endAt)&&
      other.limit==limit&&other.reverse==reverse;

}


class Repo {

  final Connection _connection;

  static final Map<String,Repo> _repos = {};

  final SyncTree _syncTree = new SyncTree();

  final pushIds = new PushIdGenerator();

  final Map<QueryFilter, int> _queryToTag = {};
  final Map<int, QueryFilter> _tagToQuery = {};
  int _nextTag = 0;

  Repo._(String host) : _connection = new Connection(host) {
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
        // TODO: auth revoke/listen revoke/security debug
        default:
          throw new UnimplementedError("Cannot handle message with action ${r.message.action}");
      }
    });
    onAuth.listen((v)=>_authData=v);
  }

  factory Repo(String host) {
    return _repos.putIfAbsent(host, ()=>new Repo._(host));
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
    _syncTree.applyUserOverwrite(Name.parsePath(path), newValue);
    return _connection.put(path, newValue.toJson(true));
    // TODO: ack operation
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
      _syncTree.applyUserMerge(Name.parsePath(path), changedChildren);
      return _connection.merge(path, value);
      // TODO: ack operation
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

    StreamController<firebase.Event> controller;

    void addEvent(value) {

      if (value is ValueEvent) {
        new Future.microtask(()=>
            controller
                .add(new firebase.Event(new firebase.DataSnapshot(ref, value.value), null))
        );
      }
    }

    void startListen() {
      listen(ref.url.path, filter, type, addEvent);
    }
    void stopListen() {
      unlisten(ref.url.path, filter, type, addEvent);
    }
    controller = new StreamController<firebase.Event>(
        onListen: startListen, onCancel: stopListen, sync: true);
    return controller.stream;//.asBroadcastStream();
  }




  Future<firebase.TransactionResult> transaction(Function update, bool applyLocally) {
    throw new UnimplementedError("transactions not implemented"); //TODO: implement transactions
  }

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
