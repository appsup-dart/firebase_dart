// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

class Request {
  static int nextRequestNum = 0;

  final FutureOr<DataMessage> message;
  final int writeId;
  final int reqNum;

  final Completer<Response> _completer = Completer();

  Request(String action, MessageBody body, [this.writeId])
      : reqNum = nextRequestNum,
        message = DataMessage(action, body, reqNum: nextRequestNum++);

  Request.auth(FutureOr<String> cred)
      : reqNum = nextRequestNum,
        message = Future.value(nextRequestNum++).then((reqNum) async {
          var token = await cred;
          return DataMessage(
              _actionFromAuthToken(token), MessageBody(cred: token),
              reqNum: reqNum);
        }),
        writeId = null;

  static String _actionFromAuthToken(String token) {
    if (token == 'owner') {
      // is simulator
      return DataMessage.actionGauth;
    } else if (token.split('.').length == 3) {
      // this is an access token or id token
      try {
        var jwt = JsonWebToken.unverified(token);
        if (jwt.claims.issuedAt != null) {
          // this is an id token
          return DataMessage.actionAuth;
        } else {
          return DataMessage.actionGauth;
        }
      } catch (e) {
        // this is an access token
        return DataMessage.actionGauth;
      }
    } else if (token.split('.').length == 2) {
      // this is an access token
      return DataMessage.actionGauth;
    } else {
      // this is a database secret
      return DataMessage.actionAuth;
    }
  }

  Request.unauth() : this(DataMessage.actionUnauth, MessageBody());

  Request.listen(String path, {Query query, int tag, String hash})
      : this(DataMessage.actionListen,
            MessageBody(path: path, query: query, tag: tag, hash: hash));

  Request.unlisten(String path, {Query query, int tag})
      : this(DataMessage.actionUnlisten,
            MessageBody(path: path, query: query, tag: tag));

  Request.onDisconnectPut(String path, data)
      : this(DataMessage.actionOnDisconnectPut,
            MessageBody(path: path, data: data));

  Request.onDisconnectMerge(String path, data)
      : this(DataMessage.actionOnDisconnectMerge,
            MessageBody(path: path, data: data));

  Request.onDisconnectCancel(String path)
      : this(DataMessage.actionOnDisconnectCancel, MessageBody(path: path));

  Request.put(String path, data, [String hash, int writeId])
      : this(DataMessage.actionPut,
            MessageBody(path: path, data: data, hash: hash), writeId);

  Request.merge(String path, data, [String hash, int writeId])
      : this(DataMessage.actionMerge,
            MessageBody(path: path, data: data, hash: hash), writeId);

  Request.stats(stats)
      : this(DataMessage.actionStats, MessageBody(stats: stats));

  Future<Response> get response => _completer.future;

  @override
  String toString() => 'Request[${json.encode(message)}]';
}
