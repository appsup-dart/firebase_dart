import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_dart/src/implementation.dart';

import 'core.dart';

/// FirebaseStorage is a service that supports uploading and downloading large
/// objects to Google Cloud Storage.
abstract class FirebaseStorage {
  /// Returns the [FirebaseStorage] instance, initialized with a custom
  /// [FirebaseApp] if [app] is specified and a custom Google Cloud Storage
  /// bucket if [bucket] is specified. Otherwise the instance will be
  /// initialized with the default [FirebaseApp].
  ///
  /// The [FirebaseStorage] instance is a singleton for fixed [app] and
  /// [bucket].
  ///
  /// The [bucket] argument is the gs:// url to the custom Firebase
  /// Storage Bucket.
  ///
  /// The [app] argument is the custom [FirebaseApp].
  static FirebaseStorage instanceFor({FirebaseApp? app, String? bucket}) =>
      FirebaseImplementation.installation
          .createStorage(app ?? Firebase.app(), storageBucket: bucket);

  /// The [FirebaseApp] instance to which this [FirebaseStorage] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.
  FirebaseApp get app;

  /// The Google Cloud Storage bucket to which this [FirebaseStorage] belongs.
  ///
  /// If null, the storage bucket of the specified [FirebaseApp] is used.
  String get bucket;

  /// Returns the [FirebaseStorage] instance, initialized with the default
  /// [FirebaseApp].
  static final FirebaseStorage instance =
      FirebaseStorage.instanceFor(app: Firebase.app());

  /// Creates a new [Reference] initialized at the root
  /// Firebase Storage location.
  Reference ref([String? path]);

  /// The maximum time to retry downloads.
  Duration get maxDownloadRetryTime;

  /// The maximum time to retry uploads.
  Duration get maxUploadRetryTime;

  /// The maximum time to retry operations other than uploads or downloads.
  Duration get maxOperationRetryTime;

  /// Sets the new maximum download retry time.
  void setMaxDownloadRetryTime(Duration time);

  /// Sets the new maximum upload retry time.
  void setMaxUploadRetryTime(Duration time);

  /// Sets the new maximum operation retry time.
  void setMaxOperationRetryTime(Duration time);

  /// Creates a [Reference] given a gs:// or // URL pointing to a Firebase
  /// Storage location.
  Reference refFromURL(String fullUrl);
}

/// A class representing an on-going storage task that additionally delegates to
///  a Future.
abstract class Task implements Future<TaskSnapshot> {
  /// The latest [TaskSnapshot] for this task.
  TaskSnapshot get snapshot;

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event. See
  /// [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// await this [Task] directly.
  Stream<TaskSnapshot> get snapshotEvents;

  /// The [FirebaseStorage] instance associated with this task.
  FirebaseStorage get storage;

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the delegating task
  /// Future and stream ([snapshotEvents]) will trigger an error with a
  /// [FirebaseException].
  Future<bool> cancel();

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a
  /// [TaskState.paused] state.
  Future<bool> pause();

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a
  /// [TaskState.running] state.
  Future<bool> resume();
}

/// Represents the state of an on-going [Task].
///
/// The state can be accessed directly via a [TaskSnapshot].
enum TaskState {
  /// Indicates the task has been paused by the user.
  paused,

  /// Indicates the task is currently in-progress.
  running,

  /// Indicates the task has successfully completed.
  success,

  /// Indicates the task was canceled.
  canceled,

  /// Indicates the task failed with an error.
  error,
}

/// A class which indicates an on-going download task.
abstract class DownloadTask extends Task {}

/// A class which indicates an on-going upload task.
abstract class UploadTask extends Task {}

/// A [TaskSnapshot] is returned as the result or on-going process of a [Task].
class TaskSnapshot {
  /// The current transferred bytes of this task.
  final int bytesTransferred;

  /// The [FullMetadata] associated with this task.
  ///
  /// May be null if no metadata exists.
  final FullMetadata? metadata;

