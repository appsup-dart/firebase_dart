@Tags(['smoke'])
library;

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/database.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:test/test.dart';
import 'package:jose/jose.dart';

import '../smoke_test_util.dart';

void main() {
  setUpAll(() async {
    FirebaseDart.setup();
  });

  group('FirebaseAppCheck', () {
    test('getToken returns null before activate', () async {
      final app = await getApp();
      final appCheck = FirebaseAppCheck.instanceFor(app: app);

      expect(await appCheck.getToken(), isNull);
    });

    test('activate with ReCaptchaV3Provider then getToken returns a JWT',
        () async {
      final app = await getApp(appCheckRecaptchaV3Enabled: true);
      final siteKey = webAppCheckRecaptchaV3SiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      final provider = ReCaptchaV3Provider(siteKey);

      await appCheck.activate(webProvider: provider);

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
      final siteKey = webAppCheckRecaptchaEnterpriseSiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      final provider = ReCaptchaEnterpriseProvider(siteKey);

      await appCheck.activate(webProvider: provider);

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
  });

  group('FirebaseDatabase', () {
    test('one-shot read succeeds with App Check activated', () async {
      final app = await getApp(appCheckRecaptchaEnterpriseEnabled: true);
      final siteKey = webAppCheckRecaptchaEnterpriseSiteKeyForApp(app);
      final appCheck = FirebaseAppCheck.instanceFor(app: app);
      await appCheck.activate(
          webProvider: ReCaptchaEnterpriseProvider(siteKey));

      final db = FirebaseDatabase(app: app);
      final snapshot = await db.reference().child('test').get();

      expect(snapshot, isNotNull);
    });
  });
}
