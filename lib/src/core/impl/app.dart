import 'package:firebase_dart/core.dart';
import 'package:meta/meta.dart';

class FirebaseAppImpl extends FirebaseApp {
  FirebaseAppImpl(String name, FirebaseOptions options) : super(name, options);

  @override
  Future<void> delete() async {
    await FirebaseService._deleteAllForApp(this);
    return super.delete();
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

  static Future<void> _deleteAllForApp(FirebaseApp app) async {
    var services = _services.remove(app) ?? {};
    for (var s in services) {
      await s.delete();
    }
  }

  @mustCallSuper
  Future<void> delete() async {
    _isDeleted = true;
  }
}
