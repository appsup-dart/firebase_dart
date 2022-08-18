part of firebase_dart.firestore;

/// An enumeration of document change types.
enum DocumentChangeType {
  /// Indicates a new document was added to the set of documents matching the
  /// query.
  added,

  /// Indicates a document within the query was modified.
  modified,

  /// Indicates a document within the query was removed (either deleted or no
  /// longer matches the query.
  removed,
}

/// A [DocumentChange] represents a change to the documents matching a query.
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
abstract class DocumentChange<T extends Object?> {
  /// The type of change that occurred (added, modified, or removed).
  DocumentChangeType get type;

  /// The index of the changed document in the result set immediately prior to
  /// this [DocumentChange] (i.e. supposing that all prior [DocumentChange] objects
  /// have been applied).
  ///
  /// -1 is returned for [DocumentChangeType.added] events.
  int get oldIndex;

  /// The index of the changed document in the result set immediately after this
  /// [DocumentChange] (i.e. supposing that all prior [DocumentChange] objects
  /// and the current [DocumentChange] object have been applied).
  ///
  /// -1 is returned for [DocumentChangeType.removed] events.
  int get newIndex;

  /// Returns the [DocumentSnapshot] for this instance.
  DocumentSnapshot<T> get doc;
}
