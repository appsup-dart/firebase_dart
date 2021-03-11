// @dart=2.9

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

  Future<Map<String, dynamic>> getList(
      {String delimiter, String pageToken, int maxResults}) async {
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

  Future<String> getDownloadUrl() async {
    var metadata = await getMetadata();
    if (metadata.downloadTokens == null || metadata.downloadTokens.isEmpty) {
      // This can happen if objects are uploaded through GCS and retrieved
      // through list, so we don't want to throw an Error.
      return null;
    }
    var token = metadata.downloadTokens.first;
    var urlPart = '/b/' +
        Uri.encodeComponent(metadata.bucket) +
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

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return json.decode(response.body);
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
  final String nextPageToken;

  @override
  final List<Reference> prefixes;

  @override
  final FirebaseStorage storage;

  ListResultImpl(this.storage, {this.items, this.nextPageToken, this.prefixes});

  ListResultImpl.fromJson(Reference reference, Map<String, dynamic> json)
      : this(reference.storage,
            items: (json['items'] as List)
                .map((v) => reference.child(v['name']))
                .toList(),
            nextPageToken: json['nextPageToken'],
            prefixes:
                (json['prefixes'] as List).map((v) => reference.child(v)));
}
