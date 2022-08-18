part of firebase_dart.firestore;

/// Metadata about a snapshot, describing the state of the snapshot.
abstract class SnapshotMetadata {
  /// Whether the snapshot contains the result of local writes that have not yet
  /// been committed to the backend.
  ///
  /// If you called [DocumentReference.snapshots] or [Query.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `hasPendingWrites` equal to `false` once the writes have been
  /// committed to the backend.
  bool get hasPendingWrites;

  /// Whether the snapshot was created from cached data rather than guaranteed
  /// up-to-date server data.
  ///
  /// If you called [DocumentReference.snapshots] or [Query.snapshots] with
  /// `includeMetadataChanges` parameter set to `true` you will receive another
  /// snapshot with `isFomCache` equal to `false` once the client has received
  /// up-to-date data from the backend.
  bool get isFromCache;
}
