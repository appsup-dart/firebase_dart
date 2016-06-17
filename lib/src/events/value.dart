// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../event.dart';

class ValueEvent<T> extends Event {
  final T value;

  ValueEvent(this.value) : super("value");

  @override
  String toString() => "ValueEvent[$value]";
}
