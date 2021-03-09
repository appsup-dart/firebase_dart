import 'dart:convert';
import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/metadata.dart';
import 'package:http/http.dart' as http;
import '../impl/location.dart';

class BackendConnection {
  final Backend backend;

  BackendConnection(this.backend);

  Future<http.Response> handleRequest(http.Request request) async {
    if (!request.url.path.startsWith('/v0/b/')) {
      throw StorageException.internalError(
          'Invalid request ${request.method}${request.url}');
    }

    var bucket = request.url.pathSegments[2];
    var path = Uri.decodeComponent(request.url.pathSegments[4]);

    var location = Location(bucket, path.split('/'));
    switch (request.method) {
      case 'GET':
        var metadata = await backend.getMetadata(location);
        if (metadata == null) {
          return http.Response('Not found', 404);
        }
        return http.Response(json.encode(metadata), 200);
      default:
        throw UnimplementedError(
            '${request.method} requests to ${request.url}');
    }
  }
}

abstract class Backend {
  Future<StorageMetadataImpl> getMetadata(Location location);
}
