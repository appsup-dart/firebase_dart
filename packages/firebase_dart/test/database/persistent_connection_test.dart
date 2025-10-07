import 'dart:async';

import 'package:firebase_dart/src/database/impl/connection.dart';
import 'package:firebase_dart/src/database/impl/connections/protocol.dart';
import 'package:firebase_dart/src/database/impl/treestructureddata.dart';
import 'package:firebase_dart/src/database/token.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentConnectionImpl', () {
    late PersistentConnectionImpl connection;

    setUp(() {
      connection = PersistentConnectionImpl(
        Uri.parse('mem://test'), // Use memory scheme to avoid network
        authTokenProvider: null,
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
}
