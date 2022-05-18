import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/storage/impl/location.dart';
import 'package:firebase_dart/src/storage/impl/resource_client.dart';
import 'package:firebase_dart/storage.dart';
import 'package:rxdart/rxdart.dart';

import '../isolate.dart';
import 'util.dart';

class StorageReferenceFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final String bucket;
  final String path;
  final Symbol functionName;

  StorageReferenceFunctionCall(
      this.functionName, this.appName, this.bucket, this.path,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseStorage get storage =>
      FirebaseStorage.instanceFor(app: Firebase.app(appName), bucket: bucket);

  Reference getRef() => storage.ref().child(path);

  static final Map<int, Task> _tasks = {};

  @override
  Function? get function {
    switch (functionName) {
      case #delete:
        return getRef().delete;
      case #getData:
        return getRef().getData;
      case #getDownloadURL:
        return getRef().getDownloadURL;
      case #getMetadata:
        return getRef().getMetadata;
      case #putData:
        return (SendPort sendPort, int id, Uint8List data,
            SettableMetadata? metadata) async {
          var task = _tasks[id] = getRef().putData(data, metadata);
          task.snapshotEvents.map(encodeTaskSnapshot).listen(sendPort.send);
          return encodeTaskSnapshot(await task.whenComplete(() {
            _tasks.remove(id);
          }));
        };
      case #putString:
        return (SendPort sendPort, int id, String data,
            {PutStringFormat format = PutStringFormat.raw,
            SettableMetadata? metadata}) async {
          var task = _tasks[id] =
              getRef().putString(data, format: format, metadata: metadata);

          task.snapshotEvents.map(encodeTaskSnapshot).listen(sendPort.send);
          return encodeTaskSnapshot(await task.whenComplete(() {
            _tasks.remove(id);
          }));
        };
      case #list:
        return (ListOptions? options) =>
            getRef().list(options).then(encodeListResult);
      case #listAll:
        return () => getRef().listAll().then(encodeListResult);
      case #updateMetadata:
        return getRef().updateMetadata;
      case #UploadTask.pause:
        return (int id) async => await _tasks[id]?.pause() ?? false;
      case #UploadTask.resume:
        return (int id) async => await _tasks[id]?.resume() ?? false;
      case #UploadTask.cancel:
        return (int id) async => await _tasks[id]?.cancel() ?? false;
    }
    return null;
  }

  static Map<Symbol, dynamic> encodeTaskSnapshot(TaskSnapshot v) => {
        #bytesTransferred: v.bytesTransferred,
        #metadata: v.metadata,
        #state: v.state,
        #totalBytes: v.totalBytes
      };

  static Map<String, dynamic> encodeListResult(ListResult v) =>
      (v as ListResultImpl).toJson();
}

class IsolateFirebaseStorage extends IsolateFirebaseService
    implements FirebaseStorage {
  final Location _bucket;

  IsolateFirebaseStorage(
      {required IsolateFirebaseApp app, String? storageBucket})
      : _bucket =
            Location.fromBucketSpec(storageBucket ?? app.options.storageBucket),
        super(app);

  @override
  Reference refFromURL(String fullUrl) {
    var location = Location.fromUrl(fullUrl);
    return IsolateStorageReference(this, location);
  }

  @override
  Reference ref([String? path]) {
    var ref = IsolateStorageReference(this, _bucket);
    if (path != null) {
      return ref.child(path);
    } else {
      return ref;
    }
  }

  @override
  String get bucket => _bucket.bucket;

  @override
  // TODO: implement maxDownloadRetryTime
  Duration get maxDownloadRetryTime => throw UnimplementedError();

  @override
  // TODO: implement maxOperationRetryTime
  Duration get maxOperationRetryTime => throw UnimplementedError();

  @override
  // TODO: implement maxUploadRetryTime
  Duration get maxUploadRetryTime => throw UnimplementedError();

  @override
  void setMaxDownloadRetryTime(Duration time) {
    // TODO: implement setMaxDownloadRetryTime
  }

  @override
  void setMaxOperationRetryTime(Duration time) {
    // TODO: implement setMaxOperationRetryTime
  }

  @override
  void setMaxUploadRetryTime(Duration time) {
    // TODO: implement setMaxUploadRetryTime
  }
}

class IsolateStorageReference extends Reference {
  @override
  final IsolateFirebaseStorage storage;

