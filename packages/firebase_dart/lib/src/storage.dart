import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_dart/src/implementation.dart';
import 'package:meta/meta.dart';

import 'core.dart';

/// FirebaseStorage is a service that supports uploading and downloading large
/// objects to Google Cloud Storage.
abstract class FirebaseStorage {
  /// Returns the [FirebaseStorage] instance, initialized with a custom
  /// [FirebaseApp] if [app] is specified and a custom Google Cloud Storage
  /// bucket if [storageBucket] is specified. Otherwise the instance will be
  /// initialized with the default [FirebaseApp].
  ///
  /// The [FirebaseStorage] instance is a singleton for fixed [app] and
  /// [storageBucket].
  ///
  /// The [storageBucket] argument is the gs:// url to the custom Firebase
  /// Storage Bucket.
  ///
  /// The [app] argument is the custom [FirebaseApp].
  factory FirebaseStorage.instanceFor({FirebaseApp app, String bucket}) =>
      FirebaseImplementation.installation
          .createStorage(app ?? Firebase.app(), storageBucket: bucket);

  /// The [FirebaseApp] instance to which this [FirebaseStorage] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.
  FirebaseApp get app;

  /// The Google Cloud Storage bucket to which this [FirebaseStorage] belongs.
  ///
  /// If null, the storage bucket of the specified [FirebaseApp] is used.
  String get storageBucket;

  /// Returns the [FirebaseStorage] instance, initialized with the default
  /// [FirebaseApp].
  static final FirebaseStorage instance =
      FirebaseStorage.instanceFor(app: Firebase.app());

  /// Creates a new [StorageReference] initialized at the root
  /// Firebase Storage location.
  StorageReference ref();

  Future<int> getMaxDownloadRetryTimeMillis();

  Future<int> getMaxUploadRetryTimeMillis();

  Future<int> getMaxOperationRetryTimeMillis();

  Future<void> setMaxDownloadRetryTimeMillis(int time);

  Future<void> setMaxUploadRetryTimeMillis(int time);

  Future<void> setMaxOperationRetryTimeMillis(int time);

  /// Creates a [StorageReference] given a gs:// or // URL pointing to a Firebase
  /// Storage location.
  Future<StorageReference> getReferenceFromUrl(String fullUrl);
}

abstract class StorageFileDownloadTask {
  Future<FileDownloadTaskSnapshot> get future;
}

class FileDownloadTaskSnapshot {
  FileDownloadTaskSnapshot({this.totalByteCount});
  final int totalByteCount;
}

abstract class StorageReference {
  /// Returns a new instance of [StorageReference] pointing to a child
  /// location of the current reference.
  StorageReference child(String path);

  /// Returns a new instance of [StorageReference] pointing to the parent
  /// location or null if this instance references the root location.
  StorageReference getParent();

  /// Returns a new instance of [StorageReference] pointing to the root location.
  StorageReference getRoot();

  /// Returns the [FirebaseStorage] service which created this reference.
  FirebaseStorage getStorage();

  /// Asynchronously uploads byte data to the currently specified
  /// [StorageReference], with an optional [metadata].
  StorageUploadTask putData(Uint8List data, [StorageMetadata metadata]);

  /// Returns the Google Cloud Storage bucket that holds this object.
  Future<String> getBucket();

  /// Returns the full path to this object, not including the Google Cloud
  /// Storage bucket.
  Future<String> getPath();

  /// Returns the short name of this object.
  Future<String> getName();

  /// Asynchronously downloads the object at the StorageReference to a list in memory.
  /// A list of the provided max size will be allocated.
  Future<Uint8List> getData(int maxSize);

  /// Asynchronously retrieves a long lived download URL with a revokable token.
  /// This can be used to share the file with others, but can be revoked by a
  /// developer in the Firebase Console if desired.
  Future<Uri> getDownloadURL();

  Future<void> delete();

  /// Retrieves metadata associated with an object at this [StorageReference].
  Future<StorageMetadata> getMetadata();

  /// Updates the metadata associated with this [StorageReference].
  ///
  /// Returns a [Future] that will complete to the updated [StorageMetadata].
  ///
  /// This method ignores fields of [metadata] that cannot be set by the public
  /// [StorageMetadata] constructor. Writable metadata properties can be deleted
  /// by passing the empty string.
  Future<StorageMetadata> updateMetadata(StorageMetadata metadata);

  String get path;
}

/// Metadata for a [StorageReference]. Metadata stores default attributes such as
/// size and content type.
class StorageMetadata {
  StorageMetadata({
    this.cacheControl,
    this.contentDisposition,
    this.contentEncoding,
    this.contentLanguage,
    this.contentType,
    Map<String, String> customMetadata,
  }) : customMetadata = customMetadata == null
            ? null
            : Map<String, String>.unmodifiable(customMetadata);

  /// The owning Google Cloud Storage bucket for the [StorageReference].
  String get bucket => null;

  /// A version String indicating what version of the [StorageReference].
  String get generation => null;

  /// A version String indicating the version of this [StorageMetadata].
  String get metadataGeneration => null;

  /// The path of the [StorageReference] object.
  String get path => null;

  /// A simple name of the [StorageReference] object.
  String get name => null;

  /// The stored Size in bytes of the [StorageReference] object.
  int get sizeBytes => null;

  /// The time the [StorageReference] was created.
  DateTime get creationTime => null;

  /// The time the [StorageReference] was last updated.
  DateTime get updatedTime => null;

  /// The MD5Hash of the [StorageReference] object.
  String get md5Hash => null;

  /// The Cache Control setting of the [StorageReference].
  final String cacheControl;

  /// The content disposition of the [StorageReference].
  final String contentDisposition;

  /// The content encoding for the [StorageReference].
  final String contentEncoding;

  /// The content language for the StorageReference, specified as a 2-letter
  /// lowercase language code defined by ISO 639-1.
  final String contentLanguage;

  /// The content type (MIME type) of the [StorageReference].
  final String contentType;

  /// An unmodifiable map with custom metadata for the [StorageReference].
  final Map<String, String> customMetadata;
}

abstract class StorageUploadTask {
  bool get isCanceled;
  bool get isComplete;
  bool get isInProgress;
  bool get isPaused;
  bool get isSuccessful;

  StorageTaskSnapshot get lastSnapshot;

  /// Returns a last snapshot when completed
  Future<StorageTaskSnapshot> get onComplete;

  Stream<StorageTaskEvent> get events;

  /// Pause the upload
  void pause();

  /// Resume the upload
  void resume();

  /// Cancel the upload
  void cancel();
}

enum StorageTaskEventType {
  resume,
  progress,
  pause,
  success,
  failure,
}

/// `Event` encapsulates a StorageTaskSnapshot
abstract class StorageTaskEvent {
  StorageTaskEventType get type;
  StorageTaskSnapshot get snapshot;
}

abstract class StorageTaskSnapshot {
  StorageReference get ref;
  int get error;
  int get bytesTransferred;
  int get totalByteCount;
  Uri get uploadSessionUri;
  StorageMetadata get storageMetadata;
}

class StorageException extends FirebaseException {
  StorageException._({
    @required String code,
    String message,
  }) : super(plugin: 'storage', code: code, message: message);

  StorageException(String code, [String message])
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
            "String does not match format '" + format + "': " + message);

  StorageException.internalError(String message)
      : this('internal-error', 'Internal error: ' + message);
}
