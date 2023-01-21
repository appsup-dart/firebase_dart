// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

/// A request to be sent to the server
class Request {
  static int nextRequestNum = 0;

  /// The message to be sent
  final DataMessage message;

  final Completer<Response> _completer = Completer();

  Request(String action, MessageBody body)
      : message = DataMessage(action, body, reqNum: nextRequestNum++);

  Request.auth(String cred)
      : message = DataMessage(
            _actionFromAuthToken(cred), MessageBody(cred: cred),
            reqNum: nextRequestNum++);

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

  Request.listen(String path,
      {required QueryFilter query, required int tag, required String hash})
      : this(
            DataMessage.actionListen,
            MessageBody(
                path: path,
                query: query.limits ? query : null,
                tag: query.limits ? tag : null,
                hash: hash));

  Request.unlisten(String path, {required QueryFilter query, required int tag})
      : this(
            DataMessage.actionUnlisten,
            MessageBody(
              path: path,
              query: query.limits ? query : null,
              tag: query.limits ? tag : null,
            ));

  Request.onDisconnectPut(String path, data)
      : this(DataMessage.actionOnDisconnectPut,
            MessageBody(path: path, data: data));

  Request.onDisconnectMerge(String path, data)
      : this(DataMessage.actionOnDisconnectMerge,
            MessageBody(path: path, data: data));

  Request.onDisconnectCancel(String path)
      : this(DataMessage.actionOnDisconnectCancel, MessageBody(path: path));

  Request.put(String path, data, [String? hash])
      : this(DataMessage.actionPut,
            MessageBody(path: path, data: data, hash: hash));

  Request.merge(String path, data, [String? hash])
      : this(DataMessage.actionMerge,
            MessageBody(path: path, data: data, hash: hash));

  Request.stats(stats)
      : this(DataMessage.actionStats, MessageBody(stats: stats));

  /// The response for this request
  Future<Response> get response => _completer.future;

  @override
  String toString() =>
      'Request[${message is Future ? '' : json.encode(message)}]';
}
