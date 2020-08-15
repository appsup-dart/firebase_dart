part of firebase_dart.core;

/// The entry point for accessing Firebase.
class Firebase {
  // Ensures end-users cannot initialize the class.
  Firebase._();

  static final Map<String, FirebaseApp> _apps = {};

  /// Returns a list of all [FirebaseApp] instances that have been created.
  static List<FirebaseApp> get apps {
    return _apps.values.toList(growable: false);
  }

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app.
  static Future<FirebaseApp> initializeApp(
      {String name, @required FirebaseOptions options}) async {
    name ??= defaultFirebaseAppName;
    if (_apps.containsKey(name)) {
      throw FirebaseCoreException.duplicateApp(name);
    }
    var app = FirebaseAppImpl(name, options);
    return _apps[name] = app;
  }

  /// Returns a [FirebaseApp] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
  static FirebaseApp app([String name = defaultFirebaseAppName]) {
    if (_apps[name] == null) {
      throw FirebaseCoreException.noAppExists(name);
    }
    return _apps[name];
  }

  static Future<void> _delete(String name) async {
    if (_apps[name] == null) {
      throw FirebaseCoreException.noAppExists(name);
    }
    _apps.remove(name);
  }
}
