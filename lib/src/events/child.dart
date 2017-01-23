// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../event.dart';

enum ChildChangeType { added, changed, moved, removed }

abstract class ChildEvent<K> extends Event {
  final K childKey;
  final K prevChildKey;

  ChildEvent(String type, this.childKey, this.prevChildKey) : super(type);

  @override
  String toString() => "ChildEvent[$childKey $type]";
}

class ChildAddedEvent<K, V> extends ChildEvent<K> {
  final V newValue;

  ChildAddedEvent(K childKey, this.newValue, K prevChildKey)
      : super("child_added", childKey, prevChildKey);
}

class ChildChangedEvent<K, V> extends ChildEvent<K> {
  final V newValue;

  ChildChangedEvent(K childKey, this.newValue, K prevChildKey)
      : super("child_changed", childKey, prevChildKey);
}

class ChildMovedEvent<K, V> extends ChildEvent<K> {
  ChildMovedEvent(K childKey, K prevChildKey)
      : super("child_moved", childKey, prevChildKey);
}

class ChildRemovedEvent<K, V> extends ChildEvent<K> {
  final V oldValue;

  ChildRemovedEvent(K childKey, this.oldValue, K prevChildKey)
      : super("child_removed", childKey, prevChildKey);
}
