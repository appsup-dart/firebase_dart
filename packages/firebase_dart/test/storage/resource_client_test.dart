// @dart=2.9

import 'dart:async';
import 'dart:convert';

import 'package:firebase_dart/src/storage.dart';
import 'package:firebase_dart/src/storage/impl/http_client.dart';
import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/src/storage/impl/resource_client.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() async {
  group('ResourceClient', () {
    var normalBucket = 'b';
    var locationRoot = Location.fromBucketSpec(normalBucket);
    var locationNormal = locationRoot.child('o');
    var locationNormalUrl = '/b/' + normalBucket + '/o/o';
    var locationNormalNoObjUrl = '/b/' + normalBucket + '/o';
    var locationEscapes = Location.fromBucketSpec('b/').child('o?');
    var locationEscapesUrl = '/b/b%2F/o/o%3F';

    String token;
    FutureOr<Response> Function(Request) handler;
    var httpClient = HttpClient(MockClient((request) async {
      return handler(request);
    }), () async => token);

    group('ResourceClient.getMetadata', () {
      test('ResourceClient.getMetadata: success', () async {
        var locations = {
          locationNormal: locationNormalUrl,
          locationEscapes: locationEscapesUrl
        };

        for (var location in locations.keys) {
          var url = locations[location];

          var client = ResourceClient(location, httpClient);

          var now = DateTime.now();
          handler = (request) {
            expect(request.url.path, '/v0$url');
            expect(request.method, 'GET');
            return Response(
                json.encode({
                  'bucket': normalBucket,
                  'generation': '1',
                  'metageneration': '2',
                  'name': 'foo/bar/baz.png',
                  'size': '10',
                  'timeCreated': now.toIso8601String(),
                  'updated': now.toIso8601String(),
                  'md5Hash': 'deadbeef',
                  'cacheControl': 'max-age=604800',
                  'contentDisposition': 'Attachment; filename=baz.png',
                  'contentLanguage': 'en-US',
                  'contentType': 'application/json',
                  'downloadTokens': 'a,b,c',
                  'metadata': {'foo': 'bar'}
                }),
                200);
          };
          var response = await client.getMetadata();

          expect(response.bucket, normalBucket);
          expect(response.generation, '1');
          expect(response.metadataGeneration, '2');
          expect(response.path, 'foo/bar/baz.png');
          expect(response.name, 'baz.png');
          expect(response.sizeBytes, 10);
          expect(response.creationTime, now);
          expect(response.md5Hash, 'deadbeef');
          expect(response.cacheControl, 'max-age=604800');
          expect(response.contentDisposition, 'Attachment; filename=baz.png');
          expect(response.contentLanguage, 'en-US');
          expect(response.contentType, 'application/json');
          expect(response.downloadTokens, ['a', 'b', 'c']);
          expect(response.customMetadata, {'foo': 'bar'});
        }
      });
    });

    group('ResourceClient.list', () {
      test('ResourceClient.list: success', () async {
        var client = ResourceClient(locationNormal, httpClient);

        handler = (request) {
          expect(request.url.path, '/v0$locationNormalNoObjUrl');
          expect(request.method, 'GET');
          expect(request.url.queryParameters, {
            'delimiter': '/',
            'pageToken': 'page_token',
            'maxResults': '4',
            'prefix': client.location.path + '/',
          });
          return Response(
              json.encode({
                'prefixes': ['a/f/'],
                'items': [
                  {'name': 'a/a', 'bucket': 'fredzqm-staging'},
                  {'name': 'a/b', 'bucket': 'fredzqm-staging'}
                ],
                'nextPageToken': 'YS9mLw=='
              }),
              200);
        };

        var response = await client.getList(
            delimiter: '/', pageToken: 'page_token', maxResults: 4);

        expect(response.prefixes[0], 'a/f/');
        expect(response.items[0].path, 'a/a');
        expect(response.items[1].path, 'a/b');
        expect(response.nextPageToken, 'YS9mLw==');
      });
    });

    group('ResourceClient.getDownloadUrl', () {
      test('ResourceClient.getDownloadUrl: success', () async {
        var client = ResourceClient(locationNormal, httpClient);

        var now = DateTime.now();
        handler = (request) {
          expect(request.method, 'GET');
          return Response(
              json.encode({
                'bucket': normalBucket,
                'generation': '1',
                'metageneration': '2',
                'name': 'foo/bar/baz.png',
                'size': '10',
                'timeCreated': now.toIso8601String(),
                'updated': now.toIso8601String(),
                'md5Hash': 'deadbeef',
                'cacheControl': 'max-age=604800',
                'contentDisposition': 'Attachment; filename=baz.png',
                'contentLanguage': 'en-US',
                'contentType': 'application/json',
                'downloadTokens': 'a,b,c',
                'metadata': {'foo': 'bar'}
              }),
              200);
        };

        var response = await client.getDownloadUrl();

        expect(
            response,
            'https://${ResourceClient.defaultHost}/v0/b/' +
                normalBucket +
                '/o/' +
                Uri.encodeComponent('foo/bar/baz.png') +
                '?alt=media&token=a');
      });
    });

    group('ResourceClient.updateMetadata', () {
      test('ResourceClient.updateMetadata: success', () async {
        var locations = {
          locationNormal: locationNormalUrl,
          locationEscapes: locationEscapesUrl
        };

        for (var location in locations.keys) {
          var url = locations[location];

          var client = ResourceClient(location, httpClient);

          var now = DateTime.now();
          handler = (request) {
            expect(request.url.path, '/v0$url');
            expect(request.method, 'PATCH');
            expect(request.headers['content-type'],
                'application/json; charset=utf-8');
            expect(json.decode(request.body), {
              // no-inline
              'contentType': 'application/json',
              'metadata': {
                // no-inline
                'foo': 'bar'
              }
            });
            return Response(
                json.encode({
                  'bucket': normalBucket,
                  'generation': '1',
                  'metageneration': '2',
                  'name': 'foo/bar/baz.png',
                  'size': '10',
                  'timeCreated': now.toIso8601String(),
                  'updated': now.toIso8601String(),
                  'md5Hash': 'deadbeef',
                  'cacheControl': 'max-age=604800',
                  'contentDisposition': 'Attachment; filename=baz.png',
                  'contentLanguage': 'en-US',
                  'contentType': 'application/json',
                  'downloadTokens': 'a,b,c',
                  'metadata': {'foo': 'bar'}
                }),
                200);
          };
          var response = await client.updateMetadata(StorageMetadata(
              contentType: 'application/json', customMetadata: {'foo': 'bar'}));

          expect(response.bucket, normalBucket);
          expect(response.generation, '1');
          expect(response.metadataGeneration, '2');
          expect(response.path, 'foo/bar/baz.png');
          expect(response.name, 'baz.png');
          expect(response.sizeBytes, 10);
          expect(response.creationTime, now);
          expect(response.md5Hash, 'deadbeef');
          expect(response.cacheControl, 'max-age=604800');
          expect(response.contentDisposition, 'Attachment; filename=baz.png');
          expect(response.contentLanguage, 'en-US');
          expect(response.contentType, 'application/json');
          expect(response.downloadTokens, ['a', 'b', 'c']);
          expect(response.customMetadata, {'foo': 'bar'});
        }
      });
    });

    group('ResourceClient.deleteObject', () {
      test('ResourceClient.deleteObject: success', () async {
        var locations = {
          locationNormal: locationNormalUrl,
          locationEscapes: locationEscapesUrl
        };

        for (var location in locations.keys) {
          var url = locations[location];

          var client = ResourceClient(location, httpClient);

          handler = (request) {
            expect(request.url.path, '/v0$url');
            expect(request.method, 'DELETE');
            return Response('', 204);
          };

          await client.deleteObject();
        }
      });
    });
  });
}
