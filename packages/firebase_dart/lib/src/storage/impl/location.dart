import 'package:firebase_dart/src/storage.dart';

/// Represents the location of a resource
class Location {
  /// The uri with scheme gs that identifies the resource
  ///
  /// e.g. gs://some-bucket/path/to/resource
  final Uri uri;

  Location(String bucket, [List<String> pathSegments = const []])
      : uri = Uri(
            scheme: 'gs',
            host: Uri.encodeComponent(bucket),
            pathSegments: pathSegments);

  factory Location.fromBucketSpec(String? bucketString) {
    if (bucketString == null) {
      throw StorageException.noDefaultBucket();
    }
    try {
      var bucketLocation = Location.fromUrl(bucketString);
      if (bucketLocation.isRoot) {
        return bucketLocation;
      }
    } catch (e) {
      // Not valid URL, use as-is. This lets you put bare bucket names in
      // config.
      return Location(bucketString);
    }
    throw StorageException.invalidDefaultBucket(bucketString);
  }

  factory Location.fromUrl(String url) {
    var uri = Uri.parse(url);

    switch (uri.scheme) {
      case 'gs':
        var m = RegExp(r'^gs://([A-Za-z0-9\.\-_]+)(/(.*))?$').firstMatch(url);
        if (m == null) break;
        var segments = m.group(3)?.split('/') ?? [];
        if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
        return Location(m.group(1)!, segments);
      case 'http':
      case 'https':
        if (uri.pathSegments.length < 4 ||
            !uri.pathSegments[0].startsWith('v') ||
            uri.pathSegments[1] != 'b' ||
            uri.pathSegments[3] != 'o') {
          break;
        }
        return Location(uri.pathSegments[2], [...uri.pathSegments.skip(4)]);
    }
    throw StorageException.invalidUrl(url);
  }

  String get bucket => Uri.decodeComponent(uri.host);

  String get path => uri.pathSegments.join('/');

  String get name => uri.pathSegments.last;

  bool get isRoot => uri.pathSegments.isEmpty;

  @override
  String toString() => 'gs://$bucket/$path';

  Location child(String childPath) {
    ArgumentError.checkNotNull(childPath, 'childPath');

    var segments = childPath.split('/').where((v) => v.isNotEmpty);
    return Location(bucket, [...uri.pathSegments, ...segments]);
  }

  Location? getParent() {
    if (isRoot) return null;
    return Location(
        bucket, [...uri.pathSegments.take(uri.pathSegments.length - 1)]);
  }

  Location getRoot() {
    return Location(bucket);
  }

  String fullServerUrl() {
    return '/b/${Uri.encodeComponent(bucket)}/o/${Uri.encodeComponent(path)}';
  }

  String bucketOnlyServerUrl() {
    return '/b/${Uri.encodeComponent(bucket)}/o';
  }

  @override
  bool operator ==(other) => other is Location && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}
