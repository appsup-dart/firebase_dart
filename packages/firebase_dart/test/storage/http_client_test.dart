import 'dart:async';

import 'package:firebase_dart/src/storage/impl/http_client.dart';
import 'package:test/test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart';

void main() async {
  group('HttpClient', () {
    String? token;
    late FutureOr<Response> Function(Request) handler;
    var httpClient = HttpClient(MockClient((request) async {
      return handler(request);
    }), () async => token);

    test('Unauthenticated request', () async {
      token = null;
      handler = (request) {
        expect(request.headers['RequestHeader1'], 'RequestValue1');
        expect(request.headers['Authorization'], isNull);
        return Response('I am the server response!!!!', 234,
            headers: {'ResponseHeader1': 'ResponseValue1'}, request: request);
      };
      var response = await httpClient.get(Uri.parse('http://my-url.com/'),
          headers: {'RequestHeader1': 'RequestValue1'});

      expect(response.statusCode, 234);
      expect(response.body, 'I am the server response!!!!');
      expect(response.headers['ResponseHeader1'], 'ResponseValue1');
    });
    test('Authenticated request', () async {
      token = 'TOKEN';
      handler = (request) {
        expect(request.headers['RequestHeader1'], 'RequestValue1');
        expect(request.headers['Authorization'], 'Firebase $token');
        return Response('I am the server response!!!!', 234,
            headers: {'ResponseHeader1': 'ResponseValue1'}, request: request);
      };
      var response = await httpClient.get(Uri.parse('http://my-url.com/'),
          headers: {'RequestHeader1': 'RequestValue1'});

      expect(response.statusCode, 234);
      expect(response.body, 'I am the server response!!!!');
      expect(response.headers['ResponseHeader1'], 'ResponseValue1');
    });
  });
}
