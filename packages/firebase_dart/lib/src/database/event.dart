// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

/// `Event` encapsulates a DataSnapshot and possibly also the key of its
/// previous sibling, which can be used to order the snapshots.
class Event {
  /// The [DataSnapshot] representing the new value.
  final DataSnapshot snapshot;

  /// The key of the previous child.
  final String? previousSiblingKey;

  /// Creates a new event
  Event(this.snapshot, this.previousSiblingKey);
}
