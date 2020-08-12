import 'package:firebase_dart/src/storage/impl/location.dart';

import 'package:firebase_dart/src/storage/metadata.dart';

import 'backend.dart';

class MemoryBackend extends Backend {
  Map<Location, StorageMetadataImpl> metadata = {};

  @override
  Future<StorageMetadataImpl> getMetadata(Location location) async {
    return metadata[location];
  }
}
