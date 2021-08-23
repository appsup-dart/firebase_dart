import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_dart/src/storage.dart';

import 'location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../metadata.dart';

class ResourceClient {
  /// Domain name for firebase storage.
  static const defaultHost = 'firebasestorage.googleapis.com';

  final http.Client httpClient;

  final Location location;

  ResourceClient(this.location, this.httpClient);

  Uri _makeUrl(String urlPart) {
    return Uri.parse('https://$defaultHost/v0$urlPart');
  }

  Uri get url => _makeUrl(location.fullServerUrl());

  Future<FullMetadataImpl> getMetadata() async {
    var response = await httpClient.get(url);

    var obj = _handleResponse(response);

    return FullMetadataImpl.fromJson(obj);
  }

  Future<Map<String, dynamic>?> getList(
      {String? delimiter, String? pageToken, int? maxResults}) async {
    var uri =
        _makeUrl(location.bucketOnlyServerUrl()).replace(queryParameters: {
      'prefix': location.isRoot ? '' : '${location.path}/',
      if (delimiter != null && delimiter.isNotEmpty) 'delimiter': delimiter,
      if (pageToken != null) 'pageToken': pageToken,
      if (maxResults != null) 'maxResults': maxResults.toString(),
    });

    var response = await httpClient.get(uri);
    return _handleResponse(response);
  }

  Future<String?> getDownloadUrl() async {
    var metadata = await getMetadata();
    if (metadata.downloadTokens == null || metadata.downloadTokens!.isEmpty) {
      // This can happen if objects are uploaded through GCS and retrieved
      // through list, so we don't want to throw an Error.
      return null;
    }
    var token = metadata.downloadTokens!.first;
    var urlPart = '/b/' +
        Uri.encodeComponent(metadata.bucket!) +
        '/o/' +
        Uri.encodeComponent(metadata.fullPath);
    var base = _makeUrl(urlPart);
    return base
        .replace(queryParameters: {'alt': 'media', 'token': token}).toString();
  }

  Future<FullMetadataImpl> updateMetadata(SettableMetadata metadata) async {
    var response = await httpClient.patch(url,
        body: json.encode({
          if (metadata.cacheControl != null)
            'cacheControl': metadata.cacheControl,
          if (metadata.contentDisposition != null)
            'contentDisposition': metadata.contentDisposition,
          if (metadata.contentEncoding != null)
            'contentEncoding': metadata.contentEncoding,
          if (metadata.contentType != null) 'contentType': metadata.contentType,
          if (metadata.contentLanguage != null)
            'contentLanguage': metadata.contentLanguage,
          if (metadata.customMetadata != null)
            'metadata': metadata.customMetadata
        }),
        headers: {'Content-Type': 'application/json; charset=utf-8'});

    var obj = _handleResponse(response);

    return FullMetadataImpl.fromJson(obj);
  }

  Future<void> deleteObject() async {
    var response = await httpClient.delete(url,
        headers: {'Content-Type': 'application/json; charset=utf-8'});

    _handleResponse(response);
  }

  /// upload as Content-Type: multipart.
  Future<FullMetadataImpl> multipartUpload(
      Uint8List blob, SettableMetadata? metadata) async {
    String generateBoundary() {
      var random = Random(DateTime.now().millisecondsSinceEpoch);
      return Iterable.generate(32, (i) => random.nextInt(10)).join();
    }

    final boundary = generateBoundary();

    final _metadata = {
      ...?metadata?.asMap(),
      'fullPath': location.path,
      'size': blob.length,
    };
    final metadataString = json.encode(_metadata);
    final preBlobPart = '--$boundary\r\n'
        'Content-Type: application/json; charset=utf-8\r\n\r\n'
        '$metadataString\r\n'
        '--$boundary\r\n'
        'Content-Type: ${metadata?.contentType ?? 'application/octet-stream'}'
        '\r\n\r\n';

    final postBlobPart = '\r\n--$boundary--';

    final body = Uint8List.fromList([
      ...utf8.encode(preBlobPart),
      ...blob,
      ...utf8.encode(postBlobPart),
    ]);

    final url = _makeUrl(location.bucketOnlyServerUrl())
        .replace(queryParameters: {'name': _metadata['fullPath']!});

    var response = await httpClient.post(url,
        headers: {
          'X-Goog-Upload-Protocol': 'multipart',
          'Content-Type': 'multipart/related; boundary=$boundary'
        },
        body: body);

    var obj = _handleResponse(response);

    return FullMetadataImpl.fromJson(obj);
  }

