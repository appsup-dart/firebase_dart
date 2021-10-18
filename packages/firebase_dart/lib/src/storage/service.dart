import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/core/impl/app.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:firebase_dart/src/storage.dart';
import 'package:http/http.dart' as http;

import 'impl/http_client.dart';
import 'impl/location.dart';
import 'reference.dart';

/// A service that provides firebaseStorage.Reference instances.
class FirebaseStorageImpl extends FirebaseService implements FirebaseStorage {
  final Location _bucket;

  final HttpClient httpClient;

  FirebaseStorageImpl(FirebaseApp app, String? storageBucket,
      {http.Client? httpClient})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        httpClient = HttpClient(httpClient ?? http.Client(), () async {
          return AuthTokenProvider.fromFirebaseAuth(
                  FirebaseAuth.instanceFor(app: app))
              .getToken();
        }),
        super(app);

  /// Returns a firebaseStorage.Reference for the given path in the default
  /// bucket.
  @override
  Reference ref([String? path]) {
    var ref = ReferenceImpl(this, _bucket);
    if (path != null) {
      return ref.child(path);
    } else {
      return ref;
    }
  }

  @override
  Duration get maxDownloadRetryTime {
    // TODO: implement getMaxDownloadRetryTimeMillis
    throw UnimplementedError();
  }

  @override
  Duration get maxOperationRetryTime =>
      Duration(milliseconds: httpClient.maxUploadRetryTime.inMilliseconds);

  @override
  Duration get maxUploadRetryTime =>
      Duration(milliseconds: httpClient.maxUploadRetryTime.inMilliseconds);

  @override
  Reference refFromURL(String url) {
    var location = Location.fromUrl(url);
    return ReferenceImpl(this, location);
  }

  @override
  void setMaxDownloadRetryTime(Duration time) {
    // TODO: implement setMaxDownloadRetryTimeMillis
    throw UnimplementedError();
  }

  @override
  void setMaxOperationRetryTime(Duration time) {
    httpClient.maxOperationRetryTime = time;
  }

  @override
  void setMaxUploadRetryTime(Duration time) {
    httpClient.maxUploadRetryTime = time;
  }

  @override
  String get bucket => _bucket.bucket;
}
