part of firebase_dart;

/// The entry point for accessing a Firebase Database.
///
/// To access a location in the database and read or write data, use `reference()`.
class FirebaseDatabase {
  /// The [FirebaseApp] instance to which this [FirebaseDatabase] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.
  final FirebaseApp app;

  /// The URL to which this [FirebaseDatabase] belongs
  ///
  /// If null, the URL of the specified [FirebaseApp] is used
  final String databaseURL;

  /// Gets an instance of [FirebaseDatabase].
  ///
  /// If app is specified, its options should include a `databaseURL`.
  FirebaseDatabase({this.app, String databaseURL})
      : databaseURL = _normalizeUrl(databaseURL);

  /// Gets a DatabaseReference for the root of your Firebase Database.
  DatabaseReference reference() => ReferenceImpl(this, <String>[]);

  @override
  int get hashCode => quiver.hash2(databaseURL, app);

  @override
  bool operator ==(Object other) =>
      other is FirebaseDatabase &&
      other.app == app &&
      other.databaseURL == databaseURL;
}

String _normalizeUrl(String url) {
  if (url == null) {
    throw ArgumentError.notNull('databaseURL');
  }
  var uri = Uri.parse(url);

  if (!['http', 'https', 'mem'].contains(uri.scheme)) {
    throw ArgumentError.value(
        url, 'databaseURL', 'Only http, https or mem scheme allowed');
  }
  if (uri.pathSegments.isNotEmpty) {
    throw ArgumentError.value(url, 'databaseURL', 'Paths are not allowed');
  }
  return Uri.parse(url).replace(path: '').toString();
}