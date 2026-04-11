// Injects Firebase Auth custom URL schemes into the built iOS/macOS Info.plist.
//
// The same `app-{GOOGLE_APP_ID}` scheme is required for phone auth reCAPTCHA
// redirect and for OAuth sign-in (e.g. Microsoft) when using the Firebase SDK on
// Apple platforms. See:
// https://firebase.google.com/docs/auth/ios/microsoft-oauth#handle_the_sign-in_flow_with_the_firebase_sdk
//
// Uses [allConfigs] from `package:_integration_testing` and
// [FirebaseOptions.firebaseAuthCustomUrlScheme] on each matching iOS
// [FirebaseOptions].
//
// Environment variables are documented on [XcodeBuildEnvironment].
//
// Run from the example package root (needs `dart pub get`):
//   dart run tool/add_firebase_auth_url_schemes.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:_integration_testing/_integration_testing.dart';
import 'package:firebase_dart/core.dart';
import 'package:propertylistserialization/propertylistserialization.dart';

/// Xcode run-script / build environment: the same keys [Platform.environment]
/// exposes to any iOS or macOS build phase.
///
/// Getters for standard Xcode variables apply to every Run Script. Optional
/// project-defined keys ([firebaseIntegrationLookupBundleId], …) are conventions
/// used by this repository’s tooling; other scripts can read the same names.
extension type XcodeBuildEnvironment(Map<String, String> _env) {
  XcodeBuildEnvironment.fromPlatform() : _env = Platform.environment;

  /// `BUILT_PRODUCTS_DIR`: directory that contains the built `.app` (or macOS
  /// bundle) for the active configuration (e.g. Debug-iphoneos).
  String? get builtProductsDir => _nonEmpty(_env['BUILT_PRODUCTS_DIR']);

  /// `FULL_PRODUCT_NAME`: built product filename (e.g. `Runner.app`).
  String? get fullProductName => _nonEmpty(_env['FULL_PRODUCT_NAME']);

  /// `WRAPPER_NAME`: alternate name for the product wrapper; used when
  /// [fullProductName] is unset (some targets export this instead).
  String? get wrapperName => _nonEmpty(_env['WRAPPER_NAME']);

  /// Prefer [fullProductName], then [wrapperName], for the bundle directory name
  /// under [builtProductsDir].
  String? get builtProductOrWrapperName =>
      fullProductName ?? wrapperName;

  /// Optional project var: bundle id override when matching
  /// `package:_integration_testing` [allConfigs]. When empty,
  /// [productBundleIdentifier] is used instead.
  String get firebaseIntegrationLookupBundleId =>
      (_env['FIREBASE_INTEGRATION_LOOKUP_BUNDLE_ID'] ?? '').trim();

  /// `PRODUCT_BUNDLE_IDENTIFIER` for this target (e.g. `com.example.app`).
  String get productBundleIdentifier =>
      (_env['PRODUCT_BUNDLE_IDENTIFIER'] ?? '').trim();

  /// Optional project var: when non-empty, only [allConfigs] entries with this
  /// Firebase `projectId` are considered (e.g. when deriving URL schemes).
  String get firebaseIntegrationProjectId =>
      (_env['FIREBASE_INTEGRATION_PROJECT_ID'] ?? '').trim();

  /// Optional project var `ADD_FIREBASE_AUTH_URL_SCHEMES_REPORT_PATH`: explicit
  /// path for a text report. When empty, callers may default under
  /// [targetTempDir].
  String get addFirebaseAuthUrlSchemesReportPath =>
      (_env['ADD_FIREBASE_AUTH_URL_SCHEMES_REPORT_PATH'] ?? '').trim();

  /// `TARGET_TEMP_DIR`: per-target temp directory; Xcode sets this for every
  /// Run Script (scratch files, default report locations, etc.).
  String get targetTempDir => (_env['TARGET_TEMP_DIR'] ?? '').trim();

  static String? _nonEmpty(String? value) {
    final s = (value ?? '').trim();
    return s.isEmpty ? null : s;
  }
}

