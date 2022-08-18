part of firebase_dart.firestore;

/// The entry point for accessing a [FirebaseFirestore].
abstract class FirebaseFirestore {
  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseFirestore instanceFor({required FirebaseApp app}) {
    return FirebaseImplementation.installation.createFirestore(app);
  }

  /// The [FirebaseApp] for this current [FirebaseFirestore] instance.
  FirebaseApp get app;

  /// Gets a [CollectionReference] for the specified Firestore path.
  CollectionReference<Map<String, dynamic>> collection(String collectionPath);
}
