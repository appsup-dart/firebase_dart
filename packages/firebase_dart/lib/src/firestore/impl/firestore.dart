import 'package:firebase_dart/src/core.dart';
import 'package:firebase_dart/src/firestore/impl/pointer.dart';
import 'package:googleapis/firestore/v1.dart';

import '../../core/impl/app.dart';
import '../../firestore.dart';
import 'client.dart';

/// Helper method exposed to determine whether a given [collectionPath] points to
/// a valid Firestore collection.
///
/// This is exposed to keep the [Pointer] internal to this library.
bool isValidCollectionPath(String collectionPath) {
  return Pointer(collectionPath).isCollection();
}

class FirebaseFirestoreImpl extends FirebaseService
    implements FirebaseFirestore {
  final FirestoreClient client = FirestoreClient();
  FirebaseFirestoreImpl(FirebaseApp app) : super(app);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    assert(
      collectionPath.isNotEmpty,
      'a collectionPath path must be a non-empty string',
    );
    assert(
      !collectionPath.contains('//'),
      'a collection path must not contain "//"',
    );
    assert(
      isValidCollectionPath(collectionPath),
      'a collection path must point to a valid collection.',
    );

    return CollectionReferenceImpl(this, collectionPath);
  }
}

class CollectionReferenceImpl
    extends CollectionReference<Map<String, dynamic>> {
  final FirebaseFirestoreImpl _firestore;

  final String _path;

  CollectionReferenceImpl(this._firestore, this._path);

  @override
  Future<DocumentReference<Map<String, dynamic>>> add(
      Map<String, dynamic> data) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return DocumentReferenceImpl(this, path);
  }

  @override
  Query<Map<String, dynamic>> endAt(List<Object?> values) {
    // TODO: implement endAt
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> endAtDocument(
      DocumentSnapshot<Object?> documentSnapshot) {
    // TODO: implement endAtDocument
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> endBefore(List<Object?> values) {
    // TODO: implement endBefore
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> endBeforeDocument(
      DocumentSnapshot<Object?> documentSnapshot) {
    // TODO: implement endBeforeDocument
    throw UnimplementedError();
  }

  @override
  FirebaseFirestore get firestore => _firestore;

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  Query<Map<String, dynamic>> limit(int limit) {
    // TODO: implement limit
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> limitToLast(int limit) {
    // TODO: implement limitToLast
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> orderBy(Object field, {bool descending = false}) {
    // TODO: implement orderBy
    throw UnimplementedError();
  }

  @override
  // TODO: implement parameters
  Map<String, dynamic> get parameters => throw UnimplementedError();

  @override
  // TODO: implement parent
  DocumentReference<Map<String, dynamic>>? get parent =>
      throw UnimplementedError();

  @override
  // TODO: implement path
  String get path => throw UnimplementedError();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots(
      {bool includeMetadataChanges = false}) {
    // TODO: implement snapshots
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> startAfter(List<Object?> values) {
    // TODO: implement startAfter
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> startAfterDocument(
      DocumentSnapshot<Object?> documentSnapshot) {
    // TODO: implement startAfterDocument
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> startAt(List<Object?> values) {
    // TODO: implement startAt
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> startAtDocument(
      DocumentSnapshot<Object?> documentSnapshot) {
    // TODO: implement startAtDocument
    throw UnimplementedError();
  }

  @override
  Query<Map<String, dynamic>> where(Object field,
      {Object? isEqualTo,
      Object? isNotEqualTo,
      Object? isLessThan,
      Object? isLessThanOrEqualTo,
      Object? isGreaterThan,
      Object? isGreaterThanOrEqualTo,
      Object? arrayContains,
      List<Object?>? arrayContainsAny,
      List<Object?>? whereIn,
      List<Object?>? whereNotIn,
      bool? isNull}) {
    // TODO: implement where
    throw UnimplementedError();
  }

  @override
  CollectionReference<R> withConverter<R extends Object?>(
      {required FromFirestore<R> fromFirestore,
      required ToFirestore<R> toFirestore}) {
    // TODO: implement withConverter
    throw UnimplementedError();
  }
}

class DocumentReferenceImpl extends DocumentReference<Map<String, dynamic>> {
  final CollectionReferenceImpl _collection;

  final String? _path;

  DocumentReferenceImpl(this._collection, this._path);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    // TODO: implement collection
    throw UnimplementedError();
  }

  @override
  Future<void> delete() {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  FirebaseFirestoreImpl get firestore => _collection._firestore;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      [GetOptions? options]) async {
    if (options?.source == Source.cache) {
      var doc = await firestore.client.getDocumentFromLocalCache(_path);
      throw UnimplementedError();
      // TODO
    } else {
      var doc = await firestore.client.api.projects.databases.documents.get(
          'projects/${firestore.app.options.projectId}/databases/(default)/documents/${_collection._path}/$_path');

      return DocumentSnapshotImpl(this, doc);
    }
  }

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  // TODO: implement parent
  CollectionReference<Map<String, dynamic>> get parent =>
      throw UnimplementedError();

  @override
  // TODO: implement path
  String get path => throw UnimplementedError();

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) {
    // TODO: implement set
    throw UnimplementedError();
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots(
      {bool includeMetadataChanges = false}) {
    // TODO: implement snapshots
    throw UnimplementedError();
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  DocumentReference<R> withConverter<R>(
      {required FromFirestore<R> fromFirestore,
      required ToFirestore<R> toFirestore}) {
    // TODO: implement withConverter
    throw UnimplementedError();
  }
}

class DocumentSnapshotImpl extends DocumentSnapshot<Map<String, dynamic>> {
  @override
  final DocumentReferenceImpl reference;

  final Document _document;

  DocumentSnapshotImpl(this.reference, this._document);
  @override
  dynamic operator [](Object field) {
    if (!exists) return null;
    var f = _document.fields![field];

    if (f == null) return null;

    return f.stringValue ??
        f.booleanValue ??
        f.integerValue ??
        f.doubleValue ??
        f.arrayValue ??
        (f.bytesValue == null ? null : f.bytesValueAsBytes) ??
        f.geoPointValue ??
        f.timestampValue ??
        f.referenceValue ??
        f.mapValue;
  }

  @override
  Map<String, dynamic>? data() {
    if (!exists) return null;
    return {for (var k in _document.fields!.keys) k: this[k]};
  }

  @override
  bool get exists => _document.createTime != null;

  @override
  dynamic get(Object field) {
    return this[field];
  }

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  // TODO: implement metadata
  SnapshotMetadata get metadata => throw UnimplementedError();
}
