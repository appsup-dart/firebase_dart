part of firebase_dart.core;

class FirebaseCoreException extends FirebaseException {
  FirebaseCoreException({required String code, String? message})
      : super(plugin: 'core', code: code, message: message);

  /// Thrown when usage of an app occurs but no app has been created.
  FirebaseCoreException.noAppExists(String appName)
      : this(
            code: 'no-app',
            message:
                "No Firebase App '$appName' has been created - call Firebase.initializeApp()");

  /// Thrown when an app is being created which already exists.
  FirebaseCoreException.duplicateApp(String appName)
      : this(
            code: 'duplicate-app',
            message: 'A Firebase App named "$appName" already exists');

  /// Thrown when no firebase implementation has been setup.
  FirebaseCoreException.noSetup()
      : this(
            code: 'no-setup',
            message: 'No firebase implementation has been setup.');
}
