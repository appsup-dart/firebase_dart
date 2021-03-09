// @dart=2.9

import 'package:firebase_dart/src/storage.dart';

import 'impl/location.dart';

class StorageMetadataImpl implements StorageMetadata {
  @override
  final String bucket;

  @override
  final String generation;

  @override
  final String metadataGeneration;

  @override
  final String path;

  @override
  final int sizeBytes;

  final String type;

  @override
  final DateTime creationTime;

  @override
  final DateTime updatedTime;

  @override
  final String md5Hash;

  @override
  final String cacheControl;

  @override
  final String contentDisposition;

  @override
  final String contentEncoding;

  @override
  final String contentLanguage;

  @override
  final String contentType;

  final List<String> downloadTokens;

  @override
  final Map<String, String> customMetadata;

  StorageMetadataImpl({
    this.bucket,
    this.generation,
    this.metadataGeneration,
    this.path,
    this.sizeBytes,
    this.type,
    this.creationTime,
    this.updatedTime,
    this.md5Hash,
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    this.downloadTokens,
    this.customMetadata,
  });

  @override
  String get name => Location(bucket, path.split('/')).name;

  factory StorageMetadataImpl.fromJson(Map<String, dynamic> json) =>
      StorageMetadataImpl(
          bucket: json['bucket'],
          generation: json['generation'],
          metadataGeneration: json['metageneration'],
          path: json['name'],
          type: 'file',
          sizeBytes: json['size'] == null ? null : int.parse(json['size']),
          creationTime: json['timeCreated'] == null
              ? null
              : DateTime.parse(json['timeCreated']),
          updatedTime:
              json['updated'] == null ? null : DateTime.parse(json['updated']),
          md5Hash: json['md5Hash'],
          cacheControl: json['cacheControl'],
          contentDisposition: json['contentDisposition'],
          contentEncoding: json['contentEncoding'],
          contentLanguage: json['contentLanguage'],
          contentType: json['contentType'],
          customMetadata: (json['metadata'] as Map)?.cast(),
          downloadTokens: (json['downloadTokens'] as String)
              ?.split(',')
              ?.where((v) => v.isNotEmpty)
              ?.toList());

  Map<String, dynamic> toJson() => {
        'bucket': bucket,
        'generation': generation,
        'metageneration': metadataGeneration,
        'name': path,
        'file': type,
        'size': sizeBytes?.toString(),
        'timeCreated': creationTime?.toIso8601String(),
        'updated': updatedTime?.toIso8601String(),
        'md5Hash': md5Hash,
        'cacheControl': cacheControl,
        'contentDisposition': contentDisposition,
        'contentEncoding': contentEncoding,
        'contentLanguage': contentLanguage,
        'contentType': contentType,
        'metadata': customMetadata,
        'downloadTokens': downloadTokens?.join(',')
      };
}
