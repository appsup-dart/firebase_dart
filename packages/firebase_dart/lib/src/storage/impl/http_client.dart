import 'dart:collection';

import 'package:http/http.dart' as http;

typedef AuthProvider = Future<String?> Function();

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
      request.headers['Authorization'] = 'Firebase $authToken';
    }

    var response =
        await baseClient.send(request).timeout(maxOperationRetryTime);

    return StreamedResponseWithCaseInsensitiveHeaders(response);
  }
}

class DelegatingStreamedResponse implements http.StreamedResponse {
  final http.StreamedResponse delegateTo;

  DelegatingStreamedResponse(this.delegateTo);

  @override
  int? get contentLength => delegateTo.contentLength;

  @override
  Map<String, String> get headers => delegateTo.headers;

  @override
  bool get isRedirect => delegateTo.isRedirect;

  @override
  bool get persistentConnection => delegateTo.persistentConnection;

  @override
  String? get reasonPhrase => delegateTo.reasonPhrase;

  @override
  http.BaseRequest? get request => delegateTo.request;

  @override
  int get statusCode => delegateTo.statusCode;

  @override
  http.ByteStream get stream => delegateTo.stream;
}

class StreamedResponseWithCaseInsensitiveHeaders
    extends DelegatingStreamedResponse {
  @override
  final Map<String, String> headers = LinkedHashMap(
      equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(),
      hashCode: (key) => key.toLowerCase().hashCode);

  StreamedResponseWithCaseInsensitiveHeaders(http.StreamedResponse delegateTo)
      : super(delegateTo) {
    headers.addAll(super.headers);
  }
}
