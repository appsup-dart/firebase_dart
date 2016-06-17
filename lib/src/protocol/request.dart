// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;


class Request {

  static int nextRequestNum = 0;

  final DataMessage message;

  final Completer<Response> _completer = new Completer();
  Future<Response> get response => _completer.future;

  Request(String action, MessageBody body) :
      message = new DataMessage(action, body, reqNum: nextRequestNum++);

  Request.auth(String cred) : this(DataMessage.action_auth, new MessageBody(cred: cred));
  Request.unauth() : this(DataMessage.action_unauth, new MessageBody());
  Request.listen(String path, {Query query, int tag, String hash})
      : this(DataMessage.action_listen, new MessageBody(path: path, query: query, tag: tag, hash: hash));
  Request.unlisten(String path, {dynamic query, int tag})
      : this(DataMessage.action_unlisten, new MessageBody(path: path, query: query, tag: tag));
  Request.onDisconnectPut(String path, data)
      : this(DataMessage.action_on_disconnect_put, new MessageBody(path: path, data: data));
  Request.onDisconnectMerge(String path, data)
      : this(DataMessage.action_on_disconnect_merge, new MessageBody(path: path, data: data));
  Request.onDisconnectCancel(String path)
      : this(DataMessage.action_on_disconnect_cancel, new MessageBody(path: path));
  Request.put(String path, data, [String hash])
      : this(DataMessage.action_put, new MessageBody(path: path, data: data, hash: hash));
  Request.merge(String path, data, [String hash])
      : this(DataMessage.action_merge, new MessageBody(path: path, data: data, hash: hash));
  Request.stats(stats)
      : this(DataMessage.action_stats, new MessageBody(stats: stats));


  String toString() => "Request[${JSON.encode(message)}]";
}
