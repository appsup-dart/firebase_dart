import 'dart:typed_data';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/app_check/app_attest_store.dart';
import 'package:firebase_dart/src/app_check/attestation.dart';
import 'package:firebase_dart/src/app_check/token.dart';
import 'package:firebase_dart/src/auth/rpc/http_util.dart';
import 'package:googleapis/firebaseappcheck/v1.dart';
import 'package:http/http.dart' as http;

Future<AppCheckToken> exchangeAttestation(
  FirebaseApp app,
  AppCheckAttestation attestation, {
  required bool limitedUse,
}) {
  return switch (attestation) {
    MintedAppCheckAttestation(:final token, :final expireTime) =>
      Future.value(AppCheckToken(token, expireTime)),
    RecaptchaV3Attestation(:final token, :final webAppId) =>
      exchangeRecaptchaV3(
        app,
        token,
        limitedUse: limitedUse,
        webAppId: webAppId,
      ),
    RecaptchaEnterpriseAttestation(:final token, :final webAppId) =>
      exchangeRecaptchaEnterprise(
        app,
        token,
        limitedUse: limitedUse,
        webAppId: webAppId,
      ),
    PlayIntegrityAttestation(:final token) => exchangePlayIntegrity(
        app,
        token,
        limitedUse: limitedUse,
      ),
    DeviceCheckAttestation(:final token) => exchangeDeviceCheck(
        app,
        token,
        limitedUse: limitedUse,
      ),
    AppAttestAttestation(
      :final attestationStatement,
      :final challenge,
      :final keyId,
    ) =>
      exchangeAppAttestAttestation(
        app,
        attestationStatement: attestationStatement,
        challenge: challenge,
        keyId: keyId,
        limitedUse: limitedUse,
      ),
    AppAttestAssertionAttestation(
      :final artifact,
      :final assertion,
      :final challenge,
    ) =>
      exchangeAppAttestAssertion(
        app,
        artifact: artifact,
        assertion: assertion,
        challenge: challenge,
        limitedUse: limitedUse,
      ),
    DebugAttestation(:final debugToken) => exchangeDebugToken(
        app,
        debugToken,
        limitedUse: limitedUse,
      ),
    CustomTokenAttestation(:final customToken) => exchangeCustomToken(
        app,
        customToken,
        limitedUse: limitedUse,
      ),
  };
}

String appCheckAppResourceName(FirebaseApp app, {String? webAppId}) =>
    'projects/${app.options.projectId}/apps/${webAppId ?? app.options.appId}';

FirebaseappcheckApi appCheckApi(FirebaseApp app) => FirebaseappcheckApi(
      ApiKeyClient(http.Client(), apiKey: app.options.apiKey),
    );

Duration appCheckTtlFromResponse(String ttl) => Duration(
      microseconds: (num.parse(
                RegExp(r'^([\d\.]+)s$').firstMatch(ttl)!.group(1)!,
              ) *
              1000 *
              1000)
          .round(),
    );

AppCheckToken appCheckTokenFromExchangeResponse(
  GoogleFirebaseAppcheckV1AppCheckToken response,
) {
  return AppCheckToken(
    response.token!,
    DateTime.now().add(appCheckTtlFromResponse(response.ttl!)),
  );
}

Future<AppCheckToken> exchangeRecaptchaV3(
  FirebaseApp app,
  String recaptchaV3Token, {
  required bool limitedUse,
  String? webAppId,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangeRecaptchaV3Token(
            GoogleFirebaseAppcheckV1ExchangeRecaptchaV3TokenRequest()
              ..recaptchaV3Token = recaptchaV3Token
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app, webAppId: webAppId),
          );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangeRecaptchaEnterprise(
  FirebaseApp app,
  String recaptchaEnterpriseToken, {
  required bool limitedUse,
  String? webAppId,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangeRecaptchaEnterpriseToken(
            GoogleFirebaseAppcheckV1ExchangeRecaptchaEnterpriseTokenRequest()
              ..recaptchaEnterpriseToken = recaptchaEnterpriseToken
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app, webAppId: webAppId),
          );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangePlayIntegrity(
  FirebaseApp app,
  String playIntegrityToken, {
  required bool limitedUse,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangePlayIntegrityToken(
            GoogleFirebaseAppcheckV1ExchangePlayIntegrityTokenRequest()
              ..playIntegrityToken = playIntegrityToken
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app),
          );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangeDeviceCheck(
  FirebaseApp app,
  String deviceToken, {
  required bool limitedUse,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangeDeviceCheckToken(
            GoogleFirebaseAppcheckV1ExchangeDeviceCheckTokenRequest()
              ..deviceToken = deviceToken
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app),
          );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangeAppAttestAttestation(
  FirebaseApp app, {
  required String attestationStatement,
  required String challenge,
  required String keyId,
  required bool limitedUse,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangeAppAttestAttestation(
            GoogleFirebaseAppcheckV1ExchangeAppAttestAttestationRequest()
              ..attestationStatement = attestationStatement
              ..challenge = challenge
              ..keyId = keyId
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app),
          );

  final artifact = response.artifact;
  if (artifact != null && artifact.isNotEmpty) {
    await saveAppAttestState(
      app.options.appId,
      keyId,
      Uint8List.fromList(response.artifactAsBytes),
    );
  }

  return appCheckTokenFromExchangeResponse(response.appCheckToken!);
}

Future<AppCheckToken> exchangeAppAttestAssertion(
  FirebaseApp app, {
  required String artifact,
  required String assertion,
  required String challenge,
  required bool limitedUse,
}) async {
  final response =
      await appCheckApi(app).projects.apps.exchangeAppAttestAssertion(
            GoogleFirebaseAppcheckV1ExchangeAppAttestAssertionRequest()
              ..artifact = artifact
              ..assertion = assertion
              ..challenge = challenge
              ..limitedUse = limitedUse,
            appCheckAppResourceName(app),
          );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangeDebugToken(
  FirebaseApp app,
  String debugToken, {
  required bool limitedUse,
}) async {
  final response = await appCheckApi(app).projects.apps.exchangeDebugToken(
        GoogleFirebaseAppcheckV1ExchangeDebugTokenRequest()
          ..debugToken = debugToken
          ..limitedUse = limitedUse,
        appCheckAppResourceName(app),
      );
  return appCheckTokenFromExchangeResponse(response);
}

Future<AppCheckToken> exchangeCustomToken(
  FirebaseApp app,
  String customToken, {
  required bool limitedUse,
}) async {
  final response = await appCheckApi(app).projects.apps.exchangeCustomToken(
        GoogleFirebaseAppcheckV1ExchangeCustomTokenRequest()
          ..customToken = customToken
          ..limitedUse = limitedUse,
        appCheckAppResourceName(app),
      );
  return appCheckTokenFromExchangeResponse(response);
}
