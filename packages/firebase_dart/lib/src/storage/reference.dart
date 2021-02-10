import 'dart:typed_data';

import 'package:firebase_dart/src/storage.dart';

import 'impl/location.dart';
import 'impl/resource_client.dart';
import 'service.dart';

/// Provides methods to interact with a bucket in the Firebase Storage service.
class StorageReferenceImpl implements StorageReference {
  final Location location;

  final FirebaseStorageImpl storage;

  final ResourceClient requests;

  StorageReferenceImpl(this.storage, this.location)
      : requests = ResourceClient(location, storage.httpClient);

  /// The URL for the bucket and path this object references, in the form
  /// gs://<bucket>/<object-path>
  @override
  String toString() => location.toString();

  /// A reference to the object obtained by appending childPath, removing any
  /// duplicate, beginning, or trailing slashes.
  @override
  StorageReferenceImpl child(String childPath) =>
      StorageReferenceImpl(storage, location.child(childPath));

  /// A reference to the parent of the current object, or null if the current
  /// object is the root.
  @override
  StorageReferenceImpl getParent() {
    var parentLocation = location.getParent();
    if (parentLocation == null) return null;
    return StorageReferenceImpl(storage, parentLocation);
  }

  /// An reference to the root of this object's bucket.
  @override
  StorageReferenceImpl getRoot() {
    return StorageReferenceImpl(storage, location.getRoot());
  }

  @override
  Future<Uri> getDownloadURL() async {
    _throwIfRoot('getDownloadURL');
    var url = await requests.getDownloadUrl();
    if (url == null) {
      throw StorageException.noDownloadURL();
    }
    return Uri.parse(url);
  }

  void _throwIfRoot(String name) {
    if (location.path == '') {
      throw StorageException.invalidRootOperation(name);
    }
  }

  @override
  Future<void> delete() {
    _throwIfRoot('delete');

/*
    return this.authWrapper.getAuthToken().then((authToken) {
      var requestInfo = requests.deleteObject(self.authWrapper, self.location);
      return self.authWrapper.makeRequest(requestInfo, authToken).getFuture();
    });
*/
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future<String> getBucket() async => location.bucket;

  @override
  Future<Uint8List> getData(int maxSize) async {
    var url = await getDownloadURL();
    var response = await storage.httpClient.get(url);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw StorageException.internalError(
        'Unable to download $path: ${response.reasonPhrase}');
  }

  @override
  Future<StorageMetadata> getMetadata() async {
    _throwIfRoot('getMetadata');
    return await requests.getMetadata();
  }

  @override
  Future<String> getName() async => location.name;

  @override
  Future<String> getPath() async => location.path;

  @override
  FirebaseStorage getStorage() => storage;

  @override
  String get path => location.path;

  @override
  StorageUploadTask putData(Uint8List data, [StorageMetadata metadata]) {
    // TODO: implement putData
/*
    args.validate(
        'put', [args.uploadDataSpec(), args.metadataSpec(true)], arguments);
    this._throwIfRoot('put');
    return new UploadTask(this, this.authWrapper, this.location,
        this.mappings(), new FbsBlob(data), metadata);
*/

    throw UnimplementedError();
  }

  @override
  Future<StorageMetadata> updateMetadata(StorageMetadata metadata) async {
    _throwIfRoot('updateMetadata');

/* TODO
    var requestInfo = requests.updateMetadata(
        self.authWrapper, self.location, metadata, self.mappings());
    return self.authWrapper.makeRequest(requestInfo, authToken).getFuture();
*/
    throw UnimplementedError();
  }

  @override
  bool operator ==(other) =>
      other is StorageReferenceImpl && other.location == location;

  @override
  int get hashCode => location.hashCode;
}
