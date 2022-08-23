import 'dart:convert';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/testing.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart';
import 'package:firebase_dart/src/implementation/isolate/store.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart'
    as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart';
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:jose/jose.dart';
import 'package:openid_client/openid_client.dart';

class BackendImpl extends Backend {
  static final JsonWebKey tokenSigningKey = JsonWebKey.generate('RS256');

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
          () => auth.StoreBackend(projectId: projectId)
            ..setTokenGenerationSettings(
                tokenSigningKey: tokenSigningKey,
                tokenExpiresIn: Duration(hours: 1)));

  static storage.MemoryStorageBackend getStorageBackend(String bucket) =>
      _storageBackends.putIfAbsent(
          bucket, () => storage.MemoryStorageBackend());

  @override
  auth.AuthBackend get authBackend => getAuthBackend(options.projectId);

  @override
  storage.MemoryStorageBackend get storageBackend =>
      getStorageBackend(options.storageBucket!);
}

class BackendRef {
  Future<auth.AuthBackend> getAuthBackend(String apiKey) async {
    var auth = BackendImpl.getAuthBackendByApiKey(apiKey) as StoreBackend;
    return StoreBackend(
      users: IsolateStore.forStore(auth.users),
      smsCodes: IsolateStore.forStore(auth.smsCodes),
      settings: IsolateStore.forStore(auth.settings),
      projectId: apiKey,
    );
  }

  Future<storage.StorageBackend> getStorageBackend(String bucket) async {
    var storage = BackendImpl.getStorageBackend(bucket);

    return MemoryStorageBackend(items: IsolateStore.forStore(storage.items));
  }

  Future<JsonWebKey> getTokenSigningKey() async {
    return BackendImpl.tokenSigningKey;
  }
}

class TestClient extends http.BaseClient {
  late http.Client _baseClient;

  final BackendRef backendRef;

  TestClient(this.backendRef);

  void init() {
    _baseClient = _createClient(backendRef);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _baseClient.send(request);
  }

  static http.Client _createClient(BackendRef backend) {
    var openIdClient = ProxyClient({
      RegExp('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'):
          http.MockClient((request) async {
        return http.Response(
            json.encode({
              'keys': [await backend.getTokenSigningKey()]
            }),
            200,
            headers: {'Content-Type': 'application/json'},
            request: request);
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
            200,
            headers: {'Content-Type': 'application/json'},
            request: request);
      }),
      RegExp('https://securetoken.googleapis.com/v1/token'):
          http.MockClient((request) async {
        var apiKey = request.url.queryParameters['key'];
        if (apiKey == null) {
          throw FirebaseAuthException.invalidApiKey();
        }

        var authBackend = await backend.getAuthBackend(apiKey);

        var body = request.bodyFields;
        switch (body['grant_type']) {
          case 'refresh_token':
            var oldIdToken =
                await authBackend.verifyRefreshToken(body['refresh_token']!);
            var claims = IdToken.unverified(oldIdToken).claims;

            var accessToken = await authBackend.generateIdToken(
                uid: claims.subject, providerId: claims['provider_id']);

            var refreshToken =
                await authBackend.generateRefreshToken(accessToken);
            return http.Response(
                json.encode({
                  'access_token': accessToken,
                  'id_token': accessToken,
                  'expires_in':
                      (await authBackend.getTokenExpiresIn()).inSeconds,
                  'refresh_token': refreshToken
                }),
                200,
                headers: {'Content-Type': 'application/json'},
                request: request);
          default:
            throw UnimplementedError();
        }
      }),
    });

    var httpClient = ProxyClient({
      ...openIdClient.clients,
      RegExp('https://identitytoolkit.googleapis.com/.*'):
          http.MockClient((r) async {
        var apiKey = r.url.queryParameters['key'];
        if (apiKey == null) {
          throw FirebaseAuthException.invalidApiKey();
        }

        var authBackend = await backend.getAuthBackend(apiKey);

        var connection = auth.BackendConnection(authBackend);
        return connection.handleRequest(r);
      }),
      RegExp('https://firebasestorage.googleapis.com/v0/b/.*'):
          http.MockClient((r) async {
        var bucket = r.url.pathSegments[2];
        var storageBackend = await backend.getStorageBackend(bucket);

        var connection = storage.BackendConnection(storageBackend);
        return connection.handleRequest(r);
      }),
    });

    return httpClient;
  }
}
