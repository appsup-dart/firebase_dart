part of firebase_dart.firestore;

/// Contains the results of a query.
/// It can contain zero or more [DocumentSnapshot] objects.
abstract class QuerySnapshot<T extends Object?> {
  /// Gets a list of all the documents included in this snapshot.
  List<QueryDocumentSnapshot<T>> get docs;

  /// An array of the documents that changed since the last snapshot. If this
  /// is the first snapshot, all documents will be in the list as Added changes.
  List<DocumentChange<T>> get docChanges;

  /// Returns the [SnapshotMetadata] for this snapshot.
  SnapshotMetadata get metadata;

  /// Returns the size (number of documents) of this snapshot.
  int get size;
}
