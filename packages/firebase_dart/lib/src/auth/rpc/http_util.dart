import 'dart:convert';

import 'package:firebase_dart/src/auth/utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/locale.dart';

/// Supplies the current App Check JWT for [AppCheckClient].
///
/// [forceRefresh] asks for a newly exchanged token after the server rejected
/// the previous one.
typedef AppCheckTokenProvider = Future<String?> Function({bool forceRefresh});

/// Adds `X-Firebase-AppCheck` when App Check is activated and a token is available.
class AppCheckClient extends http.BaseClient {
  final http.Client baseClient;
  final AppCheckTokenProvider getAppCheckToken;

  AppCheckClient(this.baseClient, {required this.getAppCheckToken});

  @override
  void close() => baseClient.close();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = await request.finalize().toBytes();
    final response = await _send(request, bytes, forceRefresh: false);
    if (response.statusCode != 401 && response.statusCode != 403) {
      return response;
    }

    final body = await response.stream.toBytes();
    if (!utf8
        .decode(body, allowMalformed: true)
        .toLowerCase()
        .contains('app check')) {
      return _withBody(response, body);
    }
    return _send(request, bytes, forceRefresh: true);
  }

  Future<http.StreamedResponse> _send(
    http.BaseRequest request,
    List<int> bytes, {
    required bool forceRefresh,
  }) async {
    final token = await getAppCheckToken(forceRefresh: forceRefresh);
    final copy = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(request.headers)
      ..bodyBytes = bytes;
    if (token != null && token.isNotEmpty) {
      copy.headers['X-Firebase-AppCheck'] = token;
    } else {
      copy.headers.remove('X-Firebase-AppCheck');
    }
    return baseClient.send(copy);
  }

  http.StreamedResponse _withBody(
      http.StreamedResponse response, List<int> body) {
    return http.StreamedResponse(
      Stream<List<int>>.value(body),
      response.statusCode,
      contentLength: body.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
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