  Future<Uri> startResumableUpload(
      Uint8List blob, SettableMetadata? metadata) async {
    final _metadata = {
      ...?metadata?.asMap(),
      'fullPath': location.path,
      'size': blob.length,
    };

    final url = _makeUrl(location.bucketOnlyServerUrl())
        .replace(queryParameters: {'name': _metadata['fullPath']!});

    var response = await httpClient.post(url,
        headers: {
          'X-Goog-Upload-Protocol': 'resumable',
          'X-Goog-Upload-Command': 'start',
          'X-Goog-Upload-Header-Content-Length': '${blob.length}',
          'X-Goog-Upload-Header-Content-Type':
              metadata?.contentType ?? 'application/octet-stream',
          'Content-Type': 'application/json; charset=utf-8'
        },
        body: json.encode(_metadata));

    _handleResponse(response);

    return Uri.parse(response.headers['x-goog-upload-url']!);
  }

  Future<ResumableUploadStatus> getResumableUploadStatus(
      Uri url, Uint8List blob) async {
    var response = await httpClient.post(url, headers: {
      'X-Goog-Upload-Command': 'query',
    });

    _handleResponse(response);

    var uploadStatus = response.headers['x-goog-upload-status'];
    var size = int.parse(response.headers['X-Goog-Upload-Size-Received']!);

    return ResumableUploadStatus(size, blob.length, uploadStatus == 'final');
  }

  Future<ResumableUploadStatus> continueResumableUpload(
    Uri url,
    Uint8List blob,
    int chunkSize, [
    ResumableUploadStatus? status,
    void Function(int, int)? progressCallback,
  ]) async {
    assert(status == null || !status.finalized);
    final status_ = ResumableUploadStatus(
        status?.current ?? 0, status?.total ?? blob.length);

    if (blob.length != status_.total) {
      throw StorageException.serverFileWrongSize();
    }

    final bytesLeft = status_.total - status_.current;
    var bytesToUpload = bytesLeft;
    if (chunkSize > 0) {
      bytesToUpload = min(bytesToUpload, chunkSize);
    }
    final startByte = status_.current;
    final endByte = startByte + bytesToUpload;
    final uploadCommand =
        bytesToUpload == bytesLeft ? 'upload, finalize' : 'upload';
    final body = blob.sublist(startByte, endByte);

    var response = await httpClient.post(url,
        headers: {
          'X-Goog-Upload-Command': uploadCommand,
          'X-Goog-Upload-Offset': '${status_.current}'
        },
        body: body);
    var v = _handleResponse(response);

    var uploadStatus = response.headers['x-goog-upload-status'];

    return ResumableUploadStatus(
        status_.current + bytesToUpload,
        blob.length,
        uploadStatus == 'final',
        uploadStatus == 'final' ? FullMetadataImpl.fromJson(v) : null);
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        if ((response.headers['Content-type'] ?? 'application/json')
                .split(';')
                .first ==
            'application/json') {
          return json.decode(response.body);
        }
        return response.body;
      case 204:
        return null;
      default:
        throw _httpStatusCodeToError(response.statusCode);
    }
  }

  StorageException _httpStatusCodeToError(int statusCode) {
    switch (statusCode) {
      case 401:
        return StorageException.unauthenticated();
      case 402:
        return StorageException.quotaExceeded(location.bucket);
      case 403:
        return StorageException.unauthorized(location.path);
      case 404:
        return StorageException.objectNotFound(location.path);
      default:
        return StorageException.unknown();
    }
  }
}

class ListResultImpl extends ListResult {
  @override
  final List<Reference> items;

  @override
  final String? nextPageToken;

  @override
  final List<Reference> prefixes;

  @override
  final FirebaseStorage storage;

  ListResultImpl(this.storage,
      {required this.items, this.nextPageToken, required this.prefixes});

  ListResultImpl.fromJson(Reference reference, Map<String, dynamic> json)
      : this(reference.storage,
            items: (json['items'] as List)
                .map((v) => reference.child(v['name']))
                .toList(),
            nextPageToken: json['nextPageToken'],
            prefixes: (json['prefixes'] as List).map((v) => reference.child(v))
                as List<Reference>);
}

class ResumableUploadStatus {
  final bool finalized;
  final FullMetadata? metadata;

  final int current;
  final int total;

  ResumableUploadStatus(this.current, this.total,
      [this.finalized = false, this.metadata]);
}
