part of firebase_dart.firestore;

class FirebaseFirestoreException extends FirebaseException {
  FirebaseFirestoreException({required String code, String? message})
      : super(plugin: 'firestore', code: code, message: message);
}
