import 'package:firebase_dart/src/auth/utils.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/locale.dart';

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

    final modifiedRequest = RequestImpl(
        request.method, request.url, request.finalize())
      ..headers.addAll({
        if (platform is AndroidPlatform)
          'X-Android-Package': platform.packageId,
        if (platform is AndroidPlatform)
          'X-Android-Cert': platform.sha1Cert.replaceAll(':', '').toUpperCase(),
        if (platform is IOsPlatform) 'X-Ios-Bundle-Identifier': platform.appId,
        'X-Firebase-Locale': _locale ?? Intl.getCurrentLocale(),
        'X-Firebase-GMPID': firebaseAppId,
        ...request.headers,
      });
    return baseClient.send(modifiedRequest);
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
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final modifiedRequest = RequestImpl(
        request.method,
        request.url.replace(
            queryParameters: {...request.url.queryParameters, 'key': apiKey}),
        request.finalize());
    return baseClient.send(modifiedRequest);
  }
}

class RequestImpl extends http.BaseRequest {
  final Stream<List<int>> _stream;

  RequestImpl(String method, Uri url, [Stream<List<int>>? stream])
      : _stream = stream ?? const Stream.empty(),
        super(method, url);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}
