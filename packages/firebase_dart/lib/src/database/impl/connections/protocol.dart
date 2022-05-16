// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library firebase.protocol;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:firebase_dart/database.dart' hide ServerValue;
import 'package:firebase_dart/src/database/impl/connections/protocol/retry_helper.dart';
import 'package:firebase_dart/src/database/impl/memory_backend.dart';
import 'package:firebase_dart/src/implementation.dart';
import 'package:jose/jose.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:quiver/collection.dart' as quiver;
import 'package:sortedmap/sortedmap.dart';
import 'package:stream_channel/stream_channel.dart';

import '../connection.dart';
import '../query_spec.dart';
import '../treestructureddata.dart';
import 'protocol/websocket.dart'
    if (dart.library.html) 'protocol/websocket_html.dart'
    if (dart.library.io) 'protocol/websocket_io.dart' as websocket;

part 'protocol/connection.dart';
part 'protocol/frames.dart';
part 'protocol/message.dart';
part 'protocol/persistent_connection.dart';
part 'protocol/request.dart';
part 'protocol/response.dart';
part 'protocol/transport.dart';

final _logger = Logger('firebase-connection');