  final Location location;

  IsolateStorageReference(this.storage, this.location);

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) {
    return storage.app.commander.execute(
        StorageReferenceFunctionCall<FutureOr<T>>(
            method,
            storage.app.name,
            storage.bucket,
            location.path,
            positionalArguments,
            namedArguments));
  }

  @override
  IsolateStorageReference child(String path) =>
      IsolateStorageReference(storage, location.child(path));

  @override
  Future<void> delete() async {
    await invoke(#delete, []);
  }

  @override
  String get bucket => location.bucket;

  @override
  Future<Uint8List> getData([int? maxSize = 10485760]) async {
    return await invoke(#getData, [maxSize]);
  }

  @override
  Future<String> getDownloadURL() async {
    return await invoke(#getDownloadURL, []);
  }

  @override
  Future<FullMetadata> getMetadata() async {
    return await invoke(#getMetadata, []);
  }

  @override
  String get name => location.name;

  @override
  IsolateStorageReference? get parent {
    var parentLocation = location.getParent();
    if (parentLocation == null) return null;
    return IsolateStorageReference(storage, parentLocation);
  }

  @override
  String get fullPath => location.path;

  @override
  Reference get root {
    return IsolateStorageReference(storage, location.getRoot());
  }

  @override
  UploadTask putData(Uint8List data, [SettableMetadata? metadata]) {
    var receivePort = ReceivePort();
    var id = DateTime.now().microsecondsSinceEpoch;
    var future = invoke<Map<Symbol, dynamic>>(
        #putData, [receivePort.sendPort, id, data, metadata]);
    return IsolateUploadTask(this, id, future.then(_decodeTaskSnapshot),
        receivePort.cast<Map<Symbol, dynamic>>().map(_decodeTaskSnapshot));
  }

  TaskSnapshot _decodeTaskSnapshot(Map<Symbol, dynamic> v) => TaskSnapshot(
      ref: this,
      bytesTransferred: v[#bytesTransferred],
      state: v[#state],
      totalBytes: v[#totalBytes],
      metadata: v[#metadata]);

  ListResult _decodeListResult(Map<String, dynamic> json) =>
      ListResultImpl.fromJson(this, json);

  @override
  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    return await invoke(#updateMetadata, [metadata]);
  }

  @override
  Future<ListResult> list([ListOptions? options]) async {
    return _decodeListResult(await invoke(#list, [options]));
  }

  @override
  Future<ListResult> listAll() async {
    return _decodeListResult(await invoke(#listAll));
  }

  @override
  UploadTask putString(String data,
      {PutStringFormat format = PutStringFormat.raw,
      SettableMetadata? metadata}) {
    var receivePort = ReceivePort();
    var id = DateTime.now().microsecondsSinceEpoch;
    var future = invoke<Map<Symbol, dynamic>>(
        #putString,
        [receivePort.sendPort, id, data],
        {#format: format, #metadata: metadata});
    return IsolateUploadTask(this, id, future.then(_decodeTaskSnapshot),
        receivePort.cast<Map<Symbol, dynamic>>().map(_decodeTaskSnapshot));
  }

  @override
  String toString() => location.toString();

  @override
  bool operator ==(other) =>
      other is IsolateStorageReference && other.location == location;

  @override
  int get hashCode => location.hashCode;
}

class IsolateUploadTask extends DelegatingFuture<TaskSnapshot>
    implements UploadTask {
  final int id;

  final IsolateStorageReference _ref;

  final BehaviorSubject<TaskSnapshot> _subject = BehaviorSubject();

  IsolateUploadTask(this._ref, this.id, Future<TaskSnapshot> future,
      Stream<TaskSnapshot> events)
      : super(future) {
    events.pipe(_subject);
  }

  @override
  Future<bool> cancel() {
    return _ref.invoke(#UploadTask.cancel, [id]);
  }

  @override
  Future<bool> pause() {
    return _ref.invoke(#UploadTask.pause, [id]);
  }

  @override
  Future<bool> resume() {
    return _ref.invoke(#UploadTask.resume, [id]);
  }

  @override
  TaskSnapshot get snapshot => _subject.value;

  @override
  Stream<TaskSnapshot> get snapshotEvents => _subject.stream;

  @override
  IsolateFirebaseStorage get storage => _ref.storage;
}
