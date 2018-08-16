import 'package:meta/meta.dart';
import 'dart:async';

final Map<String, FirebaseApp> _apps = {};
final Map<FirebaseApp, FirebaseOptions> _options = {};

class FirebaseApp {
  /// The name of this app.
  final String name;

  const FirebaseApp({@required this.name});

  /// A copy of the options for this app. These are non-modifiable.
  FirebaseOptions get options => _options[this];

  static const String defaultAppName = '[DEFAULT]';

  /// Returns the default (first initialized) instance of the FirebaseApp.
  static const FirebaseApp instance = const FirebaseApp(name: defaultAppName);

  /// Returns a list of all extant FirebaseApp instances, or null if there are
  /// no FirebaseApp instances.
  static FutureOr<List<FirebaseApp>> allApps() =>
      _apps.isEmpty ? null : _apps.values.toList();

  /// Returns a previously created FirebaseApp instance with the given name, or
  /// null if no such app exists.
  static FutureOr<FirebaseApp> appNamed(String name) => _apps[name];

  /// Configures an app with the given name and options.
  ///
  /// Configuring the default app is not currently supported. Plugins that can
  /// interact with the default app should configure it automatically at plugin
  /// registration time.
  ///
  /// Changing the options of a configured app is not supported. Reconfiguring
  /// an existing app will assert that the options haven't changed.
  static FutureOr<FirebaseApp> configure({
    @required String name,
    @required FirebaseOptions options,
  }) async {
    assert(name != null);
    assert(options != null);
    final FirebaseApp existingApp = await FirebaseApp.appNamed(name);
    if (existingApp != null) {
      assert(existingApp.options == options);
      return existingApp;
    }
    var app = name == defaultAppName ? instance : new FirebaseApp(name: name);
    _apps[defaultAppName] = app;
    _options[app] = options;
    return app;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is FirebaseApp && other.name == name;
}

class FirebaseOptions {
  final String databaseURL;

  const FirebaseOptions({this.databaseURL});

  factory FirebaseOptions.from(Map map) =>
      new FirebaseOptions(databaseURL: map["databaseURL"]);

  @override
  int get hashCode => databaseURL.hashCode;

  @override
  bool operator ==(Object other) =>
      other is FirebaseOptions && other.databaseURL == databaseURL;
}
