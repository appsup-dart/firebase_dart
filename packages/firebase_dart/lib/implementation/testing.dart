import 'dart:convert';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/app_verifier.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/implementation/isolate/store.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart'
    as storage;
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:jose/jose.dart';

export 'package:firebase_dart/src/auth/backend/backend.dart' show BackendUser;

class FirebaseTesting {
  /// Initializes the pure dart firebase implementation for testing purposes.
  static Future<void> setup({bool isolated = false}) async {
    var worker = IsolateWorker()
      ..registerFunction(#getAuthBackend, (projectId) {
        var auth =
            BackendImpl.getAuthBackendByApiKey(projectId) as StoreBackend;
        return StoreBackend(
            users: IsolateStore.forStore(auth.users),
            smsCodes: IsolateStore.forStore(auth.smsCodes),
            projectId: projectId,
            tokenSigningKey: BackendImpl._tokenSigningKey);
      })
      ..registerFunction(#getStorageBackend, (bucket) {
        return BackendImpl.getStorageBackend(bucket);
      })
      ..registerFunction(
          #getTokenSigningKey, () => BackendImpl._tokenSigningKey);

    ApplicationVerifier.instance = DummyApplicationVerifier();
    FirebaseDart.setup(
        isolated: isolated,
        platform: Platform.web(
            currentUrl: 'http://localhost', isMobile: true, isOnline: true),
        httpClient: TestClient(worker.commander));
  }

  static Backend getBackend(FirebaseOptions options) => BackendImpl(options);
}

class TestClient extends http.BaseClient {
  late http.Client baseClient = _createClient(this);

  final IsolateCommander commander;

  TestClient(this.commander);

  Future<auth.AuthBackend> getAuthBackend(String apiKey) {
    return commander.execute(RegisteredFunctionCall(#getAuthBackend, [apiKey]));
  }

  Future<storage.StorageBackend> getStorageBackend(String bucket) {
    return commander
        .execute(RegisteredFunctionCall(#getStorageBackend, [bucket]));
  }

  Future<JsonWebKey> getTokenSigningKey() {
    return commander.execute(RegisteredFunctionCall(#getTokenSigningKey));
  }

  static http.Client _createClient(TestClient client) {
    ApplicationVerifier.instance = DummyApplicationVerifier();
    var openIdClient = ProxyClient({
      RegExp('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'):
          http.MockClient((request) async {
        return http.Response(
            json.encode({
              'keys': [await client.getTokenSigningKey()]
            }),
            200);
      }),
      RegExp('https://securetoken.google.com/.*/.well-known/openid-configuration'):
          http.MockClient((request) async {
        var projectId = request.url.pathSegments.first;
        return http.Response(
            json.encode({
              'issuer': 'https://securetoken.google.com/$projectId',
              'jwks_uri':
                  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
              'response_types_supported': ['id_token'],
              'subject_types_supported': ['public'],
              'id_token_signing_alg_values_supported': ['RS256']
            }),
            200);
      }),
      RegExp('https://securetoken.googleapis.com/v1/token'):
          http.MockClient((request) async {
        var apiKey = request.url.queryParameters['key'];
        if (apiKey == null) {
          throw FirebaseAuthException.invalidApiKey();
        }

        var authBackend = await client.getAuthBackend(apiKey);

        var body = request.bodyFields;

        switch (body['grant_type']) {
          case 'refresh_token':
            var uid =
                await authBackend.verifyRefreshToken(body['refresh_token']!);

            var accessToken = await authBackend.generateRefreshToken(uid);
            return http.Response(
                json.encode({
                  'access_token': accessToken,
                  'id_token': accessToken,
                  'expires_in': 3600,
                  'refresh_token': body['refresh_token']
                }),
                200);
          default:
            throw UnimplementedError();
        }
      }),
    });

    var httpClient = ProxyClient({
      ...openIdClient.clients,
      RegExp('https://www.googleapis.com/.*'): http.MockClient((r) async {
        var apiKey = r.url.queryParameters['key'];
        if (apiKey == null) {
          throw FirebaseAuthException.invalidApiKey();
        }

        var authBackend = await client.getAuthBackend(apiKey);

        var connection = auth.BackendConnection(authBackend);
        return connection.handleRequest(r);
      }),
      RegExp('https://firebasestorage.googleapis.com/v0/b/.*'):
          http.MockClient((r) async {
        var bucket = r.url.pathSegments[2];
        var storageBackend = await client.getStorageBackend(bucket);

        var connection = storage.BackendConnection(storageBackend);
        return connection.handleRequest(r);
      }),
    });

    return httpClient;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return baseClient.send(request);
  }
}

abstract class Backend {
  auth.AuthBackend get authBackend;
  storage.StorageBackend get storageBackend;
}

class BackendImpl extends Backend {
  static final JsonWebKey _tokenSigningKey = JsonWebKey.generate('RS256');

  final FirebaseOptions options;

  BackendImpl(this.options) {
    var existing = _apiKeys[options.apiKey];
    assert(existing == null || existing == options.projectId);
    _apiKeys[options.apiKey] = options.projectId;
  }

  static final Map<String, String> _apiKeys = {};

  static final Map<String, auth.StoreBackend> _authBackends = {};

  static final Map<String, storage.MemoryStorageBackend> _storageBackends = {};

  static auth.AuthBackend getAuthBackendByApiKey(String apiKey) {
    var projectId = _apiKeys[apiKey];
    return getAuthBackend(projectId!);
  }

  static auth.AuthBackend getAuthBackend(String projectId) =>
      _authBackends.putIfAbsent(
          projectId,
          () => auth.StoreBackend(
              tokenSigningKey: _tokenSigningKey, projectId: projectId));

  static storage.MemoryStorageBackend getStorageBackend(String bucket) =>
      _storageBackends.putIfAbsent(
          bucket, () => storage.MemoryStorageBackend());

  @override
  auth.AuthBackend get authBackend => getAuthBackend(options.projectId);

  @override
  storage.MemoryStorageBackend get storageBackend =>
      getStorageBackend(options.storageBucket!);
}
