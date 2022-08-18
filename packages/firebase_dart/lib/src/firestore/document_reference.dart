part of firebase_dart.firestore;

/// A [DocumentReference] refers to a document location in a [FirebaseFirestore] database
/// and can be used to write, read, or listen to the location.
///
/// The document at the referenced location may or may not exist.
/// A [DocumentReference] can also be used to create a [CollectionReference]
/// to a subcollection.
@sealed
@immutable
abstract class DocumentReference<T extends Object?> {
  /// The Firestore instance associated with this document reference.
  FirebaseFirestore get firestore;

  /// This document's given ID within the collection.
  String get id;

  /// The parent [CollectionReference] of this document.
  CollectionReference<T> get parent;

  /// A string representing the path of the referenced document (relative to the
  /// root of the database).
  String get path;

  /// Gets a [CollectionReference] instance that refers to the collection at the
  /// specified path, relative from this [DocumentReference].
  CollectionReference<Map<String, dynamic>> collection(String collectionPath);

  /// Deletes the current document from the collection.
  Future<void> delete();

  /// Updates data on the document. Data will be merged with any existing
  /// document data.
  ///
  /// If no document exists yet, the update will fail.
  Future<void> update(Map<String, Object?> data);

  /// Reads the document referenced by this [DocumentReference].
  ///
  /// By providing [options], this method can be configured to fetch results only
  /// from the server, only from the local cache or attempt to fetch results
  /// from the server and fall back to the cache (which is the default).
  Future<DocumentSnapshot<T>> get([GetOptions? options]);

  /// Notifies of document updates at this location.
  ///
  /// An initial event is immediately sent, and further events will be
  /// sent whenever the document is modified.
  Stream<DocumentSnapshot<T>> snapshots({bool includeMetadataChanges = false});

  /// Sets data on the document, overwriting any existing data. If the document
  /// does not yet exist, it will be created.
  ///
  /// If [SetOptions] are provided, the data will be merged into an existing
  /// document instead of overwriting.
  Future<void> set(T data, [SetOptions? options]);

  /// Transforms a [DocumentReference] to manipulate a custom object instead
  /// of a `Map<String, dynamic>`.
  ///
  /// This makes both read and write operations type-safe.
  ///
  /// ```dart
  /// final modelRef = FirebaseFirestore
  ///     .instance
  ///     .collection('models')
  ///     .doc('123')
  ///     .withConverter<Model>(
  ///       fromFirestore: (snapshot, _) => Model.fromJson(snapshot.data()!),
  ///       toFirestore: (model, _) => model.toJson(),
  ///     );
  ///
  /// Future<void> main() async {
  ///   // Writes now take a Model as parameter instead of a Map
  ///   await modelRef.set(Model());
  ///
  ///   // Reads now return a Model instead of a Map
  ///   final Model model = await modelRef.get().then((s) => s.data());
  /// }
  /// ```
  DocumentReference<R> withConverter<R>({
    required FromFirestore<R> fromFirestore,
    required ToFirestore<R> toFirestore,
  });
}
