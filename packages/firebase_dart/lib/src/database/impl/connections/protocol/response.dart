// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase.protocol;

/// A response received from the server
class Response {
  /// The message
  final DataMessage message;

  final Request? _request;

  Response(this.message, this._request);

  /// The request for this response
  Request? get request => _request;

  @override
  String toString() => 'Response[${json.encode(message)}]';
}
