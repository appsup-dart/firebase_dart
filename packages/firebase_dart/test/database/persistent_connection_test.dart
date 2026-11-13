import 'dart:async';

import 'package:firebase_dart/src/database/impl/connection.dart';
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/token.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentConnectionImpl', () {
    late PersistentConnectionImpl connection;

    setUp(() {
      connection = PersistentConnectionImpl(
        Uri.parse('mem://test'), // Use memory scheme to avoid network
        authTokenProvider: null,
        appCheckTokenProvider: null,
      )..initialize();
    });

    tearDown(() {
      connection.close();
    });

    group('listen()', () {
      test('should complete when connected', () async {
        await connection.onConnect.firstWhere((v) => v);

        // Act
        await connection.listen(
          '/test/path',
          query: const QueryFilter(),
          hash: '',
        );
      });

      test('should complete when connection established', () async {
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        connection.interrupt('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.disconnected);

        var isCompleted = false;
        var f = connection
            .listen(
          '/test/path',
          query: const QueryFilter(),
          hash: '',
        )
            .then((value) {
          isCompleted = true;
        });

        await Future.delayed(Duration(seconds: 1));
        expect(isCompleted, isFalse);

        connection.resume('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        await f;
        expect(isCompleted, isTrue);
      });
    });

    group('unlisten()', () {
      setUp(() async {
        await connection.listen('/test/path',
            query: const QueryFilter(), hash: '');
      });
      test('should complete when connected', () async {
        // Arrange
        await connection.onConnect.firstWhere((v) => v);

        // Act
        await connection.unlisten(
          '/test/path',
          query: const QueryFilter(),
        );
      });

      test('should complete immediately when not connected', () async {
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        connection.interrupt('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.disconnected);

        await connection.unlisten(
          '/test/path',
          query: const QueryFilter(),
        );
      });
    });

    group('refreshAuthToken()', () {
      var secret = 'x';
      var uid = 'test-01';
      var authData = {'uid': uid, 'debug': true, 'provider': 'custom'};
      var codec = FirebaseTokenCodec(secret);
      var token = codec.encode(FirebaseToken(authData));

      test('should complete when connected', () async {
        await connection.onConnect.firstWhere((v) => v);
        expect(connection.authData, isNull);

        await connection.refreshAuthToken(token);
        expect(connection.authData, authData);
      });

      test('should complete when connection established', () async {
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        connection.interrupt('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.disconnected);

        var isCompleted = false;

        await connection.refreshAuthToken(token);

        var f = connection.authResponse.then((value) {
          expect(value, isNotNull);
          isCompleted = true;
        });

        await Future.delayed(Duration(seconds: 1));
        expect(isCompleted, isFalse);

        connection.resume('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        await f;
        expect(isCompleted, isTrue);
      });

      test('should complete immediately when disconnection and null token',
          () async {
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        await connection.refreshAuthToken(token);
        expect(connection.authData, authData);
        connection.interrupt('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.disconnected);

        await connection.refreshAuthToken(null);
        await connection.authResponse;
        expect(connection.authData, isNull);
      });
    });

    group('put()', () {
      test('should complete when connected', () async {
        await connection.onConnect.firstWhere((v) => v);
        await connection.put('/test/path', {'test': 'test'});
      });

      test('should complete when connection established', () async {
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        connection.interrupt('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.disconnected);

        var isCompleted = false;
        var f = connection.put('/test/path', {'test': 'test'}).then((value) {
          isCompleted = true;
        });

        await Future.delayed(Duration(seconds: 1));
        expect(isCompleted, isFalse);

        connection.resume('test');
        await Future.delayed(Duration(milliseconds: 100));
        expect(connection.connectionState, ConnectionState.connected);
        await f;
        expect(isCompleted, isTrue);
      });
    });
  });

  test('app check token failure still connects', () async {
    final connection = PersistentConnectionImpl(
      Uri.parse('mem://app-check-failure'),
      authTokenProvider: null,
      appCheckTokenProvider: _FailingAppCheck(),
    );
    addTearDown(() {
      connection.close();
    });

    final states = <bool>[];
    final subscription = connection.onConnect.listen(states.add);
    addTearDown(subscription.cancel);
    connection.initialize();

    await _waitUntil(() => states.contains(true));
    expect(connection.connectionState, ConnectionState.connected);
  });

  test('app check revoked reconnects with a refreshed token', () async {
    final tokens = _AppCheckTokens();
    final connection = PersistentConnectionImpl(
      Uri.parse('mem://app-check-revoke'),
      authTokenProvider: null,
      appCheckTokenProvider: tokens,
    );
    addTearDown(() {
      connection.close();
    });

    final states = <bool>[];
    final subscription = connection.onConnect.listen(states.add);
    addTearDown(subscription.cancel);
    connection.initialize();

    await _waitUntil(() => states.contains(true));
    expect(tokens.calls, [false]);

    connection.onDataMessage(DataMessage(
      DataMessage.actionAppCheckRevoked,
      MessageBody(status: 'invalid_token', data: 'App Check token rejected'),
    ));

    await _waitUntil(() => states.where((connected) => connected).length >= 2);
    expect(tokens.calls, [false, true]);
    expect(connection.isInterrupted('app_check_revoked'), isFalse);
  });
}

class _FailingAppCheck implements AuthTokenProvider {
  @override
  Future<String?> getToken([bool forceRefresh = false]) async {
    throw StateError('App Check: all providers failed');
  }

  @override
  Stream<Future<String>?> get onTokenChanged => const Stream.empty();
}

class _AppCheckTokens implements AuthTokenProvider {
  final calls = <bool>[];
  var token = 'jwt-1';

  @override
  Future<String?> getToken([bool forceRefresh = false]) async {
    calls.add(forceRefresh);
    if (forceRefresh) token = 'jwt-2';
    return token;
  }

  @override
  Stream<Future<String>?> get onTokenChanged => const Stream.empty();
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('timed out waiting for connection');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
