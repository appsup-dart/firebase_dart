import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/storage.dart';

import '../isolate.dart';
import 'util.dart';

class StorageReferenceFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final String bucket;
  final String path;
  final Symbol functionName;

  StorageReferenceFunctionCall(
      this.functionName, this.appName, this.bucket, this.path,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseStorage get storage =>
      FirebaseStorage.instanceFor(app: Firebase.app(appName), bucket: bucket);

  Reference getRef() => storage.ref().child(path);

  @override
  Function? get function {
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
      {required IsolateFirebaseApp app, String? storageBucket})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        super(app);

  @override
  Reference refFromURL(String fullUrl) {
    var location = Location.fromUrl(fullUrl);
    return IsolateStorageReference(this, location);
  }

  @override
  Reference ref([String? path]) {
    var ref = IsolateStorageReference(this, _bucket);
    if (path != null) {
      return ref.child(path);
    } else {
      return ref;
    }
  }

  @override
  String get bucket => _bucket.bucket;

  @override
  // TODO: implement maxDownloadRetryTime
  Duration get maxDownloadRetryTime => throw UnimplementedError();

  @override
  // TODO: implement maxOperationRetryTime
  Duration get maxOperationRetryTime => throw UnimplementedError();

  @override
  // TODO: implement maxUploadRetryTime
  Duration get maxUploadRetryTime => throw UnimplementedError();

  @override
  void setMaxDownloadRetryTime(Duration time) {
    // TODO: implement setMaxDownloadRetryTime
  }

  @override
  void setMaxOperationRetryTime(Duration time) {
    // TODO: implement setMaxOperationRetryTime
  }

  @override
  void setMaxUploadRetryTime(Duration time) {
    // TODO: implement setMaxUploadRetryTime
  }
}

class IsolateStorageReference extends Reference {
  @override
  final IsolateFirebaseStorage storage;

  final Location location;

  IsolateStorageReference(this.storage, this.location);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) {
    return storage.app.commander.execute(
        StorageReferenceFunctionCall<FutureOr<T>>(
            method,
            storage.app.name,
            storage.bucket,
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
  String get bucket => location.bucket;

  @override
  Future<Uint8List> getData([int? maxSize = 10485760]) async {
    return await invoke(#getData, [maxSize]);
  }

  @override
  Future<String> getDownloadURL() async {
    return await invoke(#getDownloadURL, []);
  }

  @override
  Future<FullMetadata> getMetadata() async {
    return await invoke(#getMetadata, []);
  }

  @override
  String get name => location.name;

  @override
  IsolateStorageReference? get parent {
    var parentLocation = location.getParent();
    if (parentLocation == null) return null;
    return IsolateStorageReference(storage, parentLocation);
  }

  @override
  String get fullPath => location.path;

  @override
  Reference get root {
    return IsolateStorageReference(storage, location.getRoot());
  }

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    // TODO: implement putData
    throw UnimplementedError();
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    return await invoke(#updateMetadata, [metadata]);
  }

  @override
  Future<ListResult> list([ListOptions? options]) {
    return invoke(#list, [options]);
  }

  @override
  Future<ListResult> listAll() {
    return invoke(#listAll);
  }

  @override
  UploadTask putString(String data,
      {PutStringFormat format = PutStringFormat.raw,
      SettableMetadata? metadata}) {
    // TODO: implement putString
    throw UnimplementedError();
  }

  @override
  String toString() => location.toString();

  @override
  bool operator ==(other) =>
      other is IsolateStorageReference && other.location == location;

  @override
  int get hashCode => location.hashCode;
}
