import 'dart:convert';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart' as auth;
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart'
    as storage;
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:jose/jose.dart';

export 'package:firebase_dart/src/auth/backend/backend.dart' show BackendUser;

class FirebaseTesting {
  static final JsonWebKey _tokenSigningKey = JsonWebKey.generate('RS256');

  /// Initializes the pure dart firebase implementation for testing purposes.
  static Future<void> setup() async {
    var openIdClient = ProxyClient({
      RegExp('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'):
          http.MockClient((request) async {
        return http.Response(
            json.encode({
              'keys': [_tokenSigningKey]
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

        var projectId = Backend._apiKeys[apiKey];
        var authBackend = Backend.getAuthBackend(projectId);

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
    JsonWebKeySetLoader.global =
        DefaultJsonWebKeySetLoader(httpClient: openIdClient);

    var httpClient = ProxyClient({
      ...openIdClient.clients,
      RegExp('https://www.googleapis.com/.*'): http.MockClient((r) async {
        var apiKey = r.url.queryParameters['key'];
        if (apiKey == null) {
          throw FirebaseAuthException.invalidApiKey();
        }

        var projectId = Backend._apiKeys[apiKey];
        var authBackend = Backend.getAuthBackend(projectId);

        var connection = auth.BackendConnection(authBackend);
        return connection.handleRequest(r);
      }),
      RegExp('https://firebasestorage.googleapis.com/v0/b/.*'):
          http.MockClient((r) async {
        var bucket = r.url.pathSegments[2];
        var storageBackend = Backend.getStorageBackend(bucket);

        var connection = storage.BackendConnection(storageBackend);
        return connection.handleRequest(r);
      }),
    });

    FirebaseDart.setup(
        platform: Platform.web(
            currentUrl: 'http://localhost', isMobile: true, isOnline: true),
        httpClient: httpClient);
  }

  static Backend getBackend(FirebaseOptions options) => Backend(options);
}

class Backend {
  final FirebaseOptions options;

  Backend(this.options) {
    var existing = _apiKeys[options.apiKey];
    assert(existing == null || existing == options.projectId);
    _apiKeys[options.apiKey] = options.projectId;
  }

  static final Map<String, String> _apiKeys = {};

  static final Map<String?, auth.MemoryBackend> _authBackends = {};

  static final Map<String?, storage.MemoryBackend> _storageBackends = {};

  static auth.MemoryBackend getAuthBackend(String? projectId) =>
      _authBackends.putIfAbsent(
          projectId,
          () => auth.MemoryBackend(
              tokenSigningKey: FirebaseTesting._tokenSigningKey,
              projectId: projectId));

  static storage.MemoryBackend getStorageBackend(String? bucket) =>
      _storageBackends.putIfAbsent(bucket, () => storage.MemoryBackend());

  auth.MemoryBackend get authBackend => getAuthBackend(options.projectId);

  storage.MemoryBackend get storageBackend =>
      getStorageBackend(options.storageBucket);
}
