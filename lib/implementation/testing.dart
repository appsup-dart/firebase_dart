import 'dart:convert';
import 'dart:io';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/auth/auth.dart';
import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart' as auth;
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/implementation/dart.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart'
    as storage;
import 'package:firebase_dart/src/util/proxy.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http;
import 'package:jose/jose.dart';

export 'package:firebase_dart/src/auth/backend/backend.dart' show BackendUser;

class FirebaseTesting {
  static final JsonWebKey _tokenSigningKey = JsonWebKey.generate('RS256');

  static Future<void> setup() async {
    Hive.init(Directory.systemTemp.path);
    await Hive.deleteBoxFromDisk('firebase_auth');

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
    });
    JsonWebKeySetLoader.global =
        DefaultJsonWebKeySetLoader(httpClient: openIdClient);

    var httpClient = ProxyClient({
      ...openIdClient.clients,
      RegExp('https://www.googleapis.com/.*'): http.MockClient((r) async {
        var apiKey = r.url.queryParameters['key'];
        if (apiKey == null) {
          throw AuthException.invalidApiKey();
        }

        var projectId = Backend._apiKeys[apiKey];
        var authBackend = Backend.getAuthBackend(projectId);
        assert(authBackend != null);

        var connection = auth.BackendConnection(authBackend);
        return connection.handleRequest(r);
      }),
      RegExp('https://firebasestorage.googleapis.com/v0/b/.*'):
          http.MockClient((r) async {
        var bucket = r.url.pathSegments[2];
        var storageBackend = Backend.getStorageBackend(bucket);
        assert(storageBackend != null);

        var connection = storage.BackendConnection(storageBackend);
        return connection.handleRequest(r);
      }),
    });

    FirebaseImplementation.install(
        PureDartFirebaseImplementation.withHttpClient(httpClient));
  }

  static Backend getBackend(FirebaseApp app) => Backend(app);
}

class Backend {
  final FirebaseApp _app;

  Backend(this._app) {
    var existing = _apiKeys[_app.options.apiKey];
    assert(existing == null || existing == _app.options.projectId);
    _apiKeys[_app.options.apiKey] = _app.options.projectId;
    print(_apiKeys);
    print(_app.options.apiKey);
    print(_app.options.projectId);
  }

  static final Map<String, String> _apiKeys = {};

  static final Map<String, auth.MemoryBackend> _authBackends = {};

  static final Map<String, storage.MemoryBackend> _storageBackends = {};

  static auth.MemoryBackend getAuthBackend(String projectId) =>
      _authBackends.putIfAbsent(
          projectId,
          () => auth.MemoryBackend(
              tokenSigningKey: FirebaseTesting._tokenSigningKey,
              projectId: projectId));

  static storage.MemoryBackend getStorageBackend(String bucket) =>
      _storageBackends.putIfAbsent(bucket, () => storage.MemoryBackend());

  auth.MemoryBackend get authBackend => getAuthBackend(_app.options.projectId);

  storage.MemoryBackend get storageBackend =>
      getStorageBackend(_app.options.storageBucket);
}
