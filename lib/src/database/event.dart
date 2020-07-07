// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

/// An Event is an object that is provided by every Stream on the query
/// object.
///
/// It is simply a wrapper for a tuple of DataSnapshot and PrevChild.
/// Some events (like added, moved or changed) have a prevChild argument
/// that is the name of the object that is before the object referred by the
/// event in priority order.
class Event {
  /// The [DataSnapshot] representing the new value.
  final DataSnapshot snapshot;

  /// The key of the previous child.
  final String prevChild;

  /// Creates a new event
  Event(this.snapshot, this.prevChild);
}
