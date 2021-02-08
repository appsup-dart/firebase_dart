import 'dart:async';
import 'dart:isolate';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/database.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/database/impl/firebase_impl.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/storage.dart';

import 'isolate/auth.dart';
import 'isolate/database.dart';
import 'isolate/storage.dart';

class IsolateFirebaseImplementation extends FirebaseImplementation {
  final String storagePath;
  final void Function(String errorMessage, StackTrace stackTrace) onError;

  IsolateFirebaseImplementation(this.storagePath, {this.onError});

  @override
  Future<FirebaseApp> createApp(String name, FirebaseOptions options) async {
    var app = IsolateFirebaseApp(name, options);
    var isolate = await Isolate.spawn(Plugin.create,
        {'sendPort': app._receivePort.sendPort, 'storagePath': storagePath},
        errorsAreFatal: false);
    if (onError != null) {
      var errorReceivePort = ReceivePort();
      errorReceivePort.forEach((l) {
        onError(l[0], StackTrace.fromString(l[1]));
      });
      isolate.addErrorListener(errorReceivePort.sendPort);
    }
    await app._completer.future;
    await app.invoke('core', 'initApp', [options.asMap]);
    return app;
  }

  @override
  FirebaseAuth createAuth(FirebaseApp app) {
    return FirebaseService.findService<IsolateFirebaseAuth>(app) ??
        IsolateFirebaseAuth(app);
  }

  @override
  FirebaseDatabase createDatabase(FirebaseApp app, {String databaseURL}) {
    databaseURL = FirebaseDatabaseImpl.normalizeUrl(
        databaseURL ?? app.options.databaseURL);
    return FirebaseService.findService<IsolateFirebaseDatabase>(
            app, (s) => s.databaseURL == databaseURL) ??
        IsolateFirebaseDatabase(app: app, databaseURL: databaseURL);
  }

  @override
  FirebaseStorage createStorage(FirebaseApp app, {String storageBucket}) {
    return FirebaseService.findService<IsolateFirebaseStorage>(
            app, (s) => s.storageBucket == storageBucket) ??
        IsolateFirebaseStorage(app: app, storageBucket: storageBucket);
  }
}

class IsolateFirebaseApp extends FirebaseApp {
  final ReceivePort _receivePort = ReceivePort();

  SendPort _sendPort;

  int _nextId = 0;

  final Completer<void> _completer = Completer();

  final Map<int, Completer> _requests = {};
  final Map<int, StreamController> _controllers = {};

  IsolateFirebaseApp(String name, FirebaseOptions options)
      : super(name, options) {
    _start();
  }

  Stream createStream(String service, String method, List<dynamic> arguments,
      {bool broadcast = false}) {
    var id = _nextId;
    invoke(service, method, arguments);

    var controller = _controllers[id] =
        broadcast ? StreamController.broadcast() : StreamController();
    controller.onListen = () {
      invoke('core', 'onListen', [id]);
    };
    controller.onCancel = () async {
      await invoke('core', 'onCancel', [id]);
    };
    if (!broadcast) {
      controller.onPause = () {
        invoke('core', 'onPause', [id]);
      };
      controller.onResume = () {
        invoke('core', 'onResume', [id]);
      };
    }

    return controller.stream;
  }

  Future invoke(String service, String method, List<dynamic> arguments) {
    var id = _nextId++;
    _requests[id] = Completer();
    _sendPort.send({
      'id': id,
      'service': service,
      'method': method,
      'arguments': arguments,
    });
    return _requests[id].future;
  }

  void _handleControlMessage(Map<String, dynamic> message) {
    _sendPort = message['sendPort'];
    _completer.complete();
  }

  void _handleDataMessage(Map<String, dynamic> message) {
    var id = message['id'];
    var completer = _requests.remove(id);
    var controller = _controllers.remove(id);
    if (controller != null) {
      var e = message['error'];
      if (e != null) {
        controller.addError(FirebaseException(
            plugin: e['plugin'], code: e['code'], message: e['message']));
      } else if (message.containsKey('value')) {
        controller.add(message['value']);
      } else {
        if (message['status'] == 'done') {
          controller.close();
        }
      }
      return;
    }
    if (completer != null) {
      var e = message['error'];
      if (e != null) {
        completer.completeError(FirebaseException(
            plugin: e['plugin'], code: e['code'], message: e['message']));
      } else {
        completer.complete(message['value']);
      }
    }
  }

