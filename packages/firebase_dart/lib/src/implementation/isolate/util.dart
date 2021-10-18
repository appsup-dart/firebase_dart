import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:rxdart/rxdart.dart';

abstract class FunctionCall<T> {
  List<dynamic>? get positionalArguments;
  Map<Symbol, dynamic>? get namedArguments;
  Function? get function;

  T run();
}

abstract class BaseFunctionCall<T> implements FunctionCall<T> {
  @override
  final List<dynamic>? positionalArguments;
  @override
  final Map<Symbol, dynamic>? namedArguments;

  BaseFunctionCall(this.positionalArguments, this.namedArguments);

  @override
  T run() => Function.apply(function!, positionalArguments, namedArguments);
}

class RegisteredFunctionCall<T> extends BaseFunctionCall<T> {
  final Symbol functionName;

  RegisteredFunctionCall(this.functionName,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  @override
  Function? get function =>
      IsolateWorker.current._functionRegister[functionName];
}

class StaticFunctionCall<T> extends BaseFunctionCall<T> {
  @override
  final Function function;

  StaticFunctionCall(this.function,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);
}

abstract class IsolateRunnable {
  void run();
}

class CancelStreamSubscription extends IsolateRunnable {
  final SendPort _sendPort;

  CancelStreamSubscription(this._sendPort);

  @override
  void run() {
    IsolateStream._subscriptions[_sendPort]?.cancel();
  }
}

class IsolateStream<T> extends IsolateRunnable {
  final SendPort _sendPort;

  final FunctionCall<Stream<T>> functionCall;

  IsolateStream(this.functionCall, this._sendPort);

  static final Expando<StreamSubscription> _subscriptions = Expando();

  @override
  void run() async {
    var stream = Result.captureStream(functionCall.run())
        .cast<Result<T>?>()
        .endWith(null);
    _subscriptions[_sendPort] = stream.listen(_sendPort.send);
  }
}

class IsolateTask<T> extends IsolateRunnable {
  final SendPort _sendPort;

  final FunctionCall<FutureOr<T>?> functionCall;

  IsolateTask(this.functionCall, this._sendPort);

  Future<Result<T>> _run() async {
    try {
      var v = await functionCall.run() as T;
      return Result.value(v);
    } catch (e, tr) {
      return ErrorResult(
          e is Error ? e.toString() : e, StackTrace.fromString(tr.toString()));
    }
  }

  @override
  void run() async {
    var v = await _run();
    try {
      _sendPort.send(v);
    } catch (e) {
      throw IsolateTransferException('$e: $v');
    }
  }
}

class IsolateTransferException implements Exception {
  final String message;
  IsolateTransferException(this.message);

  @override
  String toString() {
    return 'IsolateTransferException: $message';
  }
}

class IsolateCommander {
  final SendPort _sendPort;

  IsolateCommander._(this._sendPort);

  /// Request to execute a task on another isolate
  Future<T> execute<T>(FunctionCall<FutureOr<T>?> call) async {
    var port = ReceivePort();
    var task = IsolateTask<T>(call, port.sendPort);
    _sendPort.send(task);

    var r = await port.cast<Result<T>>().first;
    port.close();

    return r.asFuture;
  }

  Stream<T> subscribe<T>(FunctionCall<Stream<T>> call) {
    var port = ReceivePort();

    return Result.releaseStream(port
            .cast<Result<T>?>()
            .takeWhile((v) => v != null)
            .cast<Result<T>>())
        .doOnListen(() {
      _sendPort.send(IsolateStream<T>(call, port.sendPort));
    }).doOnCancel(() {
      _sendPort.send(CancelStreamSubscription(port.sendPort));
    });
  }

  Future<void> shutdownWorker() async {
    return execute(IsolateWorkerControlFunctionCall(#shutdown));
  }

  Future<void> registerFunction(Symbol name, Function function) {
    return execute(
        IsolateWorkerControlFunctionCall(#registerFunction, [name, function]));
  }
}

class IsolateWorker {
  final ReceivePort _receivePort = ReceivePort();
  final Map<Symbol, Function> _functionRegister = {};

  /// Should be called from the isolate executing the tasks. The result can be
  /// transmitted to another isolate.
  IsolateWorker() {
    _receivePort.cast<IsolateRunnable>().listen((runnable) {
      runZoned(() => runnable.run(),
          zoneValues: {#IsolateWorker.current: this});
    });
  }

  static IsolateWorker get current => Zone.current[#IsolateWorker.current];

  void close() {
    _receivePort.close();
  }

  void registerFunction(Symbol name, Function function) {
    _functionRegister[name] = function;
  }

  IsolateCommander get commander => IsolateCommander._(_receivePort.sendPort);

  static Future<IsolateCommander> startWorkerInIsolate(
      {String? debugName}) async {
    var port = ReceivePort();
    var errors = ReceivePort();

    errors.cast<List>().listen((message) {
      var error = message[0];
      var stackTrace = message[1] == null
          ? StackTrace.current
          : StackTrace.fromString(message[1]);
      Zone.current.handleUncaughtError(error, stackTrace);
    });
    await Isolate.spawn(_isolateEntry, port.sendPort,
        errorsAreFatal: false, onError: errors.sendPort, debugName: debugName);

    var commander = await port.cast<IsolateCommander>().first;

    return commander;
  }

  static void _isolateEntry(SendPort port) {
    var worker = IsolateWorker();
    port.send(worker.commander);
  }
}

class IsolateWorkerControlFunctionCall<T> extends BaseFunctionCall<T> {
  final Symbol functionName;

  IsolateWorkerControlFunctionCall(this.functionName,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  @override
  Function get function {
    switch (functionName) {
      case #shutdown:
        return IsolateWorker.current.close;
      case #registerFunction:
        return IsolateWorker.current.registerFunction;
    }
    throw UnsupportedError(
        'IsolateWorkerControlFunctionCall with reference $functionName not supported');
  }
}
