// @dart=2.9

import 'package:http/http.dart' as http;

typedef AuthProvider = Future<String> Function();

class HttpClient extends http.BaseClient {
  /// The timeout for all operations except upload.
  static const defaultMaxOperationRetryTime = Duration(minutes: 2);

  /// The timeout for upload.
  static const defaultMaxUploadRetryTime = Duration(minutes: 10);

  final http.Client baseClient;

  final AuthProvider getAuthToken;

  Duration maxOperationRetryTime = defaultMaxOperationRetryTime;
  Duration maxUploadRetryTime = defaultMaxUploadRetryTime;

  HttpClient(
    this.baseClient,
    this.getAuthToken,
  );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    var authToken = await getAuthToken();
    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Firebase ' + authToken;
    }

    return baseClient.send(request).timeout(maxOperationRetryTime);
  }
}
