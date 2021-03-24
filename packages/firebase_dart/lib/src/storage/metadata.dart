import 'package:firebase_dart/src/storage.dart';

import 'impl/location.dart';

class FullMetadataImpl implements FullMetadata {
  @override
  final String? bucket;

  @override
  final String? generation;

  @override
  final String? metadataGeneration;

  @override
  final String fullPath;

  @override
  final int? size;

  final String? type;

  @override
  final DateTime? timeCreated;

  @override
  final DateTime? updated;

  @override
  final String? md5Hash;

  @override
  final String? cacheControl;

  @override
  final String? contentDisposition;

  @override
  final String? contentEncoding;

  @override
  final String? contentLanguage;

  @override
  final String? contentType;

  final List<String>? downloadTokens;

  @override
  final Map<String, String>? customMetadata;

  @override
  final String? metageneration;

  FullMetadataImpl({
    this.bucket,
    this.generation,
    this.metadataGeneration,
    this.metageneration,
    required this.fullPath,
    this.size,
    this.type,
    this.timeCreated,
    this.updated,
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
  String get name => Location(bucket!, fullPath.split('/')).name;

  factory FullMetadataImpl.fromJson(Map<String, dynamic> json) =>
      FullMetadataImpl(
          bucket: json['bucket'],
          generation: json['generation'],
          metageneration: json['metageneration'],
          metadataGeneration: json['metadataGeneration'],
          fullPath: json['name'],
          type: 'file',
          size: json['size'] == null ? null : int.parse(json['size']),
          timeCreated: json['timeCreated'] == null
              ? null
              : DateTime.parse(json['timeCreated']),
          updated:
              json['updated'] == null ? null : DateTime.parse(json['updated']),
          md5Hash: json['md5Hash'],
          cacheControl: json['cacheControl'],
          contentDisposition: json['contentDisposition'],
          contentEncoding: json['contentEncoding'],
          contentLanguage: json['contentLanguage'],
          contentType: json['contentType'],
          customMetadata: (json['metadata'] as Map?)?.cast(),
          downloadTokens: (json['downloadTokens'] as String?)
              ?.split(',')
              .where((v) => v.isNotEmpty)
              .toList());

  Map<String, dynamic> toJson() => {
        'bucket': bucket,
        'generation': generation,
        'metadataGeneration': metadataGeneration,
        'metageneration': metageneration,
        'name': fullPath,
        'file': type,
        'size': size?.toString(),
        'timeCreated': timeCreated?.toIso8601String(),
        'updated': updated?.toIso8601String(),
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
