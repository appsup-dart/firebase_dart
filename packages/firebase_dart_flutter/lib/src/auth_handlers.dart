import 'dart:async';
import 'dart:convert';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:platform_info/platform_info.dart' as platform_info;
import 'package:logging/logging.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';
import 'package:crypto/crypto.dart';
import 'package:app_links/app_links.dart';

class FacebookAuthHandler extends DirectAuthHandler {
  FacebookAuthHandler() : super(FacebookAuthProvider.PROVIDER_ID);

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    try {
      var facebookLogin = FacebookAuth.instance;
      await facebookLogin.logOut();
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, AuthProvider provider) async {
    try {
      var facebookLogin = FacebookAuth.instance;
      var accessToken = (await facebookLogin.login()).accessToken!;

      return FacebookAuthProvider.credential(accessToken.tokenString);
    } catch (e) {
      return null;
    }
  }
}

class GoogleAuthHandler extends DirectAuthHandler {
  GoogleAuthHandler() : super(GoogleAuthProvider.PROVIDER_ID);

  @override
  Future<void> signOut(FirebaseApp app, User user) async {
    try {
      await GoogleSignIn().signOut();
    } on AssertionError {
      // TODO
    } on MissingPluginException {
      // TODO
    } catch (e) {
      // TODO: on release build for web, this throws an exception, should be checked why, for now ignore
    }
  }

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, AuthProvider provider) async {
    try {
      var account = await GoogleSignIn().signIn();
      var auth = await account!.authentication;
      return GoogleAuthProvider.credential(
          idToken: auth.idToken, accessToken: auth.accessToken);
    } on MissingPluginException {
      return null;
    } on AssertionError {
      return null;
    }
  }
}

class AppleAuthHandler extends DirectAuthHandler<OAuthProvider> {
  AppleAuthHandler() : super('apple.com');

  @override
  Future<AuthCredential?> directSignIn(
      FirebaseApp app, OAuthProvider provider) async {
    if (!platform_info.Platform.instance.iOS) {
      return null;
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    return OAuthProvider.credential(
        providerId: providerId,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode);
  }

  @override
  Future<void> signOut(FirebaseApp app, User user) async {}
}

class FlutterAuthHandler extends FirebaseAppAuthHandler {
  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<AuthCredential?>? _lastAuthResult;

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    if (!kIsWeb) {
      return _lastAuthResult ??= Future(() async {
        var v = await (platform_info.Platform.instance.android
            ? _getResult('getAuthResult')
            : _deepLinkRetriever.getDeepLinkResult());
        _lastAuthResult = null;
        return createCredential(
            sessionId: v['sessionId'],
            providerId: v['providerId'],
            link: v['link']);
      });
    }
    return null;
  }
}

const _channel = MethodChannel('firebase_dart_flutter');

Future<Map<String, dynamic>> _getResult(String type) async {
  var v = (await _channel.invokeMapMethod<String, dynamic>(type))!;

  Map<String, dynamic>? error =
      v['firebaseError'] == null ? null : json.decode(v['firebaseError']);
  if (error != null) {
    var code = error['code'];
    if (code.startsWith('auth/')) {
      code = code.substring('auth/'.length);
    }
    throw FirebaseAuthException(code, error['message']);
  }
  return v;
}

class FlutterApplicationVerifier extends BaseApplicationVerifier {
  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<String>? _lastRecaptchaResult;

  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await _channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  @override
  Future<String> getVerifyResult(FirebaseApp app) {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await _getResult('getVerifyResult');
        _lastRecaptchaResult = null;

        return Uri.parse(v['link']!).queryParameters['recaptchaToken']!;
      });
    } else if (!kIsWeb) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await _deepLinkRetriever.getDeepLinkResult();
        _lastRecaptchaResult = null;

        return v['recaptchaToken']!;
      });
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> verifyWithApns(FirebaseAuth auth) async {
    try {
      var apns = ApnsPushConnectorOnly();

      var completer = Completer<String>();
      apns.configureApns(
        onMessage: (message) async {
          var v =
              json.decode(message.payload['data']['com.google.firebase.auth']);

          completer.complete('${v['receipt']}:${v['secret']}');
        },
      );

      var tokenCompleter = Completer<String>();
      if (apns.token.value != null) {
        tokenCompleter.complete(apns.token.value);
      } else {
        apns.token.addListener(() async {
          if (tokenCompleter.isCompleted) return;
          tokenCompleter.complete(apns.token.value);
        });
      }

      var defaultTimeout = const Duration(seconds: 5);
      var s = await apns.getAuthorizationStatus().timeout(defaultTimeout);
      if (s != ApnsAuthorizationStatus.authorized) {
        if (!await apns.requestNotificationPermissions()) {
          return null;
        }
      }

      var timeout = await verifyIosClient(auth,
              appToken: await tokenCompleter.future.timeout(defaultTimeout),
              isSandbox: !kReleaseMode)
          .timeout(defaultTimeout);

      return completer.future.timeout(timeout);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> verifyWithPlayIntegrity(
      FirebaseAuth auth, String nonce) async {
    var available = await _isGooglePlayServicesAvailable;
    if (!available) return null;

    try {
      var n = base64Url.encode(sha256.convert(nonce.codeUnits).bytes);
      var token = await _channel.invokeMethod<String>('requestIntegrityToken', {
        'projectNumber': await getProducerProjectNumber(auth),
        'nonce': n,
      });
      return token!;
    } catch (e, tr) {
      Logger('FlutterApplicationVerifier')
          .warning('Failed getting SafetyNet token', e, tr);
      return null;
    }
  }
}

class AndroidSmsRetriever extends SmsRetriever {
  static const _channel = MethodChannel('firebase_dart_flutter');

  late final Future<String?> _appSignatureHash = Future(() async {
    var v = (await _channel.invokeMethod<String>('getAppSignatureHash'))!;
    return v;
  });

  @override
  Future<String?> getAppSignatureHash() {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return _appSignatureHash;
    }
    return Future.value();
  }

  @override
  Future<String?> retrieveSms() {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return Future<String?>(() async {
        var v = (await _channel.invokeMethod<String>('retrieveSms'))!;
        return v;
      }).catchError((e, tr) {
        Logger('firebase_dart_flutter').warning('Failed retrieving SMS', e, tr);
        return null;
      });
    }
    return Future.value();
  }
}

class DeepLinkRetriever with WidgetsBindingObserver {
  final StreamController<Uri> _controller = StreamController.broadcast();

  DeepLinkRetriever._() {
    if (!kIsWeb && !platform_info.Platform.instance.mobile) {
      AppLinks().uriLinkStream.listen((uri) {
        didPushRouteInformation(RouteInformation(uri: uri));
      });
    } else {
      WidgetsFlutterBinding.ensureInitialized().addObserver(this);
    }
  }

  static final DeepLinkRetriever instance = DeepLinkRetriever._();

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    var uri = routeInformation.uri;

    if (uri.host != 'firebaseauth') return false;
    var deepLink = Uri.parse(uri.queryParameters['deep_link_id']!);

    _controller.add(deepLink);

    return true;
  }

  Future<Map<String, String>> getDeepLinkResult() async {
    var deepLink = await _controller.stream.first;

    var v = deepLink.queryParameters;

    Map<String, dynamic>? error =
        v['firebaseError'] == null ? null : json.decode(v['firebaseError']!);
    if (error != null) {
      var code = error['code'] as String;
      if (code.startsWith('auth/')) {
        code = code.substring('auth/'.length);
      }
      throw FirebaseAuthException(code, error['message']);
    }
    return v;
  }
}
