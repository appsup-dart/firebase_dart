import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:http/http.dart' as http;

import 'impl/http_client.dart';
import 'impl/location.dart';
import 'reference.dart';

/// A service that provides firebaseStorage.Reference instances.
class FirebaseStorageImpl implements FirebaseStorage {
  @override
  final FirebaseApp app;

  final Location _bucket;

  final HttpClient httpClient;

  FirebaseStorageImpl(this.app, String storageBucket, {http.Client httpClient})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        httpClient = HttpClient(httpClient ?? http.Client(), () async {
          var user = FirebaseAuth.instanceFor(app: app).currentUser;
          if (user == null) return null;

          var token = await user.getIdToken();
          return token;
        });

  /// Returns a firebaseStorage.Reference for the given path in the default
  /// bucket.
  @override
  StorageReference ref([String path]) {
    if (_bucket == null) {
      throw StorageException.noDefaultBucket();
    }

    var ref = StorageReferenceImpl(this, _bucket);
    if (path != null) {
      return ref.child(path);
    } else {
      return ref;
    }
  }

  Future<void> delete() async {}

  @override
  Future<int> getMaxDownloadRetryTimeMillis() {
    // TODO: implement getMaxDownloadRetryTimeMillis
    throw UnimplementedError();
  }

  @override
  Future<int> getMaxOperationRetryTimeMillis() async =>
      httpClient.maxUploadRetryTime.inMilliseconds;

  @override
  Future<int> getMaxUploadRetryTimeMillis() async =>
      httpClient.maxUploadRetryTime.inMilliseconds;

  @override
  Future<StorageReference> getReferenceFromUrl(String url) async {
    var location = Location.fromUrl(url);
    return StorageReferenceImpl(this, location);
  }

  @override
  Future<void> setMaxDownloadRetryTimeMillis(int millis) {
    // TODO: implement setMaxDownloadRetryTimeMillis
    throw UnimplementedError();
  }

  @override
  Future<void> setMaxOperationRetryTimeMillis(int millis) async {
    httpClient.maxOperationRetryTime = Duration(milliseconds: millis);
  }

  @override
  Future<void> setMaxUploadRetryTimeMillis(int millis) async {
    httpClient.maxUploadRetryTime = Duration(milliseconds: millis);
  }

  @override
  String get storageBucket => _bucket.bucket;
}
