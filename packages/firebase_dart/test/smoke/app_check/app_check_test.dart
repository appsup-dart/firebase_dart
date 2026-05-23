@Tags(['smoke'])
library;

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/storage.dart';
import 'package:test/test.dart';
import 'package:jose/jose.dart';

import '../smoke_test_util.dart';

void main() {
  setUpAll(() async {
    FirebaseDart.setup(isolated: true);
  });

  group('FirebaseAppCheck', () {
    test('getToken returns null before activate', () async {
      final app = await getApp();
      addTearDown(() => app.delete());
      final appCheck = FirebaseAppCheck.instanceFor(app: app);

      expect(await appCheck.getToken(), isNull);
    });

    test('onTokenChange emits after activate', () async {
      final app = await getApp(appCheckRecaptchaV3Enabled: true);
      addTearDown(() => app.delete());
      final siteKey = webAppCheckRecaptchaV3SiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      final tokenFuture = appCheck.onTokenChange.first;
      await appCheck.activate(
          providers: AppCheckProviders.recaptchaV3(siteKey));

      final token = await tokenFuture;
      expect(token, isNotNull);
      expect(token, await appCheck.getToken());
    });

    test('activate with ReCaptchaV3Provider then getToken returns a JWT',
        () async {
      final app = await getApp(appCheckRecaptchaV3Enabled: true);
      addTearDown(() => app.delete());
      final siteKey = webAppCheckRecaptchaV3SiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      await appCheck.activate(
          providers: AppCheckProviders.recaptchaV3(siteKey));

      final token = await appCheck.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      var jwt = await JsonWebToken.decodeAndVerify(
          token!,
          JsonWebKeyStore()
            ..addKeySetUrl(
                Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks')));

      expect(jwt.claims.subject, app.options.appId);
      expect(
          jwt.claims.audience, contains('projects/${app.options.projectId}'));
      expect(jwt.claims['provider'], 'recaptcha_v3');
    });

    test(
        'activate with ReCaptchaEnterpriseProvider then getToken returns a JWT',
        () async {
      final app = await getApp(appCheckRecaptchaEnterpriseEnabled: true);
      addTearDown(() => app.delete());
      final siteKey = webAppCheckRecaptchaEnterpriseSiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      await appCheck.activate(
          providers: AppCheckProviders.recaptchaEnterprise(siteKey));

      final token = await appCheck.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      var jwt = await JsonWebToken.decodeAndVerify(
          token!,
          JsonWebKeyStore()
            ..addKeySetUrl(
                Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks')));

      expect(jwt.claims.subject, app.options.appId);
      expect(
          jwt.claims.audience, contains('projects/${app.options.projectId}'));
      expect(jwt.claims['provider'], 'recaptcha_enterprise');
    });

    test('activate with DebugAppCheckProvider then getToken returns a JWT',
        () async {
      final app = await getApp(appCheckDebugEnabled: true);
      addTearDown(() => app.delete());
      final debugToken = webAppCheckDebugTokenForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      await appCheck.activate(
        providers: AppCheckProviders.debug(debugToken: debugToken),
      );

      final token = await appCheck.getToken();
      expect(token, isNotNull);
      expect(token, isNotEmpty);

      var jwt = await JsonWebToken.decodeAndVerify(
        token!,
        JsonWebKeyStore()
          ..addKeySetUrl(
            Uri.parse('https://firebaseappcheck.googleapis.com/v1/jwks'),
          ),
      );

      expect(jwt.claims.subject, app.options.appId);
      expect(
        jwt.claims.audience,
        contains('projects/${app.options.projectId}'),
      );
      expect(jwt.claims['provider'], 'debug');
    });
  });

  group('FirebaseDatabase', () {
    test('one-shot read succeeds with App Check activated', () async {
      final app = await getApp(appCheckForServiceSmoke: true);
      addTearDown(() => app.delete());
      await activateAppCheckForSmoke(app);

      final db = FirebaseDatabase(app: app);
      final snapshot = await db.reference().child('test').get();

      expect(snapshot, isNotNull);
    });
  });

  group('FirebaseAuth', () {
    test('signInAnonymously succeeds with App Check activated', () async {
      final app = await getApp(appCheckForServiceSmoke: true);
      addTearDown(() => app.delete());
      await activateAppCheckForSmoke(app);

      final auth = FirebaseAuth.instanceFor(app: app);
      final credential = await auth.signInAnonymously();

      expect(credential.user, isNotNull);
      expect(credential.user!.isAnonymous, isTrue);

      await auth.signOut();
    });
  });

  group('FirebaseStorage', () {
    test('getMetadata reaches the API with App Check activated', () async {
      final app = await getApp(appCheckForServiceSmoke: true);
      addTearDown(() => app.delete());
      await activateAppCheckForSmoke(app);

      final storage = FirebaseStorage.instanceFor(app: app);
      final ref = storage.ref(
        'smoke/app_check/does-not-exist-${DateTime.now().microsecondsSinceEpoch}.txt',
      );

      // Proves Storage REST received the request with X-Firebase-AppCheck.
      // object-not-found / unauthorized / quota-exceeded are all backend responses.
      await expectLater(
        ref.getMetadata(),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            anyOf(
              'object-not-found',
              'unauthorized',
              'quota-exceeded',
            ),
          ),
        ),
      );
    });
  });
}
