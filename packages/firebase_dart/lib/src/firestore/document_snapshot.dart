part of firebase_dart.firestore;

typedef FromFirestore<T> = T Function(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
  SnapshotOptions? options,
);
typedef ToFirestore<T> = Map<String, Object?> Function(
  T value,
  SetOptions? options,
);

/// Options that configure how data is retrieved from a DocumentSnapshot
/// (e.g. the desired behavior for server timestamps that have not yet been set to their final value).
///
/// Currently unsupported by FlutterFire, but exposed to avoid breaking changes
/// in the future once this class is supported.
@sealed
class SnapshotOptions {}

/// A [DocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database.
///
/// The data can be extracted with the data property or by using subscript
/// syntax to access a specific field.
@sealed
abstract class DocumentSnapshot<T extends Object?> {
  /// This document's given ID for this snapshot.
  String get id;

  /// Returns the reference of this snapshot.
  DocumentReference<T> get reference;

  /// Metadata about this document concerning its source and if it has local
  /// modifications.
  SnapshotMetadata get metadata;

  /// Returns `true` if the document exists.
  bool get exists;

  /// Contains all the data of this document snapshot.
  T? data();

  /// {@template firestore.documentsnapshot.get}
  /// Gets a nested field by [String] or [FieldPath] from this [DocumentSnapshot].
  ///
  /// Data can be accessed by providing a dot-notated path or [FieldPath]
  /// which recursively finds the specified data. If no data could be found
  /// at the specified path, a [StateError] will be thrown.
  /// {@endtemplate}
  dynamic get(Object field);

  /// {@macro firestore.documentsnapshot.get}
  dynamic operator [](Object field);
}
