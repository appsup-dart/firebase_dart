import 'package:firebase_dart/src/auth/utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/locale.dart';

/// Supplies the current App Check JWT for [AppCheckClient].
typedef AppCheckTokenProvider = Future<String?> Function();

/// Adds `X-Firebase-AppCheck` when App Check is activated and a token is available.
class AppCheckClient extends http.BaseClient {
  final http.Client baseClient;
  final AppCheckTokenProvider getAppCheckToken;

  AppCheckClient(this.baseClient, {required this.getAppCheckToken});

  @override
  void close() => baseClient.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await getAppCheckToken();
    if (token != null && token.isNotEmpty) {
      request.headers['X-Firebase-AppCheck'] = token;
    }
    return baseClient.send(request);
  }
}

class MetadataClient extends http.BaseClient {
  final String firebaseAppId;

  String? _locale;

  set locale(String? value) {
    if (value != null) {
      Locale.parse(value);
    }
    _locale = value;
  }

  final http.Client baseClient;

  MetadataClient(this.baseClient, {required this.firebaseAppId});

  @override
  void close() {
    baseClient.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    var platform = Platform.current;

    final bundleId = switch (platform) {
      IOsPlatform(:final appId) => appId,
      MacOsPlatform(:final appId) => appId,
      _ => null,
    };

    request.headers.addAll({
      if (platform is AndroidPlatform) 'X-Android-Package': platform.packageId,
      if (platform is AndroidPlatform)
        'X-Android-Cert': platform.sha1Cert.replaceAll(':', '').toUpperCase(),
      if (bundleId != null) 'X-Ios-Bundle-Identifier': bundleId,
      'X-Firebase-Locale': _locale ?? Intl.getCurrentLocale(),
      'X-Firebase-GMPID': firebaseAppId,
      ...request.headers,
    });
    return baseClient.send(request);
  }
}

class ApiKeyClient extends http.BaseClient {
  final http.Client baseClient;

  final String apiKey;

  ApiKeyClient(this.baseClient, {required this.apiKey});

  @override
  void close() {
    baseClient.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final modifiedRequest = http.Request(
      request.method,
      request.url.replace(
          queryParameters: {...request.url.queryParameters, 'key': apiKey}),
    )
      ..headers.addAll(request.headers)
      ..bodyBytes = await request.finalize().toBytes();

    return baseClient.send(modifiedRequest);
  }
}
