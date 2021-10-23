import 'package:firebase_dart/src/auth/backend/backend.dart' as auth;
import 'package:firebase_dart/src/auth/backend/memory_backend.dart';
import 'package:firebase_dart/src/implementation/isolate/store.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:firebase_dart/src/implementation/testing.dart';
import 'package:firebase_dart/src/storage/backend/backend.dart' as storage;
import 'package:firebase_dart/src/storage/backend/memory_backend.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

http.Client createHttpClient() {
  var worker = IsolateWorker()
    ..registerFunction(#getAuthBackend, (projectId) {
      var auth = BackendImpl.getAuthBackendByApiKey(projectId) as StoreBackend;
      return StoreBackend(
        users: IsolateStore.forStore(auth.users),
        smsCodes: IsolateStore.forStore(auth.smsCodes),
        settings: IsolateStore.forStore(auth.settings),
        projectId: projectId,
      );
    })
    ..registerFunction(#getStorageBackend, (bucket) {
      var storage = BackendImpl.getStorageBackend(bucket);

      return MemoryStorageBackend(items: IsolateStore.forStore(storage.items));
    })
    ..registerFunction(#getTokenSigningKey, () => BackendImpl.tokenSigningKey);

  return TestClient(IsolateBackendRef(worker.commander));
}

class IsolateBackendRef implements BackendRef {
  final IsolateCommander commander;

  IsolateBackendRef(this.commander);

  @override
  Future<auth.AuthBackend> getAuthBackend(String apiKey) {
    return commander.execute(RegisteredFunctionCall(#getAuthBackend, [apiKey]));
  }

  @override
  Future<storage.StorageBackend> getStorageBackend(String bucket) {
    return commander
        .execute(RegisteredFunctionCall(#getStorageBackend, [bucket]));
  }

  @override
  Future<JsonWebKey> getTokenSigningKey() {
    return commander.execute(RegisteredFunctionCall(#getTokenSigningKey));
  }
}
