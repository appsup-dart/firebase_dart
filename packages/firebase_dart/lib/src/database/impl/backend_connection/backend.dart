// @dart=2.9

part of firebase_dart.database.backend_connection;

abstract class Backend {
  Auth _auth;

  Future<void> listen(String path, EventListener listener,
      {QueryFilter query = const QueryFilter(), String hash});

  Future<void> unlisten(String path, EventListener listener,
      {QueryFilter query = const QueryFilter()});

  Future<void> put(String path, dynamic value, {String hash});

  Future<void> merge(String path, Map<String, dynamic> children);

  Future<void> auth(Auth auth) async {
    _auth = auth;
  }

  Auth get currentAuth => _auth;
}
