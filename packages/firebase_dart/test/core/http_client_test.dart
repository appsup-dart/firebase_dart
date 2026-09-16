import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('FirebaseDart.httpClient is null before setup', () {
    expect(FirebaseDart.httpClient, isNull);
  });

  test('FirebaseDart.httpClient is the client used after setup', () async {
    var called = false;
    var client = MockClient((request) async {
      called = true;
      return Response('', 200);
    });
    FirebaseDart.setup(httpClient: client);
    expect(FirebaseDart.httpClient, isNotNull);
    await FirebaseDart.httpClient!.get(Uri.parse('https://example.com/'));
    expect(called, isTrue);
  });
}
