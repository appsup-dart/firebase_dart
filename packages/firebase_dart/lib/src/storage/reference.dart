// @dart=2.9

import 'dart:typed_data';

import 'package:firebase_dart/src/storage.dart';

import 'impl/location.dart';
import 'impl/resource_client.dart';
import 'service.dart';

/// Provides methods to interact with a bucket in the Firebase Storage service.
class ReferenceImpl implements Reference {
  final Location location;

  @override
  final FirebaseStorageImpl storage;

  final ResourceClient requests;

  ReferenceImpl(this.storage, this.location)
      : requests = ResourceClient(location, storage.httpClient);

  /// The URL for the bucket and path this object references, in the form
  /// gs://<bucket>/<object-path>
  @override
  String toString() => location.toString();

  /// A reference to the object obtained by appending childPath, removing any
  /// duplicate, beginning, or trailing slashes.
  @override
  ReferenceImpl child(String childPath) =>
      ReferenceImpl(storage, location.child(childPath));

  /// A reference to the parent of the current object, or null if the current
  /// object is the root.
  @override
  ReferenceImpl get parent {
    var parentLocation = location.getParent();
    if (parentLocation == null) return null;
    return ReferenceImpl(storage, parentLocation);
  }

  /// An reference to the root of this object's bucket.
  @override
  ReferenceImpl get root {
    return ReferenceImpl(storage, location.getRoot());
  }

  @override
  Future<String> getDownloadURL() async {
    _throwIfRoot('getDownloadURL');
    var url = await requests.getDownloadUrl();
    if (url == null) {
      throw StorageException.noDownloadURL();
    }
    return url;
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
  String get bucket => location.bucket;

  @override
  Future<Uint8List> getData([int maxSize = 10485760]) async {
    var url = await getDownloadURL();
    var response = await storage.httpClient.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw StorageException.internalError(
        'Unable to download $fullPath: ${response.reasonPhrase}');
  }

  @override
  Future<FullMetadata> getMetadata() async {
    _throwIfRoot('getMetadata');
    return await requests.getMetadata();
  }

  @override
  String get name => location.name;

  @override
  String get fullPath => location.path;

  @override
  UploadTask putData(Uint8List data, [SettableMetadata metadata]) {
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
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
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
      other is ReferenceImpl && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  Future<ListResult> list([ListOptions options]) {
    // TODO: implement list
    throw UnimplementedError();
  }

  @override
  Future<ListResult> listAll() {
    // TODO: implement listAll
    throw UnimplementedError();
  }

  @override
  UploadTask putString(String data,
      {PutStringFormat format = PutStringFormat.raw,
      SettableMetadata metadata}) {
    // TODO: implement putString
    throw UnimplementedError();
  }
}
