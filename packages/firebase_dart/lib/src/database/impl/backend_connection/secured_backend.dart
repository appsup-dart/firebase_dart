

part of firebase_dart.database.backend_connection;

class SecuredBackend extends Backend {
  SecurityTree _securityTree =
      SecurityTree.fromJson({'.read': 'true', '.write': 'true'});

  final Backend unsecuredBackend;

  SecuredBackend.from(this.unsecuredBackend);

  SecurityTree get securityTree => _securityTree;

  set securityRules(Map<String, dynamic> rules) {
    _securityTree = SecurityTree.fromJson(rules);
    // TODO reevaluate all listeners
  }

  @override
  Future<void> auth(Auth? auth) {
    return super.auth(auth);
    // TODO reevaluate listeners
  }

  @override
  Future<void> listen(String? path, EventListener listener,
      {QueryFilter? query = const QueryFilter(), String? hash}) async {
    var completer = Completer();

    var root = RuleDataSnapshotFromBackend.root(unsecuredBackend);
    securityTree
        .canRead(auth: currentAuth, path: path!, root: root)
        .listen((canRead) {
      if (!canRead) {
        if (completer.isCompleted) {
          listener(CancelEvent(FirebaseDatabaseException.permissionDenied(),
              StackTrace.current));
          unlisten(path, listener, query: query);
        } else {
          completer.completeError(
              FirebaseDatabaseException.permissionDenied(), StackTrace.current);
        }
      } else {
        completer.complete();
      }
    }); // TODO cancel subscription on unlisten
    await completer.future;
    await unsecuredBackend.listen(path, listener, query: query, hash: hash);
  }

  @override
  Future<void> unlisten(String? path, EventListener? listener,
      {QueryFilter? query = const QueryFilter()}) async {
    await unsecuredBackend.unlisten(path, listener, query: query);
  }

  @override
  Future<void> merge(String? path, Map<String, dynamic>? children) async {
    // TODO check write rules and validate rules
    await unsecuredBackend.merge(path, children);
  }

  @override
  Future<void> put(String? path, value, {String? hash}) async {
    // TODO check write rules and validate rules
    await unsecuredBackend.put(path, value, hash: hash);
  }
}
