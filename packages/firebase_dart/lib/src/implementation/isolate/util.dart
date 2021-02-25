import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';

class IsolateTask<T> {
  SendPort _sendPort;

  final dynamic functionReference;
  final List<dynamic> positionalArguments;
  final Map<Symbol, dynamic> namedArguments;

  IsolateTask(this.functionReference,
      [this.positionalArguments, this.namedArguments]);

  Future<Result<T>> _run(IsolateWorker worker) async {
    try {
      var v = await Function.apply(
          worker._resolveFunction(this), positionalArguments, namedArguments);
      return Result.value(v);
    } catch (e, tr) {
      return ErrorResult(e.toString(), StackTrace.fromString(tr.toString()));
    }
  }
}

class IsolateCommander {
  final SendPort _sendPort;

  IsolateCommander._(this._sendPort);

  /// Request to execute a task on another isolate
  Future<T> execute<T>(IsolateTask<T> task) async {
    if (task._sendPort != null) {
      throw StateError('A task should only be executed once');
    }
    var port = ReceivePort();
    task._sendPort = port.sendPort;
    _sendPort.send(task);

    var r = await port.cast<Result<T>>().first;
    port.close();

    return r.asFuture;
  }
}

class IsolateWorker {
  final ReceivePort _receivePort = ReceivePort();
  final Map<Symbol, Function> _functionRegister = {};

  /// Should be called from the isolate executing the tasks. The result can be
  /// transmitted to another isolate.
  ///
  ///
  IsolateWorker() {
    _receivePort.cast<IsolateTask>().listen((task) async {
      task._sendPort.send(await task._run(this));
    });
  }

  Function _resolveFunction(IsolateTask task) {
    if (task.functionReference is Function) return task.functionReference;
    if (task.functionReference is Symbol &&
        _functionRegister[task.functionReference] != null) {
      return _functionRegister[task.functionReference];
    }
    throw ArgumentError(
        'Function reference ${task.functionReference} is not a static Function or a Symbol referencing a registered function');
  }

  void close() {
    _receivePort.close();
  }

  void registerFunction(Symbol name, Function function) {
    _functionRegister[name] = function;
  }

  IsolateCommander get commander => IsolateCommander._(_receivePort.sendPort);
}
