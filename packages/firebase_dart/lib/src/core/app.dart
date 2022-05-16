part of firebase_dart.core;

/// Represents a single Firebase app instance.
///
/// You can get an instance by calling [Firebase.app()].
abstract class FirebaseApp {
  /// The name of this [FirebaseApp].
  final String name;

  /// The [FirebaseOptions] this app was created with.
  final FirebaseOptions options;

  FirebaseApp(this.name, this.options);

  /// Deletes this app and frees up system resources.
  ///
  /// Once deleted, any plugin functionality using this app instance will throw
  /// an error.
  Future<void> delete() => Firebase._delete(name);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseApp) return false;
    return other.name == name && other.options == options;
  }

  @override
  late final int hashCode = Object.hash(name, options);

  @override
  String toString() => '$FirebaseApp($name)';
}
