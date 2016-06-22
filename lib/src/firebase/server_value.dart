// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

class ServerValue extends MapView<String,String> {

  static const ServerValue timestamp = const ServerValue._(const {".sv": "timestamp"});

  const ServerValue._(Map<String,String> map) : super(map);

}