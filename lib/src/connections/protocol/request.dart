// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class Request {
  static int nextRequestNum = 0;

  final DataMessage message;
  final int writeId;

  final Completer<Response> _completer = new Completer();

  Request(String action, MessageBody body, [this.writeId])
      : message = new DataMessage(action, body, reqNum: nextRequestNum++);

  Request.auth(String cred)
      : this(DataMessage.actionAuth, new MessageBody(cred: cred));
  Request.gauth(String cred)
      : this(DataMessage.actionGauth, new MessageBody(cred: cred));
  Request.unauth() : this(DataMessage.actionUnauth, new MessageBody());
  Request.listen(String path, {Query query, int tag, String hash})
      : this(DataMessage.actionListen,
            new MessageBody(path: path, query: query, tag: tag, hash: hash));
  Request.unlisten(String path, {Query query, int tag})
      : this(DataMessage.actionUnlisten,
            new MessageBody(path: path, query: query, tag: tag));
  Request.onDisconnectPut(String path, data)
      : this(DataMessage.actionOnDisconnectPut,
            new MessageBody(path: path, data: data));
  Request.onDisconnectMerge(String path, data)
      : this(DataMessage.actionOnDisconnectMerge,
            new MessageBody(path: path, data: data));
  Request.onDisconnectCancel(String path)
      : this(DataMessage.actionOnDisconnectCancel, new MessageBody(path: path));
  Request.put(String path, data, [String hash, int writeId])
      : this(DataMessage.actionPut,
            new MessageBody(path: path, data: data, hash: hash), writeId);
  Request.merge(String path, data, [String hash, int writeId])
      : this(DataMessage.actionMerge,
            new MessageBody(path: path, data: data, hash: hash), writeId);
  Request.stats(stats)
      : this(DataMessage.actionStats, new MessageBody(stats: stats));

  Future<Response> get response => _completer.future;

  @override
  String toString() => "Request[${JSON.encode(message)}]";
}
