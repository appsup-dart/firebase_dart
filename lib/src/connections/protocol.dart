// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library firebase.protocol;

import 'dart:async';
import 'dart:convert';
import 'package:quiver/core.dart' as quiver;
import 'package:quiver/check.dart' as quiver;
import 'package:quiver/collection.dart' as quiver;
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol/websocket.dart'
    if (dart.library.html) 'protocol/websocket_html.dart'
    if (dart.library.io) 'protocol/websocket_io.dart';
import 'dart:math';
import '../operations/tree.dart';
import '../treestructureddata.dart';
import 'package:sortedmap/sortedmap.dart';
import '../tree.dart';
import '../repo.dart';
import '../connection.dart';

part 'protocol/request.dart';
part 'protocol/response.dart';
part 'protocol/transport.dart';
part 'protocol/message.dart';
part 'protocol/connection.dart';

final _logger = new Logger("firebase-connection");
