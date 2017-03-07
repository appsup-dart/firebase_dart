// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

/// A [DataSnapshot] contains data from a Firebase database location.
/// Any time you read data from a Firebase database, you receive the data as a
/// DataSnapshot.
///
/// DataSnapshots are passed to event handlers such as onValue or onceValue.
/// You can extract the contents of the snapshot by calling val(), or you
/// can traverse into the snapshot by calling child() to return child
/// snapshots (which you could in turn call val() on).
abstract class DataSnapshot {
  /// Gets the Firebase reference for the location that generated this
  /// DataSnapshot.
  final Firebase ref;

  /// Creates a new [DataSnapshot] instance.
  DataSnapshot(this.ref);

  /// Get the Dart Primitive, Map or List representation of the DataSnapshot.
  /// The value may be null, indicating that the snapshot is empty and contains
  /// no data.
  dynamic get val;

  /// Returns true if this DataSnapshot contains any data.
  /// It is slightly more efficient than using snapshot.val() !== null.
  bool get exists;

  /// Get a DataSnapshot for the location at the specified relative path. The
  /// relative path can either be a simple child name or a deeper slash
  /// separated path.
  DataSnapshot child(String c);

  /// Enumerate through the DataSnapshot's children (in priority order). The
  /// provided callback will be called synchronously with a DataSnapshot for
  /// each child.
  void forEach(cb(DataSnapshot snapshot));

  /// Returns true if the specified child exists.
  bool hasChild(String path);

  /// `true` if the DataSnapshot has any children.
  ///
  /// If it does, you can enumerate them with forEach. If not, then the
  /// snapshot either contains a primitive value or it is empty.
  bool get hasChildren;

  /// The key of the location that generated this DataSnapshot.
  String get key => ref.key;

  /// The number of children for this DataSnapshot. If it has children,
  /// you can enumerate them with forEach().
  int get numChildren;

  /// Get the priority of the data in this DataSnapshot.
  dynamic get priority;

  /// Exports the entire contents of the DataSnapshot as a Dart Map. This is
  /// similar to val(), except priority information is included, making it
  /// suitable for backing up your data.
  dynamic exportVal();
}
