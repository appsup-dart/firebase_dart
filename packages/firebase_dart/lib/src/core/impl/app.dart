import 'package:collection/collection.dart' show IterableExtension;
import 'package:firebase_dart/core.dart';
import 'package:meta/meta.dart';

class FirebaseAppImpl extends FirebaseApp {
  FirebaseAppImpl(String name, FirebaseOptions options) : super(name, options);

  @override
  Future<void> delete() async {
    // first call super to remove from list of apps, so it is no longer available
    await super.delete();
    await FirebaseService.deleteAllForApp(this);
  }
}

class FirebaseService {
  static final Map<FirebaseApp, Set<FirebaseService>> _services = {};

  bool _isDeleted = false;
  final FirebaseApp app;

  bool get isDeleted => _isDeleted;

  FirebaseService(this.app) {
    var app =
        Firebase.app(this.app.name); // this will throw when app is deleted
    _services.putIfAbsent(app, () => {}).add(this);
  }

  static Future<void> deleteAllForApp(FirebaseApp app) async {
    var services = _services.remove(app) ?? {};
    for (var s in services) {
      await s.delete();
    }
  }

  @mustCallSuper
  Future<void> delete() async {
    _isDeleted = true;
  }

  static T? findService<T extends FirebaseService?>(FirebaseApp app,
          [bool Function(T service)? predicate]) =>
      _services[app]?.firstWhereOrNull((element) =>
          element is T && (predicate == null || predicate(element as T))) as T?;
}
