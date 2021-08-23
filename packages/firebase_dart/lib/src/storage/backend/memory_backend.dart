import 'dart:math';

import 'package:firebase_dart/src/storage.dart';
import 'dart:typed_data';

import 'package:firebase_dart/src/storage/impl/location.dart';

import 'package:firebase_dart/src/storage/metadata.dart';

import 'backend.dart';

class MemoryStorageBackend extends StorageBackend {
  Map<Location, MapEntry<FullMetadataImpl, Uint8List>> items = {};

  @override
  Future<FullMetadataImpl?> getMetadata(Location location) async {
    return items[location]?.key;
  }

  static final _random = Random(DateTime.now().millisecondsSinceEpoch);

  static String _generateRandomString(int length) {
    var chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    return Iterable.generate(
        length, (i) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Future<void> putData(
      Location location, Uint8List data, SettableMetadata metadata) async {
    items[location] = MapEntry(
        FullMetadataImpl(
            bucket: location.bucket,
            fullPath: location.path,
            cacheControl: metadata.cacheControl,
            contentDisposition: metadata.contentDisposition,
            contentEncoding: metadata.contentEncoding,
            contentLanguage: metadata.contentLanguage,
            contentType: metadata.contentType,
            customMetadata: metadata.customMetadata,
            size: data.length,
            downloadTokens: [_generateRandomString(16)]),
        data);
  }
}
