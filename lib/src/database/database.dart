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
      : databaseURL = _normalizeUrl(databaseURL ?? app.options.databaseURL);

  /// Gets a DatabaseReference for the root of your Firebase Database.
  DatabaseReference reference() => ReferenceImpl(this, <String>[]);

  /// Resumes our connection to the Firebase Database backend after a previous
  /// [goOffline] call.
  Future<void> goOnline() async {
    var repo = Repo(this);
    await repo.resume();
  }

  /// Shuts down our connection to the Firebase Database backend until
  /// [goOnline] is called.
  Future<void> goOffline() async {
    var repo = Repo(this);
    await repo.interrupt();
  }

  /// The Firebase Database client automatically queues writes and sends them to
  /// the server at the earliest opportunity, depending on network connectivity.
  /// In some cases (e.g. offline usage) there may be a large number of writes
  /// waiting to be sent. Calling this method will purge all outstanding writes
  /// so they are abandoned.
  ///
  /// All writes will be purged, including transactions and onDisconnect writes.
  /// The writes will be rolled back locally, perhaps triggering events for
  /// affected event listeners, and the client will not (re-)send them to the
  /// Firebase Database backend.
  Future<void> purgeOutstandingWrites() async {
    var repo = Repo(this);
    await repo.purgeOutstandingWrites();
  }

  /// Attempts to sets the database persistence to [enabled].
  ///
  /// This property must be set before calling methods on database references
  /// and only needs to be called once per application. The returned [Future]
  /// will complete with `true` if the operation was successful or `false` if
  /// the persistence could not be set (because database references have
  /// already been created).
  ///
  /// The Firebase Database client will cache synchronized data and keep track
  /// of all writes you’ve initiated while your application is running. It
  /// seamlessly handles intermittent network connections and re-sends write
  /// operations when the network connection is restored.
  ///
  /// However by default your write operations and cached data are only stored
  /// in-memory and will be lost when your app restarts. By setting [enabled]
  /// to `true`, the data will be persisted to on-device (disk) storage and will
  /// thus be available again when the app is restarted (even when there is no
  /// network connectivity at that time).
  Future<bool> setPersistenceEnabled(bool enabled) async {
    // TODO: implement setPersistenceEnabled: do nothing for now

    return false;
  }

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
