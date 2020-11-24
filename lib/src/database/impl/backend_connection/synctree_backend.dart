part of firebase_dart.database.backend_connection;

class SyncTreeBackend extends Backend {
  final SyncTree syncTree;

  SyncTreeBackend(this.syncTree);

  @override
  Future<void> listen(String path, EventListener listener,
      {Query query = const Query(), String hash}) async {
    await syncTree.addEventListener(
        'value', Name.parsePath(path), query.toFilter(), listener);
  }

  @override
  Future<void> unlisten(String path, EventListener listener,
      {Query query = const Query()}) async {
    await syncTree.removeEventListener(
        'value', Name.parsePath(path), query.toFilter(), listener);
  }

  @override
  Future<void> put(String path, value, {String hash}) async {
    var serverValues = {
      ServerValue.timestamp: Value(DateTime.now().millisecondsSinceEpoch)
    };
    var p = Name.parsePath(path);
    if (hash != null) {
      var current = getLatestValue(syncTree, p);
      if (hash != current.hash) {
        throw FirebaseDatabaseException.dataStale();
      }
    }
    syncTree.applyServerOperation(
        TreeOperation.overwrite(
            p,
            ServerValue.resolve(
                TreeStructuredData.fromJson(value), serverValues)),
        null);
  }

  @override
  Future<void> merge(String path, Map<String, dynamic> children) async {
    var serverValues = {
      ServerValue.timestamp: Value(DateTime.now().millisecondsSinceEpoch)
    };
    syncTree.applyServerOperation(
        TreeOperation.merge(
            Name.parsePath(path),
            children.map((k, v) => MapEntry(
                Name.parsePath(k),
                ServerValue.resolve(
                    TreeStructuredData.fromJson(v), serverValues)))),
        null);
  }
}
