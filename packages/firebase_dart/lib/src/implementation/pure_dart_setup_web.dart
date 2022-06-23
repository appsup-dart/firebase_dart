import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:jose/jose.dart';
import 'dart:html';

bool _isMobile() {
  final navigatorPlatform = window.navigator.platform?.toLowerCase() ?? '';
  if (navigatorPlatform.startsWith('mac')) {
    return false;
  }
  if (navigatorPlatform.startsWith('win')) {
    return false;
  }
  if (navigatorPlatform.contains('iphone') ||
      navigatorPlatform.contains('ipad') ||
      navigatorPlatform.contains('ipod')) {
    return true;
  }
  if (navigatorPlatform.contains('android')) {
    return true;
  }
  // Since some phones can report a window.navigator.platform as Linux, fall
  // back to use CSS to disambiguate Android vs Linux desktop. If the CSS
  // indicates that a device has a "fine pointer" (mouse) as the primary
  // pointing device, then we'll assume desktop linux, and otherwise we'll
  // assume Android.
  if (window.matchMedia('only screen and (pointer: fine)').matches) {
    return false;
  }
  return true;
}

void setupPureDartImplementation(
    {String? storagePath,
    Platform? platform,
    bool isolated = false,
    required Function(Uri url, {bool popup}) launchUrl,
    required AuthHandler authHandler,
    required ApplicationVerifier applicationVerifier,
    required SmsRetriever smsRetriever,
    http.Client? httpClient}) {
  platform ??= Platform.web(
    currentUrl: Uri.base.toString(),
    isMobile: _isMobile(),
    isOnline: true,
  );

  if (storagePath != null) {
    Hive.init(storagePath);
  }

  initPlatform(platform);
  JsonWebKeySetLoader.global =
      DefaultJsonWebKeySetLoader(httpClient: httpClient);

  FirebaseImplementation.install(PureDartFirebaseImplementation(
      launchUrl: launchUrl,
      authHandler: authHandler,
      applicationVerifier: applicationVerifier,
      smsRetriever: smsRetriever,
      httpClient: httpClient));
}
