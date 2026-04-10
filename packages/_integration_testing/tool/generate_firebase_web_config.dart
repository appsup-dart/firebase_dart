import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:plist_parser/plist_parser.dart';

/// Output directory for generated options (fixed; relative to this package).
String get _generatedDir {
  final toolDir = File(Platform.script.toFilePath()).parent;
  final packageRoot = toolDir.parent;
  return '${packageRoot.path}/lib/_generated';
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'project',
      help: 'Generate only for this Firebase project id',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help',
    );

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } on ArgParserException catch (e) {
    _fail(e.message, parser);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    return;
  }

  final selectedProjectId = results['project'] as String?;
  final outDir = _generatedDir;

  final authClient = await clientViaApplicationDefaultCredentials(
    scopes: [FirebaseManagementApi.firebaseReadonlyScope],
  );
  try {
    final api = FirebaseManagementApi(authClient);

    if (selectedProjectId != null) {
      await _generateOneProject(
        api: api,
        outDir: outDir,
        projectId: selectedProjectId,
        parser: parser,
      );
    } else {
      final projectIds = _projectIdsFromExistingOptionsFiles(outDir);
      if (projectIds.isEmpty) {
        stdout.writeln(
          'No *_options.g.dart files in lib/_generated. '
          'Add one with --project <id> first, or create files manually.',
        );
      } else {
        for (final projectId in projectIds) {
          await _generateOneProject(
            api: api,
            outDir: outDir,
            projectId: projectId,
            parser: parser,
            allowSkip: true,
          );
        }
      }
    }

    await _writeAllConfigsFileFromDir(outDir);
    stdout.writeln('Wrote $outDir/all.dart');
  } finally {
    authClient.close();
  }
}

/// Reads [outDir] for `*_options.g.dart` and returns unique project ids from
/// `// projectId: ...` headers (stable sorted order).
List<String> _projectIdsFromExistingOptionsFiles(String outDir) {
  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    return [];
  }

  final ids = <String>{};
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.endsWith('_options.g.dart')) continue;

    final id = _readProjectIdHeader(entity);
    if (id != null && id.isNotEmpty) {
      ids.add(id);
    } else {
      stderr.writeln('Warning: skip "$name" (no // projectId: header)');
    }
  }

  final list = ids.toList()..sort();
  return list;
}

final _projectIdHeader = RegExp(r'^// projectId:\s*(.+)\s*$');

String? _readProjectIdHeader(File file) {
  final lines = file.readAsLinesSync();
  for (final line in lines.take(20)) {
    final m = _projectIdHeader.firstMatch(line);
    if (m != null) {
      return m.group(1)!.trim();
    }
  }
  return null;
}

Future<void> _generateOneProject({
  required FirebaseManagementApi api,
  required String outDir,
  required String projectId,
  required ArgParser parser,
  bool allowSkip = false,
}) async {
  final webApps = await _listWebApps(api, projectId);
  if (webApps.isEmpty) {
    final msg = 'No web app found for project "$projectId".';
    if (allowSkip) {
      stdout.writeln('Skipping "$projectId": $msg');
      return;
    }
    _fail(msg, parser);
  }
  final webApp = webApps.first;
  if (webApp.appId == null || webApp.appId!.isEmpty) {
    final msg = 'Web app has no appId for project "$projectId".';
    if (allowSkip) {
      stdout.writeln('Skipping "$projectId": $msg');
      return;
    }
    _fail(msg, parser);
  }

  final webConfig = await api.projects.webApps
      .getConfig('projects/$projectId/webApps/${webApp.appId}/config');
  final androidOptions = await _loadAndroidOptionsByPackage(api, projectId);
  final iosOptions = await _loadIosOptionsByBundleId(api, projectId);

  final outPath = '$outDir/${_sanitizeProjectId(projectId)}_options.g.dart';
  await _writeGeneratedOptionsFile(
    outPath: outPath,
    projectId: projectId,
    web: _toWebFirebaseOptions(webConfig),
    androidByPackage: androidOptions,
    iosByBundleId: iosOptions,
  );

  stdout.writeln(
    'Generated options for "$projectId" at $outPath '
    '(android: ${androidOptions.length}, ios: ${iosOptions.length})',
  );
}

