
import 'package:isolate/isolate.dart';
import 'dart:isolate';
import 'dart:async';


class Runners {

  static Runner _mainRunner;

  static Runner get mainRunner => _mainRunner ??= new IsolateRunner(Isolate.current, new IsolateRunnerRemote().commandPort);

  static void setMainRunner(Runner runner) {
    assert(_mainRunner==null);
    _mainRunner = runner;
  }

  static Future<Null> setMainRunnerOnRunner(Runner runner) => runner.run(setMainRunner, mainRunner);

  static Future<IsolateRunner> spawnIsolate() async {
    var runner = await IsolateRunner.spawn();
    await setMainRunnerOnRunner(runner);
    return runner;
  }
}