/// Firebase Auth [custom URL scheme](https://firebase.google.com/docs/auth/ios/microsoft-oauth#handle_the_sign-in_flow_with_the_firebase_sdk)
/// on iOS / macOS (`app-` plus [appId] with `:` → `-`).
///
/// Used for OAuth redirects (Microsoft, Apple, etc.) and phone auth reCAPTCHA
/// return URLs.
extension FirebaseOptionsFirebaseAuthUrlScheme on FirebaseOptions {
  String get firebaseAuthCustomUrlScheme =>
      'app-${appId.replaceAll(':', '-')}';
}

/// Info.plist root as a [Map] (binary or XML plist on disk).
extension InfoPlist on Map<String, Object> {
  /// Reads [file] as a plist and returns the root as a string-keyed map, or null.
  static Map<String, Object>? readFromFile(File file) {
    final bytes = file.readAsBytesSync();
    final Object decoded;
    if (bytes.length >= 8) {
      final head = String.fromCharCodes(bytes.sublist(0, 8));
      if (head == 'bplist00') {
        decoded = PropertyListSerialization.propertyListWithData(
          ByteData.sublistView(bytes),
        );
      } else {
        decoded =
            PropertyListSerialization.propertyListWithString(utf8.decode(bytes));
      }
    } else {
      decoded =
          PropertyListSerialization.propertyListWithString(utf8.decode(bytes));
    }
    if (decoded is! Map) {
      return null;
    }
    return Map<String, Object>.from(
      decoded.map(
        (k, v) => MapEntry(k.toString(), v as Object),
      ),
    );
  }

  bool hasUrlScheme(String scheme) {
    final types = this['CFBundleURLTypes'];
    if (types is! List) {
      return false;
    }
    for (final entry in types) {
      if (entry is! Map) {
        continue;
      }
      final schemes = entry['CFBundleURLSchemes'];
      if (schemes is! List) {
        continue;
      }
      for (final s in schemes) {
        if (s == scheme) {
          return true;
        }
      }
    }
    return false;
  }

  void appendUrlType(String bundleId, String scheme) {
    final entry = <String, Object>{
      'CFBundleTypeRole': 'Editor',
      'CFBundleURLName': bundleId,
      'CFBundleURLSchemes': <Object>[scheme],
    };
    final raw = this['CFBundleURLTypes'];
    if (raw == null) {
      this['CFBundleURLTypes'] = <Object>[entry];
    } else if (raw is List) {
      this['CFBundleURLTypes'] = <Object>[...raw, entry];
    } else {
      this['CFBundleURLTypes'] = <Object>[raw, entry];
    }
  }

  void writeBinaryPlistTo(File file) {
    final data = PropertyListSerialization.dataWithPropertyList(this);
    final out = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    file.writeAsBytesSync(out);
  }
}

void main(List<String> args) {
  exitCode = _main();
}

