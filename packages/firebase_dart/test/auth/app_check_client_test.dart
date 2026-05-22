import 'package:firebase_dart/src/auth/rpc/http_util.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('AppCheckClient', () {
    String? token;
    late Future<Response> Function(Request) handler;
    late AppCheckClient client;

    setUp(() {
      client = AppCheckClient(
        MockClient((request) => handler(request)),
        getAppCheckToken: () async => token,
      );
    });

    test('does not add header when token is null', () async {
      token = null;
      handler = (request) async {
        expect(request.headers['X-Firebase-AppCheck'], isNull);
        return Response('', 200, request: request);
      };

      await client.get(Uri.parse('https://example.com/'));
    });

    test('adds X-Firebase-AppCheck when token is set', () async {
      token = 'app-check-jwt';
      handler = (request) async {
        expect(request.headers['X-Firebase-AppCheck'], 'app-check-jwt');
        return Response('', 200, request: request);
      };

      await client.get(Uri.parse('https://example.com/'));
    });
  });
}
