import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/core/impl/persistence.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/implementation/isolate.dart';
import 'package:firebase_dart/src/implementation/testing.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:jose/jose.dart';

void setupPureDartImplementation(
    {String? storagePath,
    Platform? platform,
    bool isolated = false,
    required Function(Uri url, {bool popup}) launchUrl,
    required AuthHandler authHandler,
    required ApplicationVerifier applicationVerifier,
    required SmsRetriever smsRetriever,
    http.Client? httpClient}) {
  platform ??= Platform.linux(isOnline: true);

  if (isolated) {
    initPlatform(platform);
    FirebaseImplementation.install(IsolateFirebaseImplementation(
        storagePath: storagePath,
        platform: platform,
        launchUrl: launchUrl,
        authHandler: authHandler,
        applicationVerifier: applicationVerifier,
        smsRetriever: smsRetriever,
        httpClient: httpClient));
  } else {
    if (storagePath != null) {
      Hive.init(storagePath);
    } else {
      PersistenceStorage.setupMemoryStorage();
    }

    initPlatform(platform);
    if (httpClient is TestClient) {
      httpClient.init();
    }
    JsonWebKeySetLoader.global =
        DefaultJsonWebKeySetLoader(httpClient: httpClient);

    FirebaseImplementation.install(PureDartFirebaseImplementation(
        launchUrl: launchUrl,
        authHandler: authHandler,
        applicationVerifier: applicationVerifier,
        smsRetriever: smsRetriever,
        httpClient: httpClient));
  }
}