Future<void> _writeAllConfigsFileFromDir(String outDir) async {
  final dir = Directory(outDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final basenames = <String>[];
  for (final entity in dir.listSync()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (name == 'all.dart') continue;
    if (name.endsWith('_options.g.dart')) {
      basenames.add(name);
    }
  }
  basenames.sort();

  final file = File('$outDir/all.dart');
  final buffer = StringBuffer()
    ..writeln('// GENERATED by _integration_testing/tool/generate_firebase_web_config.dart. Do not edit.')
    ..writeln('// ignore_for_file: prefer_single_quotes')
    ..writeln()
    ..writeln("import '../_integration_testing.dart';");
  for (var i = 0; i < basenames.length; i++) {
    buffer.writeln("import '${basenames[i]}' as p$i;");
  }
  buffer
    ..writeln()
    ..writeln('const List<FirebaseProjectConfig> allConfigs = [');
  for (var i = 0; i < basenames.length; i++) {
    buffer.writeln('  p$i.config,');
  }
  buffer.writeln('];');

  await file.writeAsString(buffer.toString());
}

Future<List<WebApp>> _listWebApps(
  FirebaseManagementApi api,
  String projectId,
) async {
  final apps = <WebApp>[];
  String? pageToken;
  do {
    final response = await api.projects.webApps.list(
      'projects/$projectId',
      pageToken: pageToken,
    );
    apps.addAll(response.apps ?? const []);
    pageToken = response.nextPageToken;
  } while (pageToken != null && pageToken.isNotEmpty);
  return apps;
}

Future<Map<String, Map<String, String>>> _loadAndroidOptionsByPackage(
  FirebaseManagementApi api,
  String projectId,
) async {
  final apps = <AndroidApp>[];
  String? pageToken;
  do {
    final response =
        await api.projects.androidApps.list('projects/$projectId', pageToken: pageToken);
    apps.addAll(response.apps ?? const []);
    pageToken = response.nextPageToken;
  } while (pageToken != null && pageToken.isNotEmpty);

  final byPackage = <String, Map<String, String>>{};
  for (final app in apps) {
    final appId = app.appId;
    final packageName = app.packageName;
    if (appId == null || appId.isEmpty || packageName == null || packageName.isEmpty) {
      continue;
    }

    final config = await api.projects.androidApps
        .getConfig('projects/$projectId/androidApps/$appId/config');
    final parsed = _parseAndroidConfig(config, appId: appId);
    if (parsed != null) {
      byPackage[packageName] = parsed;
    }
  }
  return byPackage;
}

Map<String, String>? _parseAndroidConfig(AndroidAppConfig config, {required String appId}) {
  final contents = config.configFileContents;
  if (contents == null || contents.isEmpty) return null;

  final decoded = utf8.decode(config.configFileContentsAsBytes);
  final json = jsonDecode(decoded) as Map<String, dynamic>;
  final clients = (json['client'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  Map<String, dynamic>? client;
  for (final c in clients) {
    final cid = (c['client_info'] as Map?)?['mobilesdk_app_id'];
    if (cid == appId) {
      client = c;
      break;
    }
  }
  client ??= clients.isNotEmpty ? clients.first : null;
  if (client == null) return null;

  final projectInfo = (json['project_info'] as Map?)?.cast<String, dynamic>() ?? {};
  final apiKeys = (client['api_key'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final apiKey = apiKeys.isNotEmpty ? apiKeys.first['current_key']?.toString() : null;

  final options = <String, String>{};
  void setIf(String key, dynamic value) {
    final s = value?.toString();
    if (s != null && s.isNotEmpty) options[key] = s;
  }

  setIf('apiKey', apiKey);
  setIf('appId', appId);
  setIf('messagingSenderId', projectInfo['project_number']);
  setIf('projectId', projectInfo['project_id']);
  setIf('databaseURL', projectInfo['firebase_url']);
  setIf('storageBucket', projectInfo['storage_bucket']);
  return _hasRequiredOptions(options) ? options : null;
}

Future<Map<String, Map<String, String>>> _loadIosOptionsByBundleId(
  FirebaseManagementApi api,
  String projectId,
) async {
  final apps = <IosApp>[];
  String? pageToken;
  do {
    final response =
        await api.projects.iosApps.list('projects/$projectId', pageToken: pageToken);
    apps.addAll(response.apps ?? const []);
    pageToken = response.nextPageToken;
  } while (pageToken != null && pageToken.isNotEmpty);

  final byBundleId = <String, Map<String, String>>{};
  for (final app in apps) {
    final appId = app.appId;
    final bundleId = app.bundleId;
    if (appId == null || appId.isEmpty || bundleId == null || bundleId.isEmpty) {
      continue;
    }

    final config =
        await api.projects.iosApps.getConfig('projects/$projectId/iosApps/$appId/config');
    final parsed = _parseIosConfig(config, appId: appId);
    if (parsed != null) {
      byBundleId[bundleId] = parsed;
    }
  }
  return byBundleId;
}

Map<String, String>? _parseIosConfig(IosAppConfig config, {required String appId}) {
  final contents = config.configFileContents;
  if (contents == null || contents.isEmpty) return null;
  final decoded = utf8.decode(config.configFileContentsAsBytes);
  final plist = PlistParser().parse(decoded).cast<String, dynamic>();

  final options = <String, String>{};
  void setIf(String key, dynamic value) {
    final s = value?.toString();
    if (s != null && s.isNotEmpty) options[key] = s;
  }

  setIf('apiKey', plist['API_KEY']);
  setIf('appId', appId);
  setIf('messagingSenderId', plist['GCM_SENDER_ID']);
  setIf('projectId', plist['PROJECT_ID']);
  setIf('databaseURL', plist['DATABASE_URL']);
  setIf('storageBucket', plist['STORAGE_BUCKET']);
  setIf('iosClientId', plist['CLIENT_ID']);
  return _hasRequiredOptions(options) ? options : null;
}

Map<String, String> _toWebFirebaseOptions(WebAppConfig config) {
  final options = <String, String>{};
  void setIf(String key, dynamic value) {
    final s = value?.toString();
    if (s != null && s.isNotEmpty) options[key] = s;
  }

  setIf('apiKey', config.apiKey);
  setIf('appId', config.appId);
  setIf('messagingSenderId', config.messagingSenderId);
  setIf('projectId', config.projectId);
  setIf('authDomain', config.authDomain);
  // ignore: deprecated_member_use
  setIf('databaseURL', config.databaseURL);
  // ignore: deprecated_member_use
  setIf('storageBucket', config.storageBucket);
  setIf('measurementId', config.measurementId);
  return options;
}

bool _hasRequiredOptions(Map<String, String> options) {
  return options.containsKey('apiKey') &&
      options.containsKey('appId') &&
      options.containsKey('messagingSenderId') &&
      options.containsKey('projectId');
}

String _sanitizeProjectId(String projectId) =>
    projectId.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');

Future<void> _writeGeneratedOptionsFile({
  required String outPath,
  required String projectId,
  required Map<String, String> web,
  required Map<String, Map<String, String>> androidByPackage,
  required Map<String, Map<String, String>> iosByBundleId,
}) async {
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  final buffer = StringBuffer()
    ..writeln('// GENERATED by _integration_testing/tool/generate_firebase_web_config.dart. Do not edit.')
    ..writeln('// ignore_for_file: prefer_single_quotes')
    ..writeln('// projectId: $projectId')
    ..writeln()
    ..writeln("import 'package:firebase_dart/core.dart';")
    ..writeln("import '../_integration_testing.dart';")
    ..writeln()
    ..writeln('const FirebaseOptions web = ${_firebaseOptionsLiteral(web)};')
    ..writeln()
    ..writeln('const Map<String, FirebaseOptions> android = {');
  for (final entry in androidByPackage.entries) {
    buffer.writeln("  '${_escape(entry.key)}': ${_firebaseOptionsLiteral(entry.value)},");
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('const Map<String, FirebaseOptions> ios = {');
  for (final entry in iosByBundleId.entries) {
    buffer.writeln("  '${_escape(entry.key)}': ${_firebaseOptionsLiteral(entry.value)},");
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('const FirebaseProjectConfig config = FirebaseProjectConfig(')
    ..writeln("  projectId: '$projectId',")
    ..writeln('  webConfig: web,')
    ..writeln('  iosConfigs: ios,')
    ..writeln('  androidConfigs: android,')
    ..writeln(');');

  await file.writeAsString(buffer.toString());
}

String _firebaseOptionsLiteral(Map<String, String> options) {
  final b = StringBuffer()..writeln('FirebaseOptions(');
  void add(String name, {bool required = false}) {
    final value = options[name];
    if (value == null) {
      if (required) {
        throw StateError('Missing required FirebaseOptions field: $name');
      }
      return;
    }
    b.writeln("  $name: '${_escape(value)}',");
  }

  add('apiKey', required: true);
  add('appId', required: true);
  add('messagingSenderId', required: true);
  add('projectId', required: true);
  add('authDomain');
  add('databaseURL');
  add('storageBucket');
  add('measurementId');
  add('trackingId');
  add('deepLinkURLScheme');
  add('androidClientId');
  add('iosClientId');
  add('iosBundleId');
  add('appGroupId');
  b.write(')');
  return b.toString();
}

String _escape(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

Never _fail(String message, ArgParser parser) {
  stderr.writeln(message);
  stderr.writeln('');
  _printUsage(parser);
  exit(1);
}

void _printUsage(ArgParser parser) {
  stderr.writeln(
      'Usage: dart run tool/generate_firebase_web_config.dart [options]');
  stderr.writeln('');
  stderr.writeln('Writes to package lib/_generated/ (see README).');
  stderr.writeln('');
  stderr.writeln(parser.usage);
}