  void _start() {
    _receivePort.cast<Map<String, dynamic>>().listen((message) {
      var type = message['type'];
      if (type == 'control') {
        _handleControlMessage(message);
      } else {
        _handleDataMessage(message);
      }
    });
  }

  @override
  Future<void> delete() async {
    await invoke('core', 'delete', []);
    return super.delete();
  }
}

abstract class IsolateFirebaseService extends FirebaseService {
  final String service;

  IsolateFirebaseService(IsolateFirebaseApp app, this.service) : super(app);

  @override
  IsolateFirebaseApp get app => super.app;

  Future invoke(String method, List<dynamic> arguments) {
    return app.invoke(service, method, arguments);
  }

  Stream createStream(String method, List<dynamic> arguments,
      {bool broadcast = false}) {
    return app.createStream(service, method, arguments, broadcast: broadcast);
  }
}

class Plugin {
  final ReceivePort _receivePort = ReceivePort();

  final SendPort _sendPort;
  FirebaseApp _app;

  StreamSubscription _subscription;

  final Map<String, PluginService> _services = {};

  Plugin(this._sendPort);

  static void create(Map<String, dynamic> options) {
    var sendPort = options['sendPort'];
    var storagePath = options['storagePath'];
    PureDartFirebase.setup(storagePath: storagePath);
    Plugin(sendPort)..start();
  }

  void _handleControlMessage(Map<String, dynamic> message) {}

  void _handleDataMessage(Map<String, dynamic> message) async {
    var service = message['service'];
    var method = message['method'];
    var arguments = message['arguments'];
    var id = message['id'];

    try {
      var v = invoke(service, method, arguments);
      if (v is Stream) {
        _streams[id] = v;
      } else {
        _sendPort.send({'id': id, 'value': await v});
      }
    } on FirebaseException catch (e) {
      _sendPort.send({
        'id': id,
        'error': {'code': e.code, 'plugin': e.plugin, 'message': e.message}
      });
    }
  }

  void start() {
    _subscription = _receivePort.cast<Map<String, dynamic>>().listen((message) {
      var type = message['type'];

      if (type == 'control') {
        _handleControlMessage(message);
      } else {
        _handleDataMessage(message);
      }
    });
    _sendPort.send({'type': 'control', 'sendPort': _receivePort.sendPort});
  }

  void stop() {
    _subscription.cancel();
  }

  final Map<int, Stream> _streams = {};
  final Map<int, StreamSubscription> _subscriptions = {};

  dynamic invoke(String service, String method, List<dynamic> arguments) {
    if (service == 'core') {
      switch (method) {
        case 'initApp':
          return Firebase.initializeApp(
                  options: FirebaseOptions.fromMap(arguments.first))
              .then((v) {
            _app = v;
          });
        case 'delete':
          _receivePort.close();
          Isolate.current.kill();
          return _app.delete();
        case 'onListen':
          var id = arguments.first;
          _subscriptions[id] = _streams.remove(id).listen((v) {
            _sendPort.send({'id': id, 'value': v});
          }, onError: (e) {
            if (e is FirebaseException) {
              _sendPort.send({
                'id': id,
                'error': {
                  'code': e.code,
                  'plugin': e.plugin,
                  'message': e.message
                }
              });
            }
            throw e;
          }, onDone: () {
            _sendPort.send({'id': id, 'state': 'done'});
          });
          return;
        case 'onCancel':
          var id = arguments.first;
          return _subscriptions.remove(id).cancel();
        case 'onPause':
          var id = arguments.first;
          return _subscriptions[id].pause();
        case 'onResume':
          var id = arguments.first;
          return _subscriptions[id].resume();
      }
      throw ArgumentError.value(method, 'method');
    }
    var s = getService(service);
    return s.invoke(method, arguments);
  }

  PluginService getService(String service) =>
      _services.putIfAbsent(service, () {
        var parts = service.split(':');
        switch (parts.first) {
          case 'auth':
            return AuthPluginService(FirebaseAuth.instanceFor(app: _app));
          case 'database':
            return DatabasePluginService(FirebaseDatabase(
                app: _app, databaseURL: parts.skip(1).join(':')));
          case 'storage':
            return StoragePluginService(FirebaseStorage.instanceFor(
                app: _app, bucket: parts.skip(1).join(':')));
        }
        throw ArgumentError.value(service, 'service');
      });
}

abstract class PluginService {
  dynamic invoke(String method, List<dynamic> arguments);
}
