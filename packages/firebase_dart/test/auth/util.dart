import 'dart:async';
import 'dart:convert';

import 'package:firebase_dart/core.dart';
import 'package:jose/jose.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;

import 'jwt_util.dart';

FirebaseOptions getOptions(
    {String appId = 'my_app_id',
    String apiKey = 'apiKey',
    String projectId = 'my_project'}) {
  return FirebaseOptions(
      appId: appId,
      apiKey: apiKey,
      projectId: projectId,
      messagingSenderId: 'ignore',
      authDomain: '$projectId.firebaseapp.com');
}

class Expectation {
  late dynamic _response;
  dynamic _body;
  Map<String, String> _headers = {};
  int httpCode = 200;

  void thenReturn(FutureOr<Map<String, dynamic>> response, {int code = 200}) {
    _response = response;
    httpCode = code;
  }

  void thenAnswer(
      FutureOr<Map<String, dynamic>> Function(http.Request) responser) {
    _response = responser;
  }

  void expectBody(dynamic body) {
    _body = body;
  }

  void expectHeaders(Map<String, String>? headers) {
    _headers = headers ?? {};
  }

  Future<http.Response> _do(http.Request r) async {
    if (_body != null) {
      var body = _body is Function ? _body() : _body;
      if (r.method == 'GET') {
        expect(r.url.queryParameters, {...r.url.queryParameters, ...body});
      } else {
        if (body is Map) {
          expect(json.decode(r.body), body);
        } else {
          expect(r.body, body);
        }
      }
    }
    expect(
        r.headers
          ..remove('Content-Type')
          ..remove('User-Agent')
          ..remove('Content-Length')
          ..remove('x-goog-api-client')
          ..removeWhere((key, value) =>
              key.startsWith('X-Firebase-') &&
              (key != 'X-Firebase-Locale' || value == 'en_US')),
        _headers..remove('Content-Type'));

    var response = await (_response is Function ? _response(r) : _response);
    var code = response['error'] is String
        ? 400
        : (response['error'] ?? {})['code'] ?? httpCode;
    return http.Response(json.encode(response), code,
        headers: {'content-type': 'application/json'}, request: r);
  }
}

final Map<String, Expectation> _expectations = {};

Expectation when(String method, String url) {
  url = Uri.parse(url).replace(query: '').toString();

  return _expectations['$method:::$url'] = Expectation();
}

var mockHttpClient = http.MockClient((r) async {
  var url = r.url.replace(query: '');
  var e = _expectations['${r.method}:::$url'];
  if (e == null) {
    throw Exception('No server response defined for ${r.method} $url');
  }
  return await e._do(r);
});

void mockOpenidResponses() {
  JsonWebKeySetLoader.global =
      DefaultJsonWebKeySetLoader(httpClient: mockHttpClient);

  when('GET',
          'https://securetoken.google.com/12345678/.well-known/openid-configuration')
      .thenAnswer((r) {
    return {
      'issuer': 'https://securetoken.google.com/12345678',
      'jwks_uri':
          'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
      'response_types_supported': ['id_token'],
      'subject_types_supported': ['public'],
      'id_token_signing_alg_values_supported': ['RS256']
    };
  });

  when('GET',
          'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com')
      .thenReturn({
    'keys': [key.toJson()]
  });
}

class ProxyClient extends http.BaseClient {
  final Map<Pattern, http.Client> clients;

  ProxyClient(this.clients);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    for (var p in clients.keys) {
      if (p.allMatches(request.url.replace(query: '').toString()).isNotEmpty) {
        return clients[p]!.send(request);
      }
    }
    throw ArgumentError('No client defined for url ${request.url}');
  }
}