int _main() {
  final buildEnv = XcodeBuildEnvironment.fromPlatform();
  final built = buildEnv.builtProductsDir;
  final fullName = buildEnv.builtProductOrWrapperName;
  if (built == null) {
    stderr.writeln('add_firebase_auth_url_schemes: missing BUILT_PRODUCTS_DIR');
    return 0;
  }
  if (fullName == null) {
    stderr.writeln(
      'add_firebase_auth_url_schemes: missing FULL_PRODUCT_NAME or WRAPPER_NAME',
    );
    return 0;
  }

  final lookupOverride = buildEnv.firebaseIntegrationLookupBundleId;
  final lookupBundle = lookupOverride.isNotEmpty
      ? lookupOverride
      : buildEnv.productBundleIdentifier;
  if (lookupBundle.isEmpty) {
    stderr.writeln(
      'add_firebase_auth_url_schemes: no FIREBASE_INTEGRATION_LOOKUP_BUNDLE_ID '
      'or PRODUCT_BUNDLE_IDENTIFIER',
    );
    return 0;
  }

  final projectFilter = buildEnv.firebaseIntegrationProjectId;
  final schemes = distinctFirebaseAuthCustomUrlSchemesForIosBundle(
    lookupBundle,
    projectFilter,
  );
  if (schemes.isEmpty) {
    stderr.writeln(
      'add_firebase_auth_url_schemes: no ios FirebaseOptions for bundle '
      "'$lookupBundle' in package:_integration_testing allConfigs"
      '${projectFilter.isNotEmpty ? " (project filter '$projectFilter')" : ""}',
    );
    return 0;
  }

  final bundle = Directory('$built${Platform.pathSeparator}$fullName');
  final appPlist = infoPlistInBundle(bundle);
  if (appPlist == null) {
    stderr.writeln(
      'add_firebase_auth_url_schemes: no Info.plist under ${bundle.path}',
    );
    return 0;
  }

  final root = InfoPlist.readFromFile(appPlist);
  if (root == null) {
    stderr.writeln('add_firebase_auth_url_schemes: root plist is not a map');
    return 1;
  }

  final report = <String>[
    'add_firebase_auth_url_schemes — report',
    'lookup_bundle=$lookupBundle',
    'configs=package:_integration_testing allConfigs',
    'info_plist=${appPlist.path}',
    'derived schemes:',
    ...schemes.map((s) => '  $s'),
  ];

  final addedNames = <String>[];
  final skippedNames = <String>[];
  for (final scheme in schemes) {
    if (root.hasUrlScheme(scheme)) {
      skippedNames.add(scheme);
      stdout.writeln(
        'add_firebase_auth_url_schemes: SKIP (already in Info.plist): $scheme',
      );
      report.add('status: SKIP $scheme');
    } else {
      root.appendUrlType(lookupBundle, scheme);
      addedNames.add(scheme);
      stdout.writeln('add_firebase_auth_url_schemes: ADDED $scheme');
      report.add('status: ADDED $scheme');
    }
  }

  if (addedNames.isNotEmpty) {
    root.writeBinaryPlistTo(appPlist);
  }

  stdout.writeln(
    'add_firebase_auth_url_schemes: summary — added ${addedNames.length}, '
    'skipped ${skippedNames.length} (already present), '
    "lookup_bundle='$lookupBundle'",
  );
  stdout.writeln(
    'add_firebase_auth_url_schemes: edited plist — ${appPlist.path}',
  );

  report.add('');
  report.add(
    'summary: added=${addedNames.length}, skipped=${skippedNames.length}',
  );
  if (addedNames.isNotEmpty) {
    report.add('added:');
    for (final s in addedNames) {
      report.add('  $s');
    }
  }
  if (skippedNames.isNotEmpty) {
    report.add('already_present:');
    for (final s in skippedNames) {
      report.add('  $s');
    }
  }

  var reportPath = buildEnv.addFirebaseAuthUrlSchemesReportPath;
  if (reportPath.isEmpty) {
    final tmp = buildEnv.targetTempDir;
    if (tmp.isNotEmpty) {
      reportPath =
          '$tmp${Platform.pathSeparator}add_firebase_auth_url_schemes_report.txt';
    }
  }
  if (reportPath.isNotEmpty) {
    try {
      File(reportPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('${report.join('\n')}\n');
      stdout.writeln(
        'add_firebase_auth_url_schemes: full report — $reportPath',
      );
    } catch (e) {
      stderr.writeln(
        'add_firebase_auth_url_schemes: could not write report $reportPath: $e',
      );
    }
  }

  return 0;
}

/// Distinct [FirebaseOptions.firebaseAuthCustomUrlScheme] values for [bundleId]
/// across [allConfigs], optionally restricted to [projectIdFilter].
List<String> distinctFirebaseAuthCustomUrlSchemesForIosBundle(
  String bundleId,
  String projectIdFilter,
) {
  final schemes = <String>[];
  for (final config in allConfigs) {
    if (projectIdFilter.isNotEmpty && config.projectId != projectIdFilter) {
      continue;
    }
    final options = config.iosConfigs[bundleId];
    if (options == null || options.appId.isEmpty) {
      continue;
    }
    final s = options.firebaseAuthCustomUrlScheme;
    if (!schemes.contains(s)) {
      schemes.add(s);
    }
  }
  return schemes;
}

File? infoPlistInBundle(Directory bundle) {
  final macos = File(
    '${bundle.path}${Platform.pathSeparator}Contents'
    '${Platform.pathSeparator}Info.plist',
  );
  if (macos.existsSync()) {
    return macos;
  }
  final ios = File('${bundle.path}${Platform.pathSeparator}Info.plist');
  if (ios.existsSync()) {
    return ios;
  }
  return null;
}
