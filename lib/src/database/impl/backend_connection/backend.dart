part of firebase_dart.database.backend_connection;

abstract class Backend {
  Future<void> listen(String path, EventListener listener,
      {Query query, String hash});

  Future<void> unlisten(String path, EventListener listener, {Query query});

  Future<void> put(String path, dynamic value, {String hash});

  Future<void> merge(String path, Map<String, dynamic> children);
}
