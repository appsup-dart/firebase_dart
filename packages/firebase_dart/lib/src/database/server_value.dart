// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of '../database.dart';

class ServerValue extends MapView<String, dynamic> {
  static const ServerValue timestamp = ServerValue._({'.sv': 'timestamp'});

  /// Returns a placeholder value that can be used to atomically increment the
  /// current database value by the provided delta.
  static ServerValue increment(num delta) => ServerValue._({
        '.sv': {'increment': delta}
      });

  const ServerValue._(super.map);
}
