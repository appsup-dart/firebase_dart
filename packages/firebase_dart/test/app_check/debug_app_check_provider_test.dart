import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/app_check/attestation.dart';
import 'package:firebase_dart/src/app_check/debug_app_check_provider.dart';
import 'package:test/test.dart';

import '../util.dart';

void main() {
  setUpAll(() {
    FirebaseDart.setup();
  });

  test('uses explicit debug token', () async {
    final app = await Firebase.initializeApp(
      options: getOptions(appId: '1:2:web:debug-explicit'),
      name: 'debug-explicit-${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() => app.delete());

    final attestation = await DebugAppCheckProvider(
      debugToken: '00000000-0000-4000-8000-000000000001',
    ).getAttestation(app);

    expect(attestation, isA<DebugAttestation>());
    expect(
      (attestation as DebugAttestation).debugToken,
      '00000000-0000-4000-8000-000000000001',
    );
  });

  test('generates UUID v4 and persists per app', () async {
    final app = await Firebase.initializeApp(
      options: getOptions(appId: '1:2:web:debug-generated'),
      name: 'debug-generated-${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() => app.delete());

    final provider = DebugAppCheckProvider();
    final first = await provider.getAttestation(app) as DebugAttestation;
    final second = await provider.getAttestation(app) as DebugAttestation;

    expect(first.debugToken, second.debugToken);
    expect(
      first.debugToken,
      matches(RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      )),
    );
  });
}