  /// The [Reference] for this snapshot.
  final Reference ref;

  /// The current task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  final TaskState state;

  /// The [FirebaseStorage] instance used to create the task.
  FirebaseStorage get storage => ref.storage;

  /// The total bytes of the task.
  ///
  /// Note; when performing a download task, the value of -1 will be provided
  /// whilst the total size of the remote file is being determined.
  final int totalBytes;

  TaskSnapshot(
      {required this.ref,
      required this.state,
      required this.totalBytes,
      required this.bytesTransferred,
      this.metadata});
}

abstract class Reference {
  /// The name of the bucket containing this reference's object.
  String get bucket;

  /// The full path of this object.
  String get fullPath;

  /// The short name of this object, which is the last component of the full
  /// path.
  ///
  /// For example, if fullPath is 'full/path/image.png', name is 'image.png'.
  String get name;

  /// A reference pointing to the parent location of this reference, or `null`
  /// if this reference is the root.
  Reference? get parent;

  /// A reference to the root of this reference's bucket.
  Reference get root;

  /// The storage service associated with this reference.
  FirebaseStorage get storage;

  /// Returns a reference to a relative path from this reference.
  ///
  /// [path] The relative path from this reference. Leading, trailing, and
  /// consecutive slashes are removed.
  Reference child(String path);

  /// Deletes the object at this reference's location.
  Future<void> delete();

  /// Asynchronously downloads the object at the StorageReference to a list in
  /// memory.
  ///
  /// Returns a Uint8List of the data.
  ///
  /// If the maxSize (in bytes) is exceeded, the operation will be canceled. By
  /// default the maxSize is 10mb (10485760 bytes).
  Future<Uint8List?> getData([int? maxSize = 10485760]);

  /// Fetches a long lived download URL for this object.
  Future<String> getDownloadURL();

  /// Fetches metadata for the object at this location, if one exists.
  Future<FullMetadata> getMetadata();

  /// List items (files) and prefixes (folders) under this storage reference.
  ///
  /// List API is only available for Firebase Rules Version 2.
  ///
  /// GCS is a key-blob store. Firebase Storage imposes the semantic of '/'
  /// delimited folder structure. Refer to GCS's List API if you want to learn
  /// more.
  ///
  /// To adhere to Firebase Rules's Semantics, Firebase Storage does not support
  /// objects whose paths end with "/" or contain two consecutive "/"s. Firebase
  /// Storage List API will filter these unsupported objects. list may fail if
  /// there are too many unsupported objects in the bucket.
  Future<ListResult> list([ListOptions? options]);

  /// List all items (files) and prefixes (folders) under this storage
  /// reference.
  ///
  /// This is a helper method for calling [list] repeatedly until there are no
  /// more results. The default pagination size is 1000.
  ///
  /// Note: The results may not be consistent if objects are changed while this
  /// operation is running.
  ///
  /// Warning: listAll may potentially consume too many resources if there are
  /// too many results.
  Future<ListResult> listAll();

  /// Uploads data to this reference's location.
  ///
  /// Use this method to upload fixed sized data as a [Uint8List].
  ///
  /// Optionally, you can also set metadata onto the uploaded object.
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]);

  /// Upload a [String] value as a storage object.
  ///
  /// Use [PutStringFormat] to correctly encode the string:
  ///
  /// * [PutStringFormat.raw] the string will be encoded in a Base64 format.
  /// * [PutStringFormat.dataUrl] the string must be in a data url format (e.g.
  /// "data:text/plain;base64,SGVsbG8sIFdvcmxkIQ=="). If no
  /// [SettableMetadata.mimeType] is provided as part of the [metadata]
  /// argument, the [mimeType] will be automatically set.
  /// * [PutStringFormat.base64] will be encoded as a Base64 string.
  /// * [PutStringFormat.base64Url] will be encoded as a Base64 string safe URL.
  UploadTask putString(String data,
      {PutStringFormat format = PutStringFormat.raw,
      SettableMetadata? metadata});

  /// Updates the metadata on a storage object.
  Future<FullMetadata> updateMetadata(SettableMetadata metadata);
}

