import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:firebase_management/firebase_management.dart';
import 'package:firebase_management/src/api.dart' show FirebaseApiException;
import 'package:googleapis/firebaseappcheck/v1.dart' as firebaseappcheck_v1;
import 'package:googleapis/identitytoolkit/v2.dart' as identitytoolkit_v2;
import 'package:googleapis/recaptchaenterprise/v1.dart'
    as recaptchaenterprise_v1;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:http/http.dart' as http;
import 'package:plist_parser/plist_parser.dart';

import 'package:_integration_testing/_integration_testing.dart'
    show PhoneAuthRecaptchaEnforcement;

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

  final credential = Credentials.applicationDefault();
  if (credential == null) {
    _fail(
      'No Application Default Credentials. Set GOOGLE_APPLICATION_CREDENTIALS '
      'or run gcloud auth application-default login.',
      parser,
    );
  }
  final firebaseManagement = FirebaseManagement(credential);

  final authClient = await clientViaApplicationDefaultCredentials(
    scopes: [
      FirebaseManagementApi.firebaseReadonlyScope,
      identitytoolkit_v2.IdentityToolkitApi.firebaseScope,
      // App Check Admin lists cloud-platform (and firebase); include both so ADC
      // tokens work under stricter org policies.
      firebaseappcheck_v1.FirebaseappcheckApi.cloudPlatformScope,
      firebaseappcheck_v1.FirebaseappcheckApi.firebaseScope,
    ],
  );
  try {
    final api = FirebaseManagementApi(authClient);

    if (selectedProjectId != null) {
      await _generateOneProject(
        api: api,
        authClient: authClient,
        firebaseManagement: firebaseManagement,
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
            authClient: authClient,
            firebaseManagement: firebaseManagement,
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
  required http.Client authClient,
  required FirebaseManagement firebaseManagement,
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
  final webOptions = _toWebFirebaseOptions(webConfig);
  final projectNumber = webOptions['messagingSenderId'];
  if (projectNumber == null || projectNumber.isEmpty) {
    stderr.writeln(
      'Warning: no messagingSenderId (project number) for "$projectId"; '
      'skipping getApnsAuthKey.',
    );
  }
  final androidOptions = await _loadAndroidOptionsByPackage(api, projectId);
  final iosOptions = await _loadIosOptionsByBundleId(api, projectId);
  final apnsBundles = projectNumber == null || projectNumber.isEmpty
      ? <String>[]
      : await _fetchIosBundleIdsWithApnsConfigured(
          firebaseManagement,
          projectNumber,
          projectId,
          iosOptions.keys,
        );

  final phoneRecaptcha = await _fetchPhoneAuthRecaptchaEnforcementForProject(
      authClient, projectId);

  final webFirebaseAppId = webOptions['appId'];
  final appCheckV3Configured = projectNumber == null ||
          projectNumber.isEmpty ||
          webFirebaseAppId == null ||
          webFirebaseAppId.isEmpty
      ? false
      : await _hasWebAppCheckRecaptchaV3Config(
          authClient,
          projectNumber,
          webFirebaseAppId,
          projectId,
        );
  final appCheckRecaptchaV3SiteKey = appCheckV3Configured
      ? await _lookupRecaptchaV3SiteKeyByDisplayName(authClient, projectId)
      : null;
  final appCheckRecaptchaEnterpriseSiteKey = projectNumber == null ||
          projectNumber.isEmpty ||
          webFirebaseAppId == null ||
          webFirebaseAppId.isEmpty
      ? null
      : await _fetchWebAppCheckRecaptchaEnterpriseSiteKey(
          authClient,
          projectNumber,
          webFirebaseAppId,
          projectId,
        );
  final appCheckDebugToken = projectNumber == null ||
          projectNumber.isEmpty ||
          webFirebaseAppId == null ||
          webFirebaseAppId.isEmpty
      ? null
      : await _ensureWebAppCheckDebugToken(
          authClient,
          projectNumber,
          webFirebaseAppId,
          projectId,
        );

  final outPath = '$outDir/${_sanitizeProjectId(projectId)}_options.g.dart';
  await _writeGeneratedOptionsFile(
    outPath: outPath,
    projectId: projectId,
    web: webOptions,
    androidByPackage: androidOptions,
    iosByBundleId: iosOptions,
    iosBundleIdsWithApnsConfigured: apnsBundles,
    phoneAuthRecaptchaEnforcement: phoneRecaptcha,
    webAppCheckRecaptchaV3SiteKey: appCheckRecaptchaV3SiteKey,
    webAppCheckRecaptchaEnterpriseSiteKey: appCheckRecaptchaEnterpriseSiteKey,
    webAppCheckDebugToken: appCheckDebugToken,
  );

  stdout.writeln(
    'Generated options for "$projectId" at $outPath '
    '(android: ${androidOptions.length}, ios: ${iosOptions.length}, '
    'apnsBundleIds: ${apnsBundles.length}, '
    'phoneRecaptcha: ${phoneRecaptcha.name}, '
    'appCheckV3: ${appCheckV3Configured ? "yes" : "no"}, '
    'appCheckV3SiteKey: ${appCheckRecaptchaV3SiteKey != null ? "yes" : "no"}, '
    'appCheckEnterpriseSiteKey: '
    '${appCheckRecaptchaEnterpriseSiteKey != null ? "yes" : "no"}, '
    'appCheckDebugToken: ${appCheckDebugToken != null ? "yes" : "no"})',
  );
}

/// [projectNumber] is the numeric GCP/Firebase project number (same as
/// `messagingSenderId` in app options). Mobile SDK PA expects this in the
/// `getApnsAuthKey` path, not the string [projectId].
Future<List<String>> _fetchIosBundleIdsWithApnsConfigured(
  FirebaseManagement firebaseManagement,
  String projectNumber,
  String projectId,
  Iterable<String> iosBundleIds,
) async {
  final configured = <String>{};
  for (final bundleId in iosBundleIds) {
    if (bundleId.isEmpty) continue;
    try {
      await firebaseManagement.apps.getApnsAuthKey(projectNumber, bundleId);
      configured.add(bundleId);
    } on FirebaseApiException catch (e) {
      if (e.status == 404) continue;
      stderr.writeln(
        'Warning: getApnsAuthKey "$bundleId" (project $projectId, '
        'number $projectNumber) → ${e.status} ${e.message} '
        '(not listed as APNs-configured).',
      );
    } catch (e, st) {
      stderr.writeln(
        'Warning: getApnsAuthKey "$bundleId" (project $projectId, '
        'number $projectNumber) failed: $e\n$st',
      );
    }
  }
  return configured.toList()..sort();
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
    ..writeln(
        '// GENERATED by _integration_testing/tool/generate_firebase_web_config.dart. Do not edit.')
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
    final response = await api.projects.androidApps
        .list('projects/$projectId', pageToken: pageToken);
    apps.addAll(response.apps ?? const []);
    pageToken = response.nextPageToken;
  } while (pageToken != null && pageToken.isNotEmpty);

  final byPackage = <String, Map<String, String>>{};
  for (final app in apps) {
    final appId = app.appId;
    final packageName = app.packageName;
    if (appId == null ||
        appId.isEmpty ||
        packageName == null ||
        packageName.isEmpty) {
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

Map<String, String>? _parseAndroidConfig(AndroidAppConfig config,
    {required String appId}) {
  final contents = config.configFileContents;
  if (contents == null || contents.isEmpty) return null;

  final decoded = utf8.decode(config.configFileContentsAsBytes);
  final json = jsonDecode(decoded) as Map<String, dynamic>;
  final clients =
      (json['client'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
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

  final projectInfo =
      (json['project_info'] as Map?)?.cast<String, dynamic>() ?? {};
  final apiKeys =
      (client['api_key'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final apiKey =
      apiKeys.isNotEmpty ? apiKeys.first['current_key']?.toString() : null;

  final options = <String, String>{};
  void setIf(String key, dynamic value) {
    final s = value?.toString();
    if (s != null && s.isNotEmpty) options[key] = s;
  }

  setIf('apiKey', apiKey);
  setIf('appId', appId);
  setIf('messagingSenderId', projectInfo['project_number']);
  setIf('projectId', projectInfo['project_id']);
  setIf('authDomain', projectInfo['auth_domain']);
  setIf('databaseURL', projectInfo['firebase_url']);
  setIf('storageBucket', projectInfo['storage_bucket']);
  _ensureAuthDomain(options);
  return _hasRequiredOptions(options) ? options : null;
}

Future<Map<String, Map<String, String>>> _loadIosOptionsByBundleId(
  FirebaseManagementApi api,
  String projectId,
) async {
  final apps = <IosApp>[];
  String? pageToken;
  do {
    final response = await api.projects.iosApps
        .list('projects/$projectId', pageToken: pageToken);
    apps.addAll(response.apps ?? const []);
    pageToken = response.nextPageToken;
  } while (pageToken != null && pageToken.isNotEmpty);

  final byBundleId = <String, Map<String, String>>{};
  for (final app in apps) {
    final appId = app.appId;
    final bundleId = app.bundleId;
    if (appId == null ||
        appId.isEmpty ||
        bundleId == null ||
        bundleId.isEmpty) {
      continue;
    }

    final config = await api.projects.iosApps
        .getConfig('projects/$projectId/iosApps/$appId/config');
    final parsed = _parseIosConfig(config, appId: appId);
    if (parsed != null) {
      byBundleId[bundleId] = parsed;
    }
  }
  return byBundleId;
}

Map<String, String>? _parseIosConfig(IosAppConfig config,
    {required String appId}) {
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
  setIf('authDomain', plist['AUTH_DOMAIN']);
  setIf('databaseURL', plist['DATABASE_URL']);
  setIf('storageBucket', plist['STORAGE_BUCKET']);
  setIf('iosClientId', plist['CLIENT_ID']);
  _ensureAuthDomain(options);
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
  _ensureAuthDomain(options);
  return options;
}

bool _hasRequiredOptions(Map<String, String> options) {
  return options.containsKey('apiKey') &&
      options.containsKey('appId') &&
      options.containsKey('messagingSenderId') &&
      options.containsKey('projectId');
}

/// Mobile config files often omit auth domain; match web default
/// (`<projectId>.firebaseapp.com`) so generated literals include [authDomain].
void _ensureAuthDomain(Map<String, String> options) {
  if (options.containsKey('authDomain')) return;
  final pid = options['projectId'];
  if (pid != null && pid.isNotEmpty) {
    options['authDomain'] = '$pid.firebaseapp.com';
  }
}

String _sanitizeProjectId(String projectId) =>
    projectId.replaceAll(RegExp('[^a-zA-Z0-9_]'), '_');

Future<void> _writeGeneratedOptionsFile({
  required String outPath,
  required String projectId,
  required Map<String, String> web,
  required Map<String, Map<String, String>> androidByPackage,
  required Map<String, Map<String, String>> iosByBundleId,
  required List<String> iosBundleIdsWithApnsConfigured,
  required PhoneAuthRecaptchaEnforcement phoneAuthRecaptchaEnforcement,
  required String? webAppCheckRecaptchaV3SiteKey,
  required String? webAppCheckRecaptchaEnterpriseSiteKey,
  required String? webAppCheckDebugToken,
}) async {
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  final buffer = StringBuffer()
    ..writeln(
        '// GENERATED by _integration_testing/tool/generate_firebase_web_config.dart. Do not edit.')
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
    buffer.writeln(
        "  '${_escape(entry.key)}': ${_firebaseOptionsLiteral(entry.value)},");
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('const Map<String, FirebaseOptions> ios = {');
  for (final entry in iosByBundleId.entries) {
    buffer.writeln(
        "  '${_escape(entry.key)}': ${_firebaseOptionsLiteral(entry.value)},");
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('const FirebaseProjectConfig config = FirebaseProjectConfig(')
    ..writeln("  projectId: '$projectId',")
    ..writeln('  webConfig: web,')
    ..writeln('  iosConfigs: ios,')
    ..writeln('  androidConfigs: android,')
    ..writeln(
      '  phoneAuthRecaptchaEnforcement: '
      '${_phoneAuthRecaptchaEnforcementLiteral(phoneAuthRecaptchaEnforcement)},',
    );
  if (webAppCheckRecaptchaV3SiteKey != null &&
      webAppCheckRecaptchaV3SiteKey.isNotEmpty) {
    buffer.writeln(
      "  webAppCheckRecaptchaV3SiteKey: '${_escape(webAppCheckRecaptchaV3SiteKey)}',",
    );
  }
  if (webAppCheckRecaptchaEnterpriseSiteKey != null &&
      webAppCheckRecaptchaEnterpriseSiteKey.isNotEmpty) {
    buffer.writeln(
      "  webAppCheckRecaptchaEnterpriseSiteKey: '${_escape(webAppCheckRecaptchaEnterpriseSiteKey)}',",
    );
  }
  if (webAppCheckDebugToken != null && webAppCheckDebugToken.isNotEmpty) {
    buffer.writeln(
      "  webAppCheckDebugToken: '${_escape(webAppCheckDebugToken)}',",
    );
  }
  buffer.writeln('  iosBundleIdsWithApnsConfigured: <String>[');
  for (final id in iosBundleIdsWithApnsConfigured) {
    buffer.writeln("    '${_escape(id)}',");
  }
  buffer.writeln('  ],');
  buffer.writeln(');');

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

String get _debugTokenSecretsPath =>
    '$_generatedDir/app_check_debug_token_secrets.json';

String _debugTokenCacheKey(String projectNumber, String firebaseWebAppId) =>
    '$projectNumber:$firebaseWebAppId';

Map<String, String> _readDebugTokenSecrets() {
  final file = File(_debugTokenSecretsPath);
  if (!file.existsSync()) return {};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) return {};
    return decoded.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
  } catch (e) {
    stderr.writeln('Warning: could not read $_debugTokenSecretsPath: $e');
    return {};
  }
}

void _writeDebugTokenSecrets(Map<String, String> secrets) {
  final file = File(_debugTokenSecretsPath);
  file.parent.createSync(recursive: true);
  final sorted = Map.fromEntries(
    secrets.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sorted));
}

String _generateUuidV4() {
  final random = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => random.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Returns a registered App Check debug secret for the web app, creating one if needed.
Future<String?> _ensureWebAppCheckDebugToken(
  http.Client authClient,
  String projectNumber,
  String firebaseWebAppId,
  String projectId,
) async {
  final cacheKey = _debugTokenCacheKey(projectNumber, firebaseWebAppId);
  final secrets = _readDebugTokenSecrets();
  final cached = secrets[cacheKey];
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  final token = _generateUuidV4();
  final api = firebaseappcheck_v1.FirebaseappcheckApi(authClient);
  final parent = 'projects/$projectNumber/apps/$firebaseWebAppId';
  try {
    await api.projects.apps.debugTokens.create(
      firebaseappcheck_v1.GoogleFirebaseAppcheckV1DebugToken()
        ..displayName = 'integration-smoke'
        ..token = token,
      parent,
    );
    secrets[cacheKey] = token;
    _writeDebugTokenSecrets(secrets);
    stdout.writeln(
      'Registered App Check debug token for "$projectId" web app '
      '"$firebaseWebAppId" (stored in app_check_debug_token_secrets.json).',
    );
    return token;
  } on firebaseappcheck_v1.DetailedApiRequestError catch (e) {
    stderr.writeln(
      'Warning: could not create App Check debug token for "$projectId" '
      'web app "$firebaseWebAppId": ${e.status} ${e.message}',
    );
    return null;
  } catch (e, st) {
    stderr.writeln(
      'Warning: App Check debug token setup for "$projectId" failed: $e\n$st',
    );
    return null;
  }
}

/// Whether App Check reCAPTCHA v3 config exists for the web app.
///
/// [firebaseWebAppId] must be the app id from [WebAppConfig.appId] (same as
/// `FirebaseOptions.appId`, e.g. `1:123:web:abc`), not an opaque management id.
///
/// reCAPTCHA **v3** App Check stores only a secret server-side (`siteSecret`);
/// the Admin API never returns a public site key.
Future<bool> _hasWebAppCheckRecaptchaV3Config(
  http.Client authClient,
  String projectNumber,
  String firebaseWebAppId,
  String projectId,
) async {
  final api = firebaseappcheck_v1.FirebaseappcheckApi(authClient);
  final v3Name =
      'projects/$projectNumber/apps/$firebaseWebAppId/recaptchaV3Config';
  try {
    final v3 = await api.projects.apps.recaptchaV3Config.get(v3Name);
    if (v3.siteSecretSet == true) {
      return true;
    }
    stderr.writeln(
      'Note: App Check reCAPTCHA v3 config exists for "$projectId" web app '
      '"$firebaseWebAppId", but site_secret is not set.',
    );
    return false;
  } on firebaseappcheck_v1.DetailedApiRequestError catch (e) {
    if (e.status == 404) {
      stderr.writeln(
        'Note: no App Check reCAPTCHA v3 config for web app '
        '"$firebaseWebAppId" in "$projectId".',
      );
      return false;
    }
    stderr.writeln(
      'Warning: App Check recaptchaV3Config.get("$v3Name") '
      'for project "$projectId" failed: ${e.status} ${e.message}',
    );
    return false;
  } catch (e, st) {
    stderr.writeln(
      'Warning: App Check recaptchaV3Config for project '
      '"$projectId" failed: $e\n$st',
    );
    return false;
  }
}

Future<String?> _fetchWebAppCheckRecaptchaEnterpriseSiteKey(
  http.Client authClient,
  String projectNumber,
  String firebaseWebAppId,
  String projectId,
) async {
  final api = firebaseappcheck_v1.FirebaseappcheckApi(authClient);
  final name =
      'projects/$projectNumber/apps/$firebaseWebAppId/recaptchaEnterpriseConfig';
  try {
    final cfg = await api.projects.apps.recaptchaEnterpriseConfig.get(name);
    final key = cfg.siteKey?.trim();
    if (key == null || key.isEmpty) return null;
    return key;
  } on firebaseappcheck_v1.DetailedApiRequestError catch (e) {
    if (e.status == 404) return null;
    stderr.writeln(
      'Warning: App Check recaptchaEnterpriseConfig.get("$name") for '
      'project "$projectId" failed: ${e.status} ${e.message}',
    );
    return null;
  } catch (e, st) {
    stderr.writeln(
      'Warning: App Check recaptchaEnterpriseConfig for project '
      '"$projectId" failed: $e\n$st',
    );
    return null;
  }
}

/// Looks up reCAPTCHA keys and returns the site key for the web key named
/// exactly `Firebase AppCheck`.
///
/// We use this because App Check reCAPTCHA v3 config does not expose a public
/// site key; only `siteSecretSet` is returned by the App Check Admin API.
Future<String?> _lookupRecaptchaV3SiteKeyByDisplayName(
  http.Client authClient,
  String projectId,
) async {
  final api = recaptchaenterprise_v1.RecaptchaEnterpriseApi(authClient);
  const targetDisplayName = 'Firebase AppCheck';
  String? pageToken;
  try {
    do {
      final response = await api.projects.keys.list(
        'projects/$projectId',
        pageSize: 1000,
        pageToken: pageToken,
      );
      for (final key in response.keys ?? const []) {
        if (key.displayName != targetDisplayName) continue;
        if (key.webSettings == null) continue;
        final name = key.name;
        if (name == null || name.isEmpty) continue;
        final slash = name.lastIndexOf('/');
        if (slash < 0 || slash == name.length - 1) continue;
        return name.substring(slash + 1).trim();
      }
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);
  } on recaptchaenterprise_v1.DetailedApiRequestError catch (e) {
    stderr.writeln(
      'Warning: recaptchaenterprise keys.list("projects/$projectId") failed: '
      '${e.status} ${e.message}',
    );
  } catch (e, st) {
    stderr.writeln(
      'Warning: recaptchaenterprise keys lookup for "$projectId" failed: '
      '$e\n$st',
    );
  }
  stderr.writeln(
    'Note: no reCAPTCHA key named "$targetDisplayName" found in "$projectId".',
  );
  return null;
}

Future<PhoneAuthRecaptchaEnforcement>
    _fetchPhoneAuthRecaptchaEnforcementForProject(
  http.Client authClient,
  String projectId,
) async {
  final toolkit = identitytoolkit_v2.IdentityToolkitApi(authClient);
  try {
    final config = await toolkit.projects.getConfig(
      'projects/$projectId/config',
    );
    return _phoneEnforcementFromProjectConfig(config);
  } on identitytoolkit_v2.DetailedApiRequestError catch (e) {
    stderr.writeln(
      'Warning: Identity Toolkit getConfig("projects/$projectId/config") '
      'failed: ${e.status} ${e.message}',
    );
    return PhoneAuthRecaptchaEnforcement.unknown;
  } catch (e, st) {
    stderr.writeln(
      'Warning: Identity Toolkit getConfig("projects/$projectId/config") '
      'failed: $e\n$st',
    );
    return PhoneAuthRecaptchaEnforcement.unknown;
  }
}

PhoneAuthRecaptchaEnforcement _phoneEnforcementFromProjectConfig(
  identitytoolkit_v2.GoogleCloudIdentitytoolkitAdminV2Config config,
) {
  final state = config.recaptchaConfig?.phoneEnforcementState;
  return _phoneAuthRecaptchaEnforcementFromAdminApi(state);
}

PhoneAuthRecaptchaEnforcement _phoneAuthRecaptchaEnforcementFromAdminApi(
  String? api,
) {
  switch (api) {
    case 'ENFORCE':
      return PhoneAuthRecaptchaEnforcement.enforce;
    case 'AUDIT':
      return PhoneAuthRecaptchaEnforcement.audit;
    case 'OFF':
      return PhoneAuthRecaptchaEnforcement.off;
    case 'RECAPTCHA_PROVIDER_ENFORCEMENT_STATE_UNSPECIFIED':
    case null:
      return PhoneAuthRecaptchaEnforcement.unspecified;
    default:
      return PhoneAuthRecaptchaEnforcement.unknown;
  }
}

String _phoneAuthRecaptchaEnforcementLiteral(
  PhoneAuthRecaptchaEnforcement value,
) =>
    'PhoneAuthRecaptchaEnforcement.${value.name}';

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
