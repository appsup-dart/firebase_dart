import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/storage.dart';
import 'package:meta/meta.dart';

import '../isolate.dart';
import 'util.dart';

class StorageFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final String bucket;
  final Symbol functionName;

  StorageFunctionCall(this.functionName, this.appName, this.bucket,
      [List<dynamic> positionalArguments, Map<Symbol, dynamic> namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseStorage get storage =>
      FirebaseStorage.instanceFor(app: Firebase.app(appName), bucket: bucket);

  @override
  Function get function {
    switch (functionName) {
      case #getMaxDownloadRetryTimeMillis:
        return storage.getMaxDownloadRetryTimeMillis;
      case #getMaxOperationRetryTimeMillis:
        return storage.getMaxOperationRetryTimeMillis;
      case #getMaxUploadRetryTimeMillis:
        return storage.getMaxUploadRetryTimeMillis;
      case #setMaxDownloadRetryTimeMillis:
        return storage.setMaxDownloadRetryTimeMillis;
      case #setMaxOperationRetryTimeMillis:
        return storage.setMaxOperationRetryTimeMillis;
      case #setMaxUploadRetryTimeMillis:
        return storage.setMaxUploadRetryTimeMillis;
    }
    return null;
  }
}

class StorageReferenceFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final String bucket;
  final String path;
  final Symbol functionName;

  StorageReferenceFunctionCall(
      this.functionName, this.appName, this.bucket, this.path,
      [List<dynamic> positionalArguments, Map<Symbol, dynamic> namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseStorage get storage =>
      FirebaseStorage.instanceFor(app: Firebase.app(appName), bucket: bucket);

  StorageReference getRef() => storage.ref().child(path);

  @override
  Function get function {
    switch (functionName) {
      case #delete:
        return getRef().delete;
      case #getData:
        return getRef().getData;
      case #getDownloadURL:
        return getRef().getDownloadURL;
      case #getMetadata:
        return getRef().getMetadata;
      case #putData:
        throw UnimplementedError();
      case #updateMetadata:
        return getRef().updateMetadata;
    }
    return null;
  }
}

class IsolateFirebaseStorage extends IsolateFirebaseService
    implements FirebaseStorage {
  final Location _bucket;

  IsolateFirebaseStorage(
      {@required IsolateFirebaseApp app, String storageBucket})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        super(app);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments]) {
    return app.commander.execute(StorageFunctionCall<FutureOr<T>>(
        method, app.name, storageBucket, positionalArguments, namedArguments));
  }

  @override
  Future<int> getMaxDownloadRetryTimeMillis() async {
    return await invoke(#getMaxDownloadRetryTimeMillis, []);
  }

  @override
  Future<int> getMaxOperationRetryTimeMillis() async {
    return await invoke(#getMaxOperationRetryTimeMillis, []);
  }

  @override
  Future<int> getMaxUploadRetryTimeMillis() async {
    return await invoke(#getMaxUploadRetryTimeMillis, []);
  }

  @override
  Future<StorageReference> getReferenceFromUrl(String fullUrl) async {
    var location = Location.fromUrl(fullUrl);
    return IsolateStorageReference(this, location);
  }

  @override
  StorageReference ref([String path]) {
    if (_bucket == null) {
      throw StorageException.noDefaultBucket();
    }

    var ref = IsolateStorageReference(this, _bucket);
    if (path != null) {
      return ref.child(path);
    } else {
      return ref;
    }
  }

  @override
  Future<void> setMaxDownloadRetryTimeMillis(int time) async {
    await invoke(#setMaxDownloadRetryTimeMillis, [time]);
  }

  @override
  Future<void> setMaxOperationRetryTimeMillis(int time) async {
    await invoke(#setMaxOperationRetryTimeMillis, [time]);
  }

  @override
  Future<void> setMaxUploadRetryTimeMillis(int time) async {
    await invoke(#setMaxUploadRetryTimeMillis, [time]);
  }

  @override
  String get storageBucket => _bucket.bucket;
}

class IsolateStorageReference extends StorageReference {
  final IsolateFirebaseStorage storage;

  final Location location;

  IsolateStorageReference(this.storage, this.location);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic> positionalArguments,
      Map<Symbol, dynamic> namedArguments]) {
    return storage.app.commander.execute(
        StorageReferenceFunctionCall<FutureOr<T>>(
            method,
            storage.app.name,
            storage.storageBucket,
            location.path,
            positionalArguments,
            namedArguments));
  }

  @override
  IsolateStorageReference child(String childPath) =>
      IsolateStorageReference(storage, location.child(childPath));

  @override
  Future<void> delete() async {
    await invoke(#delete, []);
  }

  @override
  Future<String> getBucket() async => location.bucket;

  @override
  Future<Uint8List> getData(int maxSize) async {
    return await invoke(#getData, [maxSize]);
  }

  @override
  Future<Uri> getDownloadURL() async {
    return await invoke(#getDownloadURL, []);
  }

  @override
  Future<StorageMetadata> getMetadata() async {
    return await invoke(#getMetadata, []);
  }

  @override
  Future<String> getName() async => location.name;

  @override
  IsolateStorageReference getParent() {
    var parentLocation = location.getParent();
    if (parentLocation == null) return null;
    return IsolateStorageReference(storage, parentLocation);
  }

  @override
  Future<String> getPath() async => location.path;

  @override
  StorageReference getRoot() {
    return IsolateStorageReference(storage, location.getRoot());
  }

  @override
  FirebaseStorage getStorage() => storage;

  @override
  StorageUploadTask putData(Uint8List data, [StorageMetadata metadata]) {
    // TODO: implement putData
    throw UnimplementedError();
  }

  @override
  Future<StorageMetadata> updateMetadata(StorageMetadata metadata) async {
    return await invoke(#updateMetadata, [metadata]);
  }

  @override
  String get path => location.path;
}
