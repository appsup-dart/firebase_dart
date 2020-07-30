// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library firebase.protocol;

import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:firebase_dart/database.dart' hide ServerValue;
import 'package:firebase_dart/src/database/impl/connections/protocol/retry_helper.dart';
import 'package:jose/jose.dart';
import 'package:quiver/core.dart' as quiver;
import 'package:quiver/check.dart' as quiver;
import 'package:quiver/collection.dart' as quiver;
import 'package:logging/logging.dart';

import 'protocol/websocket.dart'
    if (dart.library.html) 'protocol/websocket_html.dart'
    if (dart.library.io) 'protocol/websocket_io.dart' as websocket;
import 'dart:math';
import '../treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';
import '../connection.dart';
import 'package:dart2_constant/convert.dart';
import 'package:stream_channel/stream_channel.dart';

part 'protocol/request.dart';

part 'protocol/response.dart';

part 'protocol/transport.dart';

part 'protocol/message.dart';

part 'protocol/persistent_connection.dart';
part 'protocol/connection.dart';
part 'protocol/frames.dart';

final _logger = Logger('firebase-connection');
