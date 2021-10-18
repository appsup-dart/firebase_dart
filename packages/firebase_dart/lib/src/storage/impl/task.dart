import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:firebase_dart/src/storage/impl/resource_client.dart';
import 'package:rxdart/subjects.dart';

import '../../../storage.dart';
import 'package:http/http.dart';

import '../reference.dart';

import 'package:synchronized/extension.dart';

/// Represents a blob being uploaded.
///
/// Can be used to pause/resume/cancel the upload and manage callbacks for
/// various events.
class UploadTaskImpl extends DelegatingFuture<TaskSnapshot>
    implements UploadTask {
  final ReferenceImpl _ref;

  /// The data to be uploaded.
  final Uint8List _blob;

  final SettableMetadata? _metadata;

  FullMetadata? _fullMetadata;

  final BehaviorSubject<TaskSnapshot> _subject = BehaviorSubject();

  final Completer<TaskSnapshot> _completer;

  /// Upload state.
  InternalTaskState _state = InternalTaskState.running;

  Request? _request;

  StorageException? _error;

  Uri? _uploadUrl;

  bool _needToFetchStatus = false;

  bool _needToFetchMetadata = false;

  /// Number of bytes transferred so far.
  int _transferred = 0;

  int _chunkMultiplier = 1;

  static const _resumableUploadChunkSize = 256 * 1024;

  UploadTaskImpl(ReferenceImpl ref, Uint8List blob, SettableMetadata? metadata)
      : this._(Completer(), ref, blob, metadata);

  UploadTaskImpl._(this._completer, this._ref, this._blob, this._metadata)
      : super(_completer.future) {
    _start();
  }

  @override
  Future<bool> cancel() async {
    final valid = _state == InternalTaskState.running ||
        _state == InternalTaskState.pausing;
    if (valid) {
      _transition(InternalTaskState.canceling);
    }
    return valid;
  }

  @override
  Future<bool> pause() async {
    final valid = _state == InternalTaskState.running;
    if (valid) {
      _transition(InternalTaskState.pausing);
    }
    return valid;
  }

  @override
  Future<bool> resume() async {
    final valid = _state == InternalTaskState.paused ||
        _state == InternalTaskState.pausing;
    if (valid) {
      _transition(InternalTaskState.running);
    }
    return valid;
  }

  @override
  TaskSnapshot get snapshot {
    final externalState = _taskStateFromInternalTaskState(_state);
    return TaskSnapshot(
        bytesTransferred: _transferred,
        totalBytes: _blob.length,
        state: externalState,
        metadata: _fullMetadata,
        ref: _ref);
  }

  @override
  Stream<TaskSnapshot> get snapshotEvents => _subject.stream;

  @override
  FirebaseStorage get storage => _ref.storage;

  void _errorHandler(StorageException error) {
    _chunkMultiplier = 1;
    if (error.code == StorageException.canceled().code) {
      _needToFetchStatus = true;
      _completeTransitions();
    } else {
      _error = error;
      _transition(InternalTaskState.error);
    }
  }

  bool get _resumable => _blob.length > _resumableUploadChunkSize;

  void _start() {
    synchronized(() async {
      if (_state != InternalTaskState.running) {
        // This can happen if someone pauses us in a resume callback, for example.
        return;
      }
      if (_request != null) {
        return;
      }
      if (_resumable) {
        if (_uploadUrl == null) {
          await _createResumable();
        } else {
          if (_needToFetchStatus) {
            await _fetchStatus();
          } else {
            if (_needToFetchMetadata) {
              // Happens if we miss the metadata on upload completion.
              await _fetchMetadata();
            } else {
              await _continueUpload();
            }
          }
        }
      } else {
        await _oneShotUpload();
      }
    });
  }

  Future<void> _createResumable() async {
    try {
      _uploadUrl = await _ref.requests.startResumableUpload(_blob, _metadata);
      _needToFetchStatus = false;
      _completeTransitions();
    } on StorageException catch (e) {
      _errorHandler(e);
    }
  }

  Future<void> _continueUpload() async {
    assert(_uploadUrl != null);

    try {
      final chunkSize = _resumableUploadChunkSize * _chunkMultiplier;
      final status = ResumableUploadStatus(_transferred, _blob.length);

      var newStatus = await _ref.requests
          .continueResumableUpload(_uploadUrl!, _blob, chunkSize, status);

      _increaseMultiplier();

      _updateProgress(newStatus.current);

      if (newStatus.finalized) {
        _fullMetadata = newStatus.metadata;
        _transition(InternalTaskState.success);
      } else {
        _completeTransitions();
      }
    } on StorageException catch (e) {
      _errorHandler(e);
    }
  }

  void _increaseMultiplier() {
    final currentSize = _resumableUploadChunkSize * _chunkMultiplier;

    // Max chunk size is 32M.
    if (currentSize < 32 * 1024 * 1024) {
      _chunkMultiplier *= 2;
    }
  }

  Future<void> _fetchStatus() async {
    assert(_uploadUrl != null);

    try {
      var status =
          await _ref.requests.getResumableUploadStatus(_uploadUrl!, _blob);

      _updateProgress(status.current);
      _needToFetchStatus = false;
      if (status.finalized) {
        _needToFetchMetadata = true;
      }
      _completeTransitions();
    } on StorageException catch (e) {
      _errorHandler(e);
    }
  }

  Future<void> _fetchMetadata() async {
    try {
      var metadata = await _ref.requests.getMetadata();
      _fullMetadata = metadata;
      _transition(InternalTaskState.success);
    } on StorageException catch (error) {
      if (error.code == StorageException.canceled().code) {
        _completeTransitions();
      } else {
        _error = error;
        _transition(InternalTaskState.error);
      }
    }
  }

  void _updateProgress(int transferred) {
    final old = _transferred;
    _transferred = transferred;

    // A progress update can make the "transferred" value smaller (e.g. a
    // partial upload not completed by server, after which the "transferred"
    // value may reset to the value at the beginning of the request).
    if (_transferred != old) {
      _notifyObservers();
    }
  }

  void _transition(InternalTaskState state) {
    if (_state == state) {
      return;
    }
    switch (state) {
      case InternalTaskState.canceling:
        assert(_state == InternalTaskState.running ||
            _state == InternalTaskState.pausing);
        _state = state;
        break;
      case InternalTaskState.pausing:
        assert(_state == InternalTaskState.running);
        _state = state;
        break;
      case InternalTaskState.running:
        assert(_state == InternalTaskState.paused ||
            _state == InternalTaskState.pausing);
        final wasPaused = _state == InternalTaskState.paused;
        _state = state;
        if (wasPaused) {
          _notifyObservers();
          _start();
        }
        break;
      case InternalTaskState.paused:
        assert(_state == InternalTaskState.pausing);
        _state = state;
        _notifyObservers();
        break;
      case InternalTaskState.canceled:
        assert(_state == InternalTaskState.paused ||
            _state == InternalTaskState.canceling);
        _error = StorageException.canceled();
        _state = state;
        _notifyObservers();
        break;
      case InternalTaskState.error:
        assert(_state == InternalTaskState.running ||
            _state == InternalTaskState.pausing ||
            _state == InternalTaskState.canceling);
        _state = state;
        _notifyObservers();
        break;
      case InternalTaskState.success:
        assert(_state == InternalTaskState.running ||
            _state == InternalTaskState.pausing ||
            state == InternalTaskState.canceling);
        _state = state;
        _notifyObservers();
        break;
    }
  }

  void _completeTransitions() {
    switch (_state) {
      case InternalTaskState.pausing:
        _transition(InternalTaskState.paused);
        break;
      case InternalTaskState.canceling:
        _transition(InternalTaskState.canceled);
        break;
      case InternalTaskState.running:
        _start();
        break;
      default:
        assert(false);
        break;
    }
  }

  void _notifyObservers() {
    _subject.add(snapshot);
    _finishWhenDone();
  }

  void _finishWhenDone() {
    if (_completer.isCompleted) return;
    switch (_taskStateFromInternalTaskState(_state)) {
      case TaskState.success:
        _completer.complete(snapshot);
        _subject.close();
        break;
      case TaskState.canceled:
      case TaskState.error:
        _completer.completeError(_error!);
        _subject.close();
        break;
      default:
        break;
    }
  }

  Future<void> _oneShotUpload() async {
    try {
      _fullMetadata = await _ref.requests.multipartUpload(_blob, _metadata);
      _updateProgress(_blob.length);
      _transition(InternalTaskState.success);
    } on StorageException catch (e) {
      _errorHandler(e);
    }
  }
}

/// Internal enum for task state.
enum InternalTaskState {
  running,
  pausing,
  paused,
  success,
  canceling,
  canceled,
  error,
}

TaskState _taskStateFromInternalTaskState(InternalTaskState state) {
  switch (state) {
    case InternalTaskState.running:
    case InternalTaskState.pausing:
    case InternalTaskState.canceling:
      return TaskState.running;
    case InternalTaskState.paused:
      return TaskState.paused;
    case InternalTaskState.success:
      return TaskState.success;
    case InternalTaskState.canceled:
      return TaskState.canceled;
    case InternalTaskState.error:
      return TaskState.error;
  }
}
