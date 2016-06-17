// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import '../data_observer.dart';
import '../tree.dart';

class Overwrite<T> extends Operation<T> {
  final T value;

  Overwrite(this.value);

  @override
  T apply(T value) => this.value;

  String toString() => "Overwrite[$value]";

  @override
  Iterable<Path> get completesPaths => [new Path()];
}