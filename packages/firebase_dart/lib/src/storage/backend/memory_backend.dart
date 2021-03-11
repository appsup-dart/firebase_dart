// @dart=2.9

import 'package:firebase_dart/src/storage/impl/location.dart';

import 'package:firebase_dart/src/storage/metadata.dart';

import 'backend.dart';

class MemoryBackend extends Backend {
  Map<Location, FullMetadataImpl> metadata = {};

  @override
  Future<FullMetadataImpl> getMetadata(Location location) async {
    return metadata[location];
  }
}
