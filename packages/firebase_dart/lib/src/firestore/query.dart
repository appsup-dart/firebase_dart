part of firebase_dart.firestore;

/// Represents a [Query] over the data at a particular location.
///
/// Can construct refined [Query] objects by adding filters and ordering.
// `extends Object?` so that type inference defaults to `Object?` instead of `dynamic`
@sealed
@immutable
abstract class Query<T extends Object?> {
  /// The [FirebaseFirestore] instance of this query.
  FirebaseFirestore get firestore;

  /// Creates and returns a new [Query] that ends at the provided document
  /// (inclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Cannot be used in combination with [endBefore], [endBeforeDocument], or
  /// [endAt], but can be used in combination with [startAt],
  /// [startAfter], [startAtDocument] and [startAfterDocument].
  ///
  /// See also:
  ///
  ///  * [startAfterDocument] for a query that starts after a document.
  ///  * [startAtDocument] for a query that starts at a document.
  ///  * [endBeforeDocument] for a query that ends before a document.
  Query<T> endAtDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that ends at the
  /// provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endAt(List<Object?> values);

  /// Creates and returns a new [Query] that ends before the provided document
  /// snapshot (exclusive). The end position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endBeforeDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that ends before
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query<T> endBefore(List<Object?> values);

  /// Fetch the documents for this query.
  ///
  /// To modify how the query is fetched, the [options] parameter can be provided
  /// with a [GetOptions] instance.
  Future<QuerySnapshot<T>> get([GetOptions? options]);

  /// Creates and returns a new Query that's additionally limited to only return up
  /// to the specified number of documents.
  Query<T> limit(int limit);

  /// Creates and returns a new Query that only returns the last matching documents.
  ///
  /// You must specify at least one orderBy clause for limitToLast queries,
  /// otherwise an exception will be thrown during execution.
  Query<T> limitToLast(int limit);

  /// Notifies of query results at this location.
  Stream<QuerySnapshot<T>> snapshots({bool includeMetadataChanges = false});

  /// Creates and returns a new [Query] that's additionally sorted by the specified
  /// [field].
  /// The field may be a [String] representing a single field name or a [FieldPath].
  ///
  /// After a [FieldPath.documentId] order by call, you cannot add any more [orderBy]
  /// calls.
  ///
  /// Furthermore, you may not use [orderBy] on the [FieldPath.documentId] [field] when
  /// using [startAfterDocument], [startAtDocument], [endBeforeDocument],
  /// or [endAtDocument] because the order by clause on the document id
  /// is added by these methods implicitly.
  Query<T> orderBy(Object field, {bool descending = false});

  /// Creates and returns a new [Query] that starts after the provided document
  /// (exclusive). The starting position is relative to the order of the query.
  /// The [documentSnapshot] must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAfterDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that starts
  /// after the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAfter(List<Object?> values);

  /// Creates and returns a new [Query] that starts at the provided document
  /// (inclusive). The starting position is relative to the order of the query.
  /// The document must contain all of the fields provided in the orderBy of
  /// this query.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAtDocument(
    // Voluntarily accepts any DocumentSnapshot<T>
    DocumentSnapshot documentSnapshot,
  );

  /// Takes a list of [values], creates and returns a new [Query] that starts at
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query<T> startAt(List<Object?> values);

  /// Creates and returns a new [Query] with additional filter on specified
  /// [field]. [field] refers to a field in a document.
  ///
  /// The [field] may be a [String] consisting of a single field name
  /// (referring to a top level field in the document),
  /// or a series of field names separated by dots '.'
  /// (referring to a nested field in the document).
  /// Alternatively, the [field] can also be a [FieldPath].
  ///
  /// Only documents satisfying provided condition are included in the result
  /// set.
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  });

  /// Transforms a [Query] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final personsRef = FirebaseFirestore
  ///     .instance
  ///     .collection('persons')
  ///     .where('age', isGreaterThan: 0)
  ///     .withConverter<Person>(
  ///       fromFirestore: (snapshot, _) => Person.fromJson(snapshot.data()!),
  ///       toFirestore: (person, _) => person.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   List<QuerySnapshot<Person>> persons = await personsRef.get().then((s) => s.docs);
  /// }
  /// ```
  Query<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });
}
