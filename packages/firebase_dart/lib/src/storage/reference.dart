import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_dart/src/storage.dart';

import 'impl/location.dart';
import 'impl/resource_client.dart';
import 'impl/task.dart';
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
  ReferenceImpl? get parent {
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
  Future<void> delete() async {
    _throwIfRoot('delete');

    await requests.deleteObject();
  }

  @override
  String get bucket => location.bucket;

  @override
  Future<Uint8List> getData([int? maxSize = 10485760]) async {
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
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    _throwIfRoot('putData');

    return UploadTaskImpl(this, data, metadata);
  }

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    _throwIfRoot('updateMetadata');

    return await requests.updateMetadata(metadata);
  }

  @override
  bool operator ==(other) =>
      other is ReferenceImpl && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  Future<ListResult> list([ListOptions? options]) async {
    var v = await requests.getList(
        delimiter: '/',
        maxResults: options?.maxResults,
        pageToken: options?.pageToken);

    return ListResultImpl.fromJson(this, v!);
  }

  @override
  Future<ListResult> listAll() async {
    var v = await list();
    var items = [...v.items];
    var prefixes = [...v.prefixes];
    while (v.nextPageToken != null) {
      v = await list(ListOptions(pageToken: v.nextPageToken));
      items.addAll(v.items);
      prefixes.addAll(v.prefixes);
    }

    return ListResultImpl(this, items: items, prefixes: prefixes);
  }

  @override
  UploadTask putString(String data,
      {PutStringFormat format = PutStringFormat.raw,
      SettableMetadata? metadata}) {
    _throwIfRoot('putString');

    var d = _dataFromString(format, data);
    if (metadata?.contentType == null) {
      metadata = SettableMetadata(
          cacheControl: metadata?.cacheControl,
          contentDisposition: metadata?.contentDisposition,
          contentEncoding: metadata?.contentEncoding,
          contentLanguage: metadata?.contentLanguage,
          customMetadata: metadata?.customMetadata,
          contentType: d.mimeType);
    }
    return putData(d.contentAsBytes(), metadata);
  }

  static UriData _dataFromString(PutStringFormat format, String stringData) {
    switch (format) {
      case PutStringFormat.raw:
        return UriData.fromString(stringData);
      case PutStringFormat.base64:
        return UriData.fromBytes(base64.decode(stringData));
      case PutStringFormat.base64Url:
        return UriData.fromBytes(base64Url.decode(stringData));
      case PutStringFormat.dataUrl:
        return UriData.fromUri(Uri.parse(stringData));
    }
  }
}
