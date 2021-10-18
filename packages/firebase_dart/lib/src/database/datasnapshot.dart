// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

/// A [DataSnapshot] contains data from a Firebase database location.
///
/// Any time you read data from a Firebase database, you receive the data as a
/// DataSnapshot.
///
/// DataSnapshots are passed to event handlers such as onValue or onceValue.
abstract class DataSnapshot {
  /// Get the Dart Primitive, Map or List representation of the DataSnapshot.
  ///
  /// The value may be null, indicating that the snapshot is empty and contains
  /// no data.
  dynamic get value;

  /// The key of the location that generated this DataSnapshot.
  String? get key;
}

class MutableData {
  /// The key of the location that generated this MutableData.
  final String? key;

  /// Returns the mutable contents of this MutableData as native types.
  dynamic value;

  MutableData(this.key, this.value);
}
