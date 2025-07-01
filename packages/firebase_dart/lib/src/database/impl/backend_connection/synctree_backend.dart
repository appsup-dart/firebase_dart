part of '../backend_connection.dart';

class SyncTreeBackend extends Backend {
  final SyncTree syncTree;

  SyncTreeBackend(this.syncTree);

  @override
  Future<List<String>> listen(String path, EventListener listener,
      {QueryFilter query = const QueryFilter(), String? hash}) async {
    await syncTree.addEventListener(
        'value', Name.parsePath(path), query, listener);
    return [];
  }

  @override
  Future<void> unlisten(String path, EventListener? listener,
      {QueryFilter query = const QueryFilter()}) async {
    await syncTree.removeEventListener(
        'value', Name.parsePath(path), query, listener!);
  }

  @override
  Future<void> put(String path, value, {String? hash}) async {
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
    var existing = syncTree.valueForPathAndFilter(p, const QueryFilter());
    syncTree.applyServerOperation(
        TreeOperation.overwrite(
            p,
            ServerValueX.resolve(
                TreeStructuredData.fromJson(value), existing, serverValues)),
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
                ServerValueX.resolve(
                    TreeStructuredData.fromJson(v),
                    syncTree.valueForPathAndFilter(
                        Path.from(
                            [...Name.parsePath(path), ...Name.parsePath(k)]),
                        const QueryFilter()),
                    serverValues)))),
        null);
  }
}
