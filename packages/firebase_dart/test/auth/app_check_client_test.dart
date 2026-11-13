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
        getAppCheckToken: ({bool forceRefresh = false}) async => token,
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

    test('fetches a new token once when the server rejects App Check',
        () async {
      token = 'stale';
      var calls = 0;
      var refreshes = 0;
      client = AppCheckClient(
        MockClient((request) async {
          calls++;
          if (calls == 1) {
            expect(request.headers['X-Firebase-AppCheck'], 'stale');
            return Response(
              'Firebase App Check token is invalid.',
              401,
              request: request,
            );
          }
          expect(request.headers['X-Firebase-AppCheck'], 'fresh');
          return Response('ok', 200, request: request);
        }),
        getAppCheckToken: ({bool forceRefresh = false}) async {
          if (forceRefresh) {
            refreshes++;
            token = 'fresh';
          }
          return token;
        },
      );

      final response = await client.get(Uri.parse('https://example.com/'));

      expect(response.statusCode, 200);
      expect(response.body, 'ok');
      expect(refreshes, 1);
      expect(calls, 2);
    });

    test('keeps an unrelated 401', () async {
      token = 'app-check-jwt';
      var refreshes = 0;
      client = AppCheckClient(
        MockClient((request) async {
          return Response('missing credentials', 401, request: request);
        }),
        getAppCheckToken: ({bool forceRefresh = false}) async {
          if (forceRefresh) refreshes++;
          return token;
        },
      );

      final response = await client.get(Uri.parse('https://example.com/'));

      expect(response.statusCode, 401);
      expect(response.body, 'missing credentials');
      expect(refreshes, 0);
    });
  });
}
