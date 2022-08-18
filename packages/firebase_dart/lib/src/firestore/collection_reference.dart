part of firebase_dart.firestore;

@immutable

/// A [CollectionReference] can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [Query]).
abstract class CollectionReference<T extends Object?> implements Query<T> {
  /// Identifier of the referenced collection.
  String get id;

  /// For subcollections, parent returns the containing [DocumentReference].
  ///
  /// For root collections, `null` is returned.
  DocumentReference<Map<String, dynamic>>? get parent;

  /// A string containing the slash-separated path to this  CollectionReference
  /// (relative to the root of the database).
  String get path;

  /// Returns a [DocumentReference] with an auto-generated ID, after
  /// populating it with provided [data].
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  Future<DocumentReference<T>> add(T data);

  /// Returns a [DocumentReference] with the provided [path].
  ///
  /// If no [path] is provided, an auto-generated ID is used.
  ///
  /// The unique key generated is prefixed with a client-generated timestamp
  /// so that the resulting list will be chronologically-sorted.
  DocumentReference<T> doc([String? path]);

  /// Transforms a [CollectionReference] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final modelsRef = FirebaseFirestore
  ///     .instance
  ///     .collection('models')
  ///     .withConverter<Model>(
  ///       fromFirestore: (snapshot, _) => Model.fromJson(snapshot.data()!),
  ///       toFirestore: (model, _) => model.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   // Writes now take a Model as parameter instead of a Map
  ///   await modelsRef.add(Model());
  ///
  ///   // Reads now return a Model instead of a Map
  ///   final Model model = await modelsRef.doc('123').get().then((s) => s.data());
  /// }
  /// ```
  // `extends Object?` so that type inference defaults to `Object?` instead of `dynamic`
  @override
  CollectionReference<R> withConverter<R extends Object?>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });
}