/// Metadata for a [Reference]. Metadata stores default attributes such as
/// size and content type.
class FullMetadata {
  /// The bucket this object is contained in.
  final String? bucket;

  /// Served as the 'Cache-Control' header on object download.
  final String? cacheControl;

  /// Served as the 'Content-Disposition' HTTP header on object download.
  final String? contentDisposition;

  /// Served as the 'Content-Encoding' header on object download.
  final String? contentEncoding;

  /// Served as the 'Content-Language' header on object download.
  final String? contentLanguage;

  /// Served as the 'Content-Type' header on object download.
  final String? contentType;

  /// Custom metadata set on this storage object.
  final Map<String, String>? customMetadata;

  /// The full path of this object.
  final String fullPath;

  /// The object's generation.
  final String? generation;

  /// A Base64-encoded MD5 hash of the object being uploaded.
  final String? md5Hash;

  /// The object's metadata generation.
  final String? metadataGeneration;

  /// The object's metageneration.
  final String? metageneration;

  /// The short name of this object, which is the last component of the full
  /// path.
  ///
  /// For example, if fullPath is 'full/path/image.png', name is 'image.png'.
  final String name;

  /// The size of this object, in bytes.
  final int? size;

  /// A DateTime representing when this object was created.
  final DateTime? timeCreated;

  /// A DateTime representing when this object was updated.
  final DateTime? updated;

  FullMetadata({
    this.bucket,
    required this.fullPath,
    this.generation,
    this.md5Hash,
    this.metadataGeneration,
    this.metageneration,
    required this.name,
    this.size,
    this.timeCreated,
    this.updated,
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    Map<String, String>? customMetadata,
  }) : customMetadata = customMetadata == null
            ? null
            : Map<String, String>.unmodifiable(customMetadata);
}

class SettableMetadata {
  /// Served as the 'Cache-Control' header on object download.
  final String? cacheControl;

  /// Served as the 'Content-Disposition' HTTP header on object download.
  final String? contentDisposition;

  /// Served as the 'Content-Encoding' header on object download.
  final String? contentEncoding;

  /// Served as the 'Content-Language' header on object download.
  final String? contentLanguage;

  /// Served as the 'Content-Type' header on object download.
  final String? contentType;

  /// Custom metadata set on this storage object.
  final Map<String, String>? customMetadata;

  SettableMetadata(
      {this.cacheControl,
      this.contentDisposition,
      this.contentEncoding,
      this.contentLanguage,
      this.contentType,
      this.customMetadata});

  Map<String, dynamic> asMap() => {
        'cacheControl': cacheControl,
        'contentDisposition': contentDisposition,
        'contentEncoding': contentEncoding,
        'contentLanguage': contentLanguage,
        'contentType': contentType,
        'customMetadata': customMetadata,
      };
}

/// The format in which a string can be uploaded to the storage bucket via
/// [Reference.putString].
enum PutStringFormat {
  /// A raw string. It will be uploaded as a Base64 string.
  raw,

  /// A Base64 encoded string.
  base64,

  /// A Base64 URL encoded string.
  base64Url,

  /// A data url string.
  dataUrl,
}

/// The options [FirebaseStoragePlatform.list] accepts.
class ListOptions {
  /// If set, limits the total number of `prefixes` and `items` to return.
  ///
  /// The default and maximum maxResults is 1000.
  final int? maxResults;

  /// The nextPageToken from a previous call to list().
  ///
  /// If provided, listing is resumed from the previous position.
  final String? pageToken;

  ListOptions({this.maxResults, this.pageToken}) {
    if (maxResults != null && (maxResults! <= 0 || maxResults! > 1000)) {
      throw ArgumentError.value(
          maxResults, 'maxResults', 'Should be a value between 1 and 1000');
    }
  }
}

