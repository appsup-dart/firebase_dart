import 'dart:io';

/// Runs smoke-tagged tests under [test/smoke].
///
/// Config comes from [allConfigs] in `package:_integration_testing` (generate
/// with `dart run tool/generate_firebase_web_config.dart` in
/// `packages/_integration_testing`).
Future<void> main(List<String> args) async {
  var runIo = true;
  var runChrome = true;

  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--no-io':
        runIo = false;
        break;
      case '--no-chrome':
        runChrome = false;
        break;
      case '-h':
      case '--help':
        _printUsage();
        return;
      default:
        _fail('Unknown argument: ${args[i]}');
    }
  }

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final packageRoot = scriptDir.parent.parent;
  final integrationAllDart = File(
    '${packageRoot.path}/../_integration_testing/lib/_generated/all.dart',
  );
  if (!integrationAllDart.existsSync()) {
    _fail(
      'Missing package:_integration_testing generated configs:\n'
      '  ${integrationAllDart.path}\n\n'
      'From packages/_integration_testing run:\n'
      '  dart run tool/generate_firebase_web_config.dart',
    );
  }

  const testFile = 'test/smoke';
  var dartArgs = ['test', '-t', 'smoke', '--run-skipped', testFile];

  if (runIo) {
    stdout.writeln('==> Running smoke tests on VM');
    await _runDart(dartArgs);
  }

  if (runChrome) {
    stdout.writeln('==> Running smoke tests on Chrome');
    final chromeArgs = <String>[
      ...dartArgs,
      '-p',
      'chrome',
      '--pause-after-load',
      '--concurrency=1'
    ];
    await _runDart(chromeArgs);
  }
}

Future<void> _runDart(List<String> args) async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    args,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  stderr.writeln('');
  _printUsage();
  exit(1);
}

void _printUsage() {
  stderr.writeln('Usage: dart run test/smoke/run.dart [options]');
  stderr.writeln('');
  stderr.writeln(
    'Requires generated configs in package:_integration_testing '
    '(see packages/_integration_testing README).',
  );
  stderr.writeln('');
  stderr.writeln('Options:');
  stderr.writeln('  --no-io          Skip VM smoke tests');
  stderr.writeln('  --no-chrome      Skip Chrome smoke tests');
  stderr.writeln('  -h, --help       Show this help');
}
