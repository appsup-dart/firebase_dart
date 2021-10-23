import 'dart:math';

import 'package:firebase_dart/src/storage.dart';
import 'dart:typed_data';

import 'package:firebase_dart/src/storage/impl/location.dart';

import 'package:firebase_dart/src/storage/metadata.dart';
import 'package:firebase_dart/src/util/store.dart';

import 'backend.dart';

class MemoryStorageBackend extends StorageBackend {
  final Store<Location, MapEntry<FullMetadataImpl, Uint8List>> items;

  MemoryStorageBackend(
      {Store<Location, MapEntry<FullMetadataImpl, Uint8List>>? items})
      : items = items ?? MemoryStore();

  @override
  Future<FullMetadataImpl?> getMetadata(Location location) async {
    return (await items.get(location))?.key;
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
    await items.set(
        location,
        MapEntry(
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
            data));
  }

  @override
  Future<FullMetadataImpl?> updateMetadata(
      Location location, SettableMetadata metadata) async {
    var current = await items.get(location);

    if (current == null) return null;

    var updated = MapEntry(
        FullMetadataImpl(
            bucket: location.bucket,
            fullPath: location.path,
            cacheControl: metadata.cacheControl,
            contentDisposition: metadata.contentDisposition,
            contentEncoding: metadata.contentEncoding,
            contentLanguage: metadata.contentLanguage,
            contentType: metadata.contentType,
            customMetadata: metadata.customMetadata,
            size: current.key.size,
            downloadTokens: current.key.downloadTokens),
        current.value);

    await items.set(location, updated);
    return updated.key;
  }

  @override
  Future<Map<String, dynamic>> list(
      Location location, ListOptions listOptions) async {
    // TODO: implement maxResults and pageToken
    var list = await items.keys.toList();

    var allItems = list
        .where((v) => v.path.startsWith(location.path))
        .map((v) => v.path.substring(location.path.length));

    return {
      'items': [
        ...allItems.where((v) => !v.contains('/')).map((v) => {'name': v})
      ],
      'prefixes': [...allItems.where((v) => v.contains('/'))],
    };
  }

  @override
  Future<bool> delete(Location location) async {
    var v = await items.remove(location);
    return v != null;
  }
}
