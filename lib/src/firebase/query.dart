// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;


/**
 * A Query filters the data at a Firebase location so only a subset of the
 * child data is visible to you. This can be used for example to restrict a
 * large list of items down to a number suitable for synchronizing to the
 * client.
 *
 * Queries are created by chaining together one or two of the following filter
 * functions: startAt(), endAt() and limit().
 *
 * Once a Query is constructed, you can receive data for it using on(). You
 * will only receive events and DataSnapshots for the subset of the data that
 * matches your query.
 */
class Query {
  final Uri _url;
  final Repo _repo;
  final QueryFilter __filter;

  Query._(Uri url, [this.__filter]) :
        _url = url, _repo = new Repo(url.resolve("/"));

  QueryFilter get _filter => __filter ?? const QueryFilter();

  /**
   * Gets a stream for events of type [eventType]
   */
  Stream<Event> on(String eventType) => _repo.createStream(ref, __filter, eventType);
//      _streams.putIfAbsent(eventType, ()=>_repo.createStream(ref, _filter, eventType));

  /**
   * Streams for 'value' events.
   */
  Stream<Event> get onValue => on("value");

  /**
   * Streams for 'child_added' events.
   */
  Stream<Event> get onChildAdded => on("child_added");

  /**
   * Streams for 'child_moved' events.
   */
  Stream<Event> get onChildMoved => on("child_moved");

  /**
   * Streams for 'child_changed' events.
   */
  Stream<Event> get onChildChanged => on("child_changed");

  /**
   * Streams for 'child_removed' events.
   */
  Stream<Event> get onChildRemoved => on("child_removed");

  /**
   * Listens for exactly one event of the specified event type, and then stops
   * listening.
   */
  Future<DataSnapshot> once(String eventType) =>
      on(eventType).first.then((e)=>e.snapshot);

  Future<DataSnapshot> get onceValue => once('value');

  Future get() => onceValue.then((v)=>v.val);

  Query _withFilter(QueryFilter filter) => new Query._(_url, filter);

  /**
   * Generates a new [Query] object ordered by the specified child key.
   */
  Query orderByChild(String child) {
    if (child == null || child.startsWith(r"$"))
      throw new ArgumentError("'$child' is not a valid child");

    return _withFilter(_filter.copyWith(orderBy: child));
  }

  /**
   * Generates a new [Query] object ordered by key.
   */
  Query orderByKey() => _withFilter(_filter.copyWith(orderBy: r".key"));

  /**
   * Generates a new [Query] object ordered by child values.
   */
  Query orderByValue() => _withFilter(_filter.copyWith(orderBy: r".value"));


  /**
   * Generates a new [Query] object ordered by priority.
   */
  Query orderByPriority() => _withFilter(_filter.copyWith(orderBy: r".priority"));


  /**
   * Creates a [Query] with the specified starting point. The generated Query
   * includes children which match the specified starting point. If no arguments
   * are provided, the starting point will be the beginning of the data.
   *
   * The starting point is inclusive, so children with exactly the specified
   * priority will be included. Though if the optional name is specified, then
   * the children that have exactly the specified priority must also have a
   * name greater than or equal to the specified name.
   *
   * startAt() can be combined with endAt() or limitToFirst() or limitToLast()
   * to create further restrictive queries.
   */
  Query startAt({dynamic value, String key}) =>
      _withFilter(_filter.copyWith(startAtKey: key, startAtValue: value));

  /**
   * Creates a [Query] with the specified ending point. The generated Query
   * includes children which match the specified ending point. If no arguments
   * are provided, the ending point will be the end of the data.
   *
   * The ending point is inclusive, so children with exactly the specified
   * priority will be included. Though if the optional name is specified, then
   * children that have exactly the specified priority must also have a name
   * less than or equal to the specified name.
   *
   * endAt() can be combined with startAt() or limitToFirst() or limitToLast()
   * to create further restrictive queries.
   */
  Query endAt({dynamic value, String key}) =>
      _withFilter(_filter.copyWith(endAtKey: key, endAtValue: value));


  /**
   * Creates a [Query] which includes children which match the specified value.
   */
  Query equalTo(value, [String key]) =>
      endAt(value: value, key: key).startAt(value: value, key: key);

  /**
   * Generates a new [Query] object limited to the first certain number of
   * children.
   */
  Query limitToFirst(int limit) =>
      _withFilter(_filter.copyWith(limit: limit, reverse: false));

  /**
   * Generates a new [Query] object limited to the last certain number of
   * children.
   */
  Query limitToLast(int limit) =>
      _withFilter(_filter.copyWith(limit: limit, reverse: true));


  /**
   * Queries are attached to a location in your Firebase. This method will
   * return a Firebase reference to that location.
   */
  Firebase get ref => new Firebase(_url.toString());


}

