import 'dart:typed_data';

import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/src/storage/metadata.dart';
import 'package:firebase_dart/src/storage/reference.dart';
import 'package:firebase_dart/storage.dart';

import '../isolate.dart';

class IsolateFirebaseStorage extends IsolateFirebaseService
    implements FirebaseStorage {
  final Location _bucket;

  IsolateFirebaseStorage({IsolateFirebaseApp app, String storageBucket})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        super(app, 'storage:$storageBucket');

  @override
  Future<int> getMaxDownloadRetryTimeMillis() async {
    return await invoke('getMaxDownloadRetryTimeMillis', []);
  }

  @override
  Future<int> getMaxOperationRetryTimeMillis() async {
    return await invoke('getMaxOperationRetryTimeMillis', []);
  }

  @override
  Future<int> getMaxUploadRetryTimeMillis() async {
    return await invoke('getMaxUploadRetryTimeMillis', []);
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
    await invoke('setMaxDownloadRetryTimeMillis', [time]);
  }

  @override
  Future<void> setMaxOperationRetryTimeMillis(int time) async {
    await invoke('setMaxOperationRetryTimeMillis', [time]);
  }

  @override
  Future<void> setMaxUploadRetryTimeMillis(int time) async {
    await invoke('setMaxUploadRetryTimeMillis', [time]);
  }

  @override
  String get storageBucket => _bucket.bucket;
}

class IsolateStorageReference extends StorageReference {
  final IsolateFirebaseStorage storage;

  final Location location;

  IsolateStorageReference(this.storage, this.location);

  @override
  IsolateStorageReference child(String childPath) =>
      IsolateStorageReference(storage, location.child(childPath));

  dynamic invoke(String method, List<dynamic> arguments) {
    return storage.invoke(method, [location.uri.toString(), ...arguments]);
  }

  @override
  Future<void> delete() async {
    await invoke('delete', []);
  }

  @override
  Future<String> getBucket() async => location.bucket;

  @override
  Future<Uint8List> getData(int maxSize) async {
    return await invoke('getData', [maxSize]);
  }

  @override
  Future<Uri> getDownloadURL() async {
    return await invoke('getDownloadURL', []);
  }

  @override
  Future<StorageMetadata> getMetadata() async {
    return StorageMetadataX.fromJson(await invoke('getMetadata', []));
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
    return StorageMetadataX.fromJson(
        await invoke('updateMetadata', [metadata.toJson()]));
  }

  @override
  String get path => location.path;
}

extension StorageMetadataX on StorageMetadata {
  static StorageMetadata fromJson(Map<String, dynamic> json) =>
      StorageMetadataImpl.fromJson(json);

  Map<String, dynamic> toJson() => (this as StorageMetadataImpl).toJson();
}

class StoragePluginService extends PluginService {
  final FirebaseStorage storage;

  StoragePluginService(this.storage);

  @override
  dynamic invoke(String method, List<dynamic> arguments) {
    StorageReference getRef() {
      var location = Location.fromUrl(arguments.first);
      return StorageReferenceImpl(storage, location);
    }

    switch (method) {
      case 'getMaxDownloadRetryTimeMillis':
        return storage.getMaxDownloadRetryTimeMillis();
      case 'getMaxOperationRetryTimeMillis':
        return storage.getMaxOperationRetryTimeMillis();
      case 'getMaxUploadRetryTimeMillis':
        return storage.getMaxUploadRetryTimeMillis();
      case 'setMaxDownloadRetryTimeMillis':
        return storage.setMaxDownloadRetryTimeMillis(arguments.first);
      case 'setMaxOperationRetryTimeMillis':
        return storage.setMaxOperationRetryTimeMillis(arguments.first);
      case 'setMaxUploadRetryTimeMillis':
        return storage.setMaxUploadRetryTimeMillis(arguments.first);
      case 'delete':
        return getRef().delete();
      case 'getData':
        return getRef().getData(arguments[1]);
      case 'getDownloadURL':
        return getRef().getDownloadURL();
      case 'getMetadata':
        return getRef().getMetadata().then((v) => v.toJson());
      case 'putData':
        throw UnimplementedError();
      case 'updateMetadata':
        return getRef()
            .updateMetadata(StorageMetadataX.fromJson(arguments[1]))
            .then((v) => v.toJson());
    }
  }
}
