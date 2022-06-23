import 'dart:convert';
import 'dart:math';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../../auth.dart';
import '../implementation.dart';

class FirebaseAppAuthCredential extends AuthCredential {
  final String sessionId;
  final String link;

  FirebaseAppAuthCredential({
    required String providerId,
    required this.sessionId,
    required this.link,
  }) : super(providerId: providerId, signInMethod: providerId);
}

abstract class FirebaseAppAuthHandler extends BaseRecaptchaVerifier
    implements AuthHandler {
  const FirebaseAppAuthHandler();
  Future<FirebaseAppAuthCredential> createCredential(
      {String? eventId,
      String? sessionId,
      String? providerId,
      String? link}) async {
    var box = await PersistenceStorage.openBox('firebase_auth');
    sessionId = sessionId ?? box.get('redirect_session_id');

    if (eventId != null) {
      var storedEventId = box.get('redirect_event_id');
      if (storedEventId != eventId) {
        throw FirebaseAuthException.noAuthEvent();
      }
      await box.delete('redirect_event_id');
    }

    return FirebaseAppAuthCredential(
        providerId: providerId ?? 'unknown',
        sessionId: sessionId!,
        link: link!);
  }

  static String _randomString([int length = 32]) {
    assert(length > 0);
    var charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';

    var random = Random.secure();
    return Iterable.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static Uri createAuthHandlerUrl({
    required FirebaseApp app,
    required String authType,
    String? providerId,
    List<String>? scopes,
    Map<dynamic, dynamic>? parameters,
  }) {
    var eventId = Uuid().v4();

    var sessionId = _randomString();

    var platform = Platform.current;

    var url = Uri(
        scheme: 'https',
        host: app.options.authDomain,
        path: '__/auth/handler',
        queryParameters: {
          // TODO: version 'v': 'X$clientVersion',
          'authType': authType,
          'apiKey': app.options.apiKey,
          if (providerId != null) 'providerId': providerId,
          if (scopes != null && scopes.isNotEmpty) 'scopes': scopes.join(','),
          if (parameters != null) 'customParameters': json.encode(parameters),
          // TODO: if (tenantId != null) 'tid': tenantId

          'eventId': eventId,

          if (platform is AndroidPlatform) ...{
            'eid': 'p',
            'sessionId': sessionId,
            'apn': platform.packageId,
            'sha1Cert': platform.sha1Cert.replaceAll(':', '').toLowerCase(),
            'publicKey':
                '...', // seems encryption is not used, but public key needs to be present to assemble the correct redirect url
          },
          if (platform is IOsPlatform) ...{
            'sessionId': sessionId,
            'ibi': platform.appId,
            if (app.options.iosClientId != null)
              'clientId': app.options.iosClientId
            else
              'appId': app.options.appId,
          },
          if (platform is MacOsPlatform) ...{
            'sessionId': sessionId,
            'ibi': platform.appId,
            if (app.options.iosClientId != null)
              'clientId': app.options.iosClientId
            else
              'appId': app.options.appId,
          },
          if (platform is WebPlatform) ...{
            'redirectUrl': platform.currentUrl,
            'appName': app.name,
          }
        });
    return url;
  }

  @override
  Future<bool> signIn(FirebaseApp app, AuthProvider provider,
      {bool isPopup = false}) async {
    if (provider is! OAuthProvider) {
      return false;
    }

    var url = createAuthHandlerUrl(
      app: app,
      authType: isPopup ? 'signInWithPopup' : 'signInWithRedirect',
      providerId: provider.providerId,
      parameters: provider.parameters,
      scopes: provider.scopes,
    );

    var box = await PersistenceStorage.openBox('firebase_auth');
    await box.put('redirect_session_id', url.queryParameters['sessionId']);
    await box.put('redirect_event_id', url.queryParameters['eventId']);

    var installation = FirebaseImplementation.installation;
    var launchUrl = (installation as BaseFirebaseImplementation).launchUrl;
    launchUrl(url, popup: isPopup);
    return true;
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {}

  @override
  Future<String> verifyWithRecaptcha(FirebaseAuth auth) async {
    var url = createAuthHandlerUrl(
      app: auth.app,
      authType: 'verifyApp',
    );

    var installation = FirebaseImplementation.installation;
    var launchUrl = (installation as BaseFirebaseImplementation).launchUrl;
    launchUrl(url);

    return getVerifyResult(auth.app);
  }

  @visibleForOverriding
  Future<String> getVerifyResult(FirebaseApp app);
}
