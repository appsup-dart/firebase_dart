part of firebase_dart.firestore;

/// A [QueryDocumentSnapshot] contains data read from a document in your [FirebaseFirestore]
/// database as part of a query.
///
/// A [QueryDocumentSnapshot] offers the same API surface as a [DocumentSnapshot].
/// Since query results contain only existing documents, the exists property
/// will always be `true` and [data()] will never return `null`.
@sealed
abstract class QueryDocumentSnapshot<T extends Object?>
    implements DocumentSnapshot<T> {
  @override
  T data();
}
