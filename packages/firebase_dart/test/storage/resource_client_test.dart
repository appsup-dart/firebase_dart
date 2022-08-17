import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
    var locationNormalUrl = '/b/$normalBucket/o/o';
    var locationNormalNoObjUrl = '/b/$normalBucket/o';
    var locationEscapes = Location.fromBucketSpec('b/').child('o?');
    var locationEscapesUrl = '/b/b%2F/o/o%3F';
    var locationEscapesNoObjUrl = '/b/b%2F/o';

    String? token;
    late FutureOr<Response> Function(Request) handler;
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
                200,
                request: request);
          };
          var response = await client.getMetadata();

          expect(response.bucket, normalBucket);
          expect(response.generation, '1');
          expect(response.metageneration, '2');
          expect(response.fullPath, 'foo/bar/baz.png');
          expect(response.name, 'baz.png');
          expect(response.size, 10);
          expect(response.timeCreated, now);
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
      test('ResourceClient.list: root: success', () async {
        var client = ResourceClient(locationRoot, httpClient);

        handler = (request) {
          expect(request.url.path, '/v0$locationNormalNoObjUrl');
          expect(request.method, 'GET');
          expect(request.url.queryParameters, {
            'delimiter': '/',
            'prefix': '',
          });
          return Response(
              json.encode({
                'prefixes': [],
                'items': [],
              }),
              200,
              request: request);
        };

        var response = await client.getList(delimiter: '/');

        expect(response, {
          'prefixes': [],
          'items': [],
        });
      });
      test('ResourceClient.list: success', () async {
        var client = ResourceClient(locationNormal, httpClient);

        handler = (request) {
          expect(request.url.path, '/v0$locationNormalNoObjUrl');
          expect(request.method, 'GET');
          expect(request.url.queryParameters, {
            'delimiter': '/',
            'pageToken': 'page_token',
            'maxResults': '4',
            'prefix': '${client.location.path}/',
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
              200,
              request: request);
        };

        var response = await client.getList(
            delimiter: '/', pageToken: 'page_token', maxResults: 4);

        expect(response, {
          'prefixes': ['a/f/'],
          'items': [
            {'name': 'a/a', 'bucket': 'fredzqm-staging'},
            {'name': 'a/b', 'bucket': 'fredzqm-staging'}
          ],
          'nextPageToken': 'YS9mLw=='
        });
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
              200,
              request: request);
        };

        var response = await client.getDownloadUrl();

        expect(response,
            'https://${ResourceClient.defaultHost}/v0/b/$normalBucket/o/${Uri.encodeComponent('foo/bar/baz.png')}?alt=media&token=a');
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
                200,
                request: request);
          };
          var response = await client.updateMetadata(SettableMetadata(
              contentType: 'application/json', customMetadata: {'foo': 'bar'}));

          expect(response.bucket, normalBucket);
          expect(response.generation, '1');
          expect(response.metageneration, '2');
          expect(response.fullPath, 'foo/bar/baz.png');
          expect(response.name, 'baz.png');
          expect(response.size, 10);
          expect(response.timeCreated, now);
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
            return Response('', 204, request: request);
          };

          await client.deleteObject();
        }
      });
    });

    group('ResourceClient.multipartUpload', () {
      test('ResourceClient.multipartUpload: success', () async {
        var locations = {
          locationNormal: locationNormalNoObjUrl,
          locationEscapes: locationEscapesNoObjUrl
        };

        for (var location in locations.keys) {
          var url = locations[location];

          var client = ResourceClient(location, httpClient);

          var data = Uint8List.fromList(utf8.encode('hello world!'));

          handler = (request) {
            expect(request.url.path, '/v0$url');
            expect(request.method, 'POST');
            expect(request.headers['X-Goog-Upload-Protocol'], 'multipart');

            var re = RegExp(r'multipart/related; boundary=(\d{32})');
            var m = re.firstMatch(request.headers['Content-Type']!);
            var boundary = m!.group(1)!;

            var parts = request.body.split('--$boundary');

            var metadata = json.decode(parts[1]
                .split('\n')
                .lastWhere((element) => element.isNotEmpty));

            expect(metadata, {'fullPath': location.path, 'size': data.length});

            m = RegExp(r'Content-Type: [^\n\r]*\r\n\r\n(.*)')
                .firstMatch(parts[2]);

            var content = m!.group(1)!.codeUnits;

            expect(content, data);

            return Response(
                json.encode({
                  'name': metadata['fullPath'],
                }),
                200,
                request: request);
          };

          var r = await client.multipartUpload(data, null);

          expect(r.fullPath, location.path);
        }
      });
    });

    group('ResourceClient.startResumableUpload', () {
      test('ResourceClient.startResumableUpload: success', () async {
        var locations = {
          locationNormal: locationNormalNoObjUrl,
          locationEscapes: locationEscapesNoObjUrl
        };

        for (var location in locations.keys) {
          var url = locations[location];

          var client = ResourceClient(location, httpClient);

          var data = Uint8List.fromList(utf8.encode('hello world!'));
          const uploadUrl = 'https://i.am.an.upload.url.com/hello/there';
          handler = (request) {
            expect(request.url.path, '/v0$url');
            expect(request.method, 'POST');
            expect(request.url.queryParameters, {'name': location.path});
            expect(request.headers, {
              'X-Goog-Upload-Protocol': 'resumable',
              'X-Goog-Upload-Command': 'start',
              'X-Goog-Upload-Header-Content-Length': '${data.length}',
              'X-Goog-Upload-Header-Content-Type': 'application/octet-stream',
              'Content-Type': 'application/json; charset=utf-8'
            });

            return Response('', 200,
                headers: {
                  'X-Goog-Upload-Url': uploadUrl,
                  'X-Goog-Upload-Status': 'active',
                  'Content-Type': 'text/plain'
                },
                request: request);
          };

          var r = await client.startResumableUpload(data, null);

          expect(r, Uri.parse(uploadUrl));
        }
      });
    });
    group('ResourceClient.getResumableUploadStatus', () {
      test('ResourceClient.getResumableUploadStatus: active: success',
          () async {
        const url =
            'https://this.is.totally.a.real.url.com/hello/upload?whatsgoingon';
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        var data = Uint8List.fromList(utf8.encode('hello world!'));
        handler = (request) {
          expect(request.url, Uri.parse(url));
          expect(request.method, 'POST');
          expect(request.headers, {
            'X-Goog-Upload-Command': 'query',
          });

          return Response('', 200,
              headers: {
                'X-Goog-Upload-Status': 'active',
                'X-Goog-Upload-Size-Received': '0',
                'Content-Type': 'text/plain'
              },
              request: request);
        };

        var r = await client.getResumableUploadStatus(Uri.parse(url), data);

        expect(r.finalized, false);
        expect(r.current, 0);
        expect(r.total, data.length);
      });
      test('ResourceClient.getResumableUploadStatus: finished: success',
          () async {
        const url =
            'https://this.is.totally.a.real.url.com/hello/upload?whatsgoingon';
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        var data = Uint8List.fromList(utf8.encode('hello world!'));
        handler = (request) {
          expect(request.url, Uri.parse(url));
          expect(request.method, 'POST');
          expect(request.headers, {
            'X-Goog-Upload-Command': 'query',
          });

          return Response('', 200,
              headers: {
                'X-Goog-Upload-Status': 'final',
                'X-Goog-Upload-Size-Received': '${data.length}',
                'Content-Type': 'text/plain'
              },
              request: request);
        };

        var r = await client.getResumableUploadStatus(Uri.parse(url), data);

        expect(r.finalized, true);
        expect(r.current, data.length);
        expect(r.total, data.length);
      });
    });

    group('ResourceClient.continueResumableUpload', () {
      test('ResourceClient.continueResumableUpload: active: success', () async {
        const url =
            'https://this.is.totally.a.real.url.com/hello/upload?whatsgoingon';
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        var data = Uint8List.fromList(utf8.encode('hello world!'));
        handler = (request) {
          expect(request.url, Uri.parse(url));
          expect(request.method, 'POST');
          expect(request.headers, {
            'X-Goog-Upload-Command': 'upload, finalize',
            'X-Goog-Upload-Offset': '0'
          });

          var content = request.bodyBytes;
          expect(content, data);

          return Response(json.encode({'name': location.path}), 200,
              headers: {
                'X-Goog-Upload-Status': 'final',
                'X-Goog-Upload-Size-Received': '${content.length}',
                'Content-Type': 'application/json'
              },
              request: request);
        };

        var r = await client.continueResumableUpload(
            Uri.parse(url), data, 256 * 1024);

        expect(r.finalized, true);
        expect(r.current, data.length);
        expect(r.total, data.length);
        expect(r.metadata!.fullPath, location.path);
      });
    });

    group('Error handling', () {
      test('error handler passes through unknown errors', () async {
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        handler = (request) {
          return Response('', 509, request: request);
        };
        expect(() => client.getMetadata(), throwsA(StorageException.unknown()));
      });
      test('error handler converts 404 to not found', () async {
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        handler = (request) {
          return Response('', 404, request: request);
        };
        expect(() => client.getMetadata(),
            throwsA(StorageException.objectNotFound(location.path)));
      });
      test('error handler converts 402 to quota exceeded', () async {
        var location = locationNormal;
        var client = ResourceClient(location, httpClient);
        handler = (request) {
          return Response('', 402, request: request);
        };
        expect(() => client.getMetadata(),
            throwsA(StorageException.quotaExceeded(location.bucket)));
      });
    });
  });
}
