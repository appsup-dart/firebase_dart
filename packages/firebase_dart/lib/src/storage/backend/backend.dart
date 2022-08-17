import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/metadata.dart';
import 'package:http/http.dart' as http;
import '../impl/location.dart';

class BackendConnection {
  final StorageBackend backend;

  BackendConnection(this.backend);

  Future<http.Response> handleRequest(http.Request request) async {
    if (!request.url.path.startsWith('/v0/b/')) {
      throw StorageException.internalError(
          'Invalid request ${request.method}${request.url}');
    }

    var bucket = request.url.pathSegments[2];

    if (request.url.pathSegments.length == 4) {
      switch (request.method) {
        case 'GET':
          var path = request.url.queryParameters['prefix']!;
          var location = Location(bucket, path.split('/'));
          var pageToken = request.url.queryParameters['pageToken'];
          var maxResults = request.url.queryParameters['maxResults'];

          var v = await backend.list(
              location,
              ListOptions(
                  pageToken: pageToken,
                  maxResults:
                      maxResults != null ? int.parse(maxResults) : null));

          return http.Response(json.encode(v), 200,
              headers: {'Content-Type': 'application/json'}, request: request);

        case 'POST':
          switch (request.headers['X-Goog-Upload-Protocol']) {
            case 'multipart':
              var boundary = RegExp(r'multipart/related; boundary=(\d*)')
                  .firstMatch(request.headers['Content-Type']!)!
                  .group(1)!;
              boundary = '--$boundary';

              var parts =
                  String.fromCharCodes(request.bodyBytes).split(boundary);

              var re = RegExp(r'^\r\nContent-Type: ([^\r\n]*)\r\n\r\n(.*)\r\n');
              var m = re.firstMatch(parts[1])!;
              var metadata = json.decode(m.group(2)!);

              m = re.firstMatch(parts[2])!;
              var contentType = m.group(1)!;
              var content = m.group(2)!.codeUnits;

              var location =
                  Location(bucket, (metadata['fullPath'] as String).split('/'));

              await backend.putData(
                location,
                Uint8List.fromList(content),
                SettableMetadata(
                    cacheControl: metadata['cacheControl'],
                    contentDisposition: metadata['contentDisposition'],
                    contentEncoding: metadata['contentEncoding'],
                    contentLanguage: metadata['contentLanguage'],
                    contentType: metadata['contentType'] ?? contentType,
                    customMetadata:
                        (metadata['customMetadata'] as Map?)?.cast()),
              );

              var fullMetadata = await backend.getMetadata(location);
              return http.Response(json.encode(fullMetadata), 200,
                  headers: {'Content-Type': 'application/json'},
                  request: request);
            case 'resumable':
          }
      }
    } else if (request.url.pathSegments.length == 5) {
      var path = Uri.decodeComponent(request.url.pathSegments[4]);

      var location = Location(bucket, path.split('/'));
      switch (request.method) {
        case 'GET':
          var metadata = await backend.getMetadata(location);
          if (metadata == null) {
            return http.Response('Not found', 404, request: request);
          }
          return http.Response(json.encode(metadata), 200,
              headers: {'Content-Type': 'application/json'}, request: request);
        case 'PATCH':
          var map = json.decode(request.body);

          var metadata = await backend.updateMetadata(
              location,
              SettableMetadata(
                  cacheControl: map['cacheControl'],
                  contentDisposition: map['contentDisposition'],
                  contentEncoding: map['contentEncoding'],
                  contentLanguage: map['contentLanguage'],
                  contentType: map['contentType'],
                  customMetadata: (map['metadata'] as Map?)?.cast()));
          if (metadata == null) {
            return http.Response('Not found', 404, request: request);
          }
          return http.Response(json.encode(metadata), 200, request: request);
        case 'DELETE':
          await backend.delete(location);

          return http.Response('', 200,
              headers: {'Content-Type': 'text/plain'}, request: request);
      }
    }
    throw UnimplementedError('${request.method} requests to ${request.url}');
  }
}

abstract class StorageBackend {
  Future<FullMetadataImpl?> getMetadata(Location location);

  Future<FullMetadataImpl?> updateMetadata(
      Location location, SettableMetadata metadata);

  Future<void> putData(
      Location location, Uint8List data, SettableMetadata metadata);

  Future<Map<String, dynamic>> list(Location location, ListOptions listOptions);

  Future<bool> delete(Location location);
}
