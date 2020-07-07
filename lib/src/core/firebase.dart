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
      {String name, FirebaseOptions options}) async {
    name ??= defaultFirebaseAppName;
    if (_apps.containsKey(name)) {
      throw FirebaseCoreException.duplicateApp(name);
    }
    var app = FirebaseApp._(name, options);
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

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! Firebase) return false;
    return other.hashCode == hashCode;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$Firebase';
}
