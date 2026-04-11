@Tags(['smoke'])
library;

import 'package:_integration_testing/_integration_testing.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/impl/auth.dart';
import 'package:firebase_dart/src/auth/recaptcha_verifier.dart';
import 'package:test/test.dart';

/// Returns [FirebaseAuth] for the chosen project, creating the app with
/// [Firebase.initializeApp] when needed ([FirebaseProjectConfig.webConfig]).
///
/// When [recaptchaEnterpriseEnabled] is null, uses [allConfigs.first] (no
/// filtering on [FirebaseProjectConfig.phoneAuthRecaptchaEnforcement]).
///
/// When it is true, uses the first config with [PhoneAuthRecaptchaEnforcement.enforce]
/// or [PhoneAuthRecaptchaEnforcement.audit]. When false, uses the first config
/// that is neither enforce nor audit.
///
/// The app is always registered under [FirebaseProjectConfig.projectId].
Future<FirebaseAuthImpl> getAuth({bool? recaptchaEnterpriseEnabled}) async {
  if (allConfigs.isEmpty) {
    throw StateError(
      'No Firebase project configs in package:_integration_testing. '
      'From packages/_integration_testing run:\n'
      '  dart run tool/generate_firebase_web_config.dart',
    );
  }

  final FirebaseProjectConfig config;
  if (recaptchaEnterpriseEnabled == null) {
    config = allConfigs.first;
  } else if (recaptchaEnterpriseEnabled) {
    config = allConfigs.firstWhere(
      (c) =>
          c.phoneAuthRecaptchaEnforcement ==
              PhoneAuthRecaptchaEnforcement.enforce ||
          c.phoneAuthRecaptchaEnforcement ==
              PhoneAuthRecaptchaEnforcement.audit,
      orElse: () => throw StateError(
        'No FirebaseProjectConfig in allConfigs with '
        'phoneAuthRecaptchaEnforcement audit or enforce. '
        'Regenerate configs or enable reCAPTCHA Enterprise for phone auth.',
      ),
    );
  } else {
    config = allConfigs.firstWhere(
      (c) =>
          c.phoneAuthRecaptchaEnforcement !=
              PhoneAuthRecaptchaEnforcement.enforce &&
          c.phoneAuthRecaptchaEnforcement !=
              PhoneAuthRecaptchaEnforcement.audit,
      orElse: () => throw StateError(
        'No FirebaseProjectConfig in allConfigs without '
        'phoneAuthRecaptchaEnforcement audit or enforce.',
      ),
    );
  }

  late final FirebaseApp app;
  FirebaseApp? matchByName;
  for (final a in Firebase.apps) {
    if (a.name == config.projectId) {
      matchByName = a;
      break;
    }
  }
  if (matchByName != null) {
    app = matchByName;
  } else {
    FirebaseApp? matchByProjectId;
    for (final a in Firebase.apps) {
      if (a.options.projectId == config.projectId) {
        matchByProjectId = a;
        break;
      }
    }
    app = matchByProjectId ??
        await Firebase.initializeApp(
          name: config.projectId,
          options: config.webConfig,
        );
  }

  return FirebaseAuth.instanceFor(app: app) as FirebaseAuthImpl;
}

void main() {
  setUpAll(() async {
    FirebaseDart.setup();
  });

  group('RecaptchaVerifier', () {
    group('challenge-based site keys', () {
      test('should verify', () async {
        final auth = await getAuth(recaptchaEnterpriseEnabled: false);
        var siteKey = await auth.rpcHandler.getRecaptchaSiteKey();
        var verifier = RecaptchaVerifier(siteKey: siteKey);
        var token = await verifier.verify();
        expect(token, isNotEmpty);
      });

      test('should error with invalid site key', () async {
        var verifier = RecaptchaVerifier(siteKey: 'siteKey');
        expect(() => verifier.verify(),
            throwsA(FirebaseAuthException('recaptcha-error')));
      });
    });

    group('score-based site keys', () {
      test('should verify', () async {
        final auth = await getAuth(recaptchaEnterpriseEnabled: true);
        var config = await auth.rpcHandler.getRecaptchaConfig(
            clientType: 'CLIENT_TYPE_WEB', version: 'RECAPTCHA_ENTERPRISE');
        final phoneState = config.recaptchaEnforcementState!
            .firstWhere((e) => e.provider == 'PHONE_PROVIDER')
            .enforcementState;
        expect(phoneState, anyOf('ENFORCE', 'AUDIT'));

        var siteKey = config.recaptchaKey!.split('/').last;
        var verifier =
            RecaptchaVerifier(siteKey: siteKey, action: 'sendVerificationCode');
        var token = await verifier.verify();
        expect(token, isNotEmpty);
      });

      test('should error with invalid site key', () async {
        var verifier = RecaptchaVerifier(
            siteKey: 'siteKey', action: 'sendVerificationCode');
        expect(
            () => verifier.verify(),
            throwsA(FirebaseAuthException('recaptcha-error',
                'Invalid site key or not loaded in api.js: siteKey')));
      });
    });
  });

  group('RecaptchaApplicationVerifier', () {
    final verifier = RecaptchaApplicationVerifier();

    test(
        'verify should return recaptcha enterprise token when recaptcha enterprise is enabled',
        () async {
      final auth = await getAuth(recaptchaEnterpriseEnabled: true);
      var token = await verifier.verify(auth,
          nonce: 'nonce', action: 'sendVerificationCode');
      expect(token.type, 'recaptcha-enterprise');
      expect(token.token, startsWith('CLIENT_TYPE_WEB:'));
    });

    test(
        'verify should return recaptcha token when recaptcha enterprise is disabled',
        () async {
      final auth = await getAuth(recaptchaEnterpriseEnabled: false);
      var token = await verifier.verify(auth,
          nonce: 'nonce', action: 'sendVerificationCode');
      expect(token.type, 'recaptcha');
      expect(token.token, isNotEmpty);
    });
  });
}