/// Class returned as a result of calling a list method (`list` or `listAll`) on
/// a [Reference].
abstract class ListResult {
  /// Objects in this directory.
  ///
  /// Returns a [List] of [Reference] instances.
  List<Reference> get items;

  /// If set, there might be more results for this list.
  ///
  /// Use this token to resume the list with [ListOptions].
  String? get nextPageToken;

  /// References to prefixes (sub-folders). You can call list() on them to get
  /// its contents.
  ///
  /// Folders are implicit based on '/' in the object paths. For example, if a
  /// bucket has two objects '/a/b/1' and '/a/b/2', list('/a') will return
  /// '/a/b' as a prefix.
  List<Reference> get prefixes;

  /// The [FirebaseStorage] instance for this result.
  FirebaseStorage get storage;
}

class StorageException extends FirebaseException {
  StorageException._({
    required String code,
    String? message,
  }) : super(plugin: 'storage', code: code, message: message);

  StorageException(String code, [String? message])
      : this._(code: code, message: message);

  StorageException.unknown()
      : this(
            'unknown',
            'An unknown error occurred, please check the error payload for '
                'server response.');

  StorageException.objectNotFound(String path)
      : this('object-not-found', "Object '$path' does not exist.");

  StorageException.bucketNotFound(String bucket)
      : this('bucket-not-found', "Bucket '$bucket' does not exist.");

  StorageException.projectNotFound(String project)
      : this('project-not-found', "Project '$project' does not exist.");

  StorageException.quotaExceeded(String bucket)
      : this(
            'quota-exceeded',
            "Quota for bucket '$bucket' exceeded, please view quota on "
                'https://firebase.google.com/pricing/.');

  StorageException.unauthenticated()
      : this(
            'unauthenticated',
            'User is not authenticated, please authenticate using Firebase '
                'Authentication and try again.');

  StorageException.unauthorized(String path)
      : this(
            'unauthorized', "User does not have permission to access '$path'.");

  StorageException.retryLimitExceeded()
      : this('retry-limit-exceeded',
            'Max retry time for operation exceeded, please try again.');

  StorageException.invalidChecksum(
      String path, String checksum, String calculated)
      : this(
            'invalid-checksum',
            "Uploaded/downloaded object '$path' has checksum '$checksum' which does"
                'not match. Please retry the upload/download.');

  StorageException.canceled()
      : this('canceled', 'User canceled the upload/download.');

  StorageException.invalidEventName(String name)
      : this('invalid-event-name', "Invalid event name '$name'.");

  StorageException.invalidUrl(String url)
      : this('invalid-url', "Invalid URL '$url'.");

  StorageException.invalidDefaultBucket(String bucket)
      : this('invalid-default-bucket', "Invalid default bucket '$bucket'.");

  StorageException.noDefaultBucket()
      : this(
            'no-default-bucket',
            "No default bucket found. Did you set the 'storageBucket' property "
                'when initializing the app?');

  StorageException.cannotSliceBlob()
      : this('cannot-slice-blob'
            'Cannot slice blob for upload. Please retry the upload.');

  StorageException.serverFileWrongSize()
      : this('server-file-wrong-size'
            'Server recorded incorrect upload file size, please retry the upload.');

  StorageException.noDownloadURL()
      : this('no-download-url',
            'The given file does not have any download URLs.');

  StorageException.appDeleted()
      : this('app-deleted', 'The Firebase app was deleted.');

  /// The name of the operation that was invalid.
  StorageException.invalidRootOperation(String name)
      : this(
            'invalid-root-operation',
            "The operation '$name' cannot be performed on a root reference, create a non-root "
                "reference using child, such as .child('file.png').");

  StorageException.invalidFormat(String format, String message)
      : this('invalid-format',
            "String does not match format '$format': $message");

  StorageException.internalError(String message)
      : this('internal-error', 'Internal error: $message');
}
