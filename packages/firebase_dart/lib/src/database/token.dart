// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:jose/jose.dart';

class _Encoder extends Converter<FirebaseToken, String> {
  final String? secret;

  const _Encoder(this.secret);

  @override
  String convert(FirebaseToken data) {
    var key = JsonWebKey.symmetric(
        key: secret!.codeUnits.fold(
            BigInt.from(0), (a, b) => a * BigInt.from(256) + BigInt.from(b)));
    var builder = JsonWebSignatureBuilder()
      ..jsonContent = data.toJson()
      ..addRecipient(key, algorithm: 'HS256');

    return builder.build().toCompactSerialization();
  }
}

class _Decoder extends Converter<String, FirebaseToken> {
  final String? secret;

  const _Decoder(this.secret);

  @override
  FirebaseToken convert(String input) {
    return FirebaseToken.fromJson(
        JsonWebToken.unverified(input).claims.toJson());
  }
}

class FirebaseTokenCodec extends Codec<FirebaseToken, String> {
  final String? secret;

  const FirebaseTokenCodec(this.secret);

  @override
  Converter<String, FirebaseToken> get decoder => _Decoder(secret);

  @override
  Converter<FirebaseToken, String> get encoder => _Encoder(secret);
}

class FirebaseToken {
  final int? version;
  final DateTime issuedAt;
  final Map<String, dynamic>? data;

  final DateTime? notBefore;
  final DateTime? expires;
  final bool? admin;
  final bool? debug;

  FirebaseToken(this.data,
      {this.version = 0,
      DateTime? issuedAt,
      this.notBefore,
      this.expires,
      this.debug,
      this.admin})
      : issuedAt = issuedAt ?? DateTime.now();

  factory FirebaseToken.fromJson(Map<String, dynamic> json) {
    return FirebaseToken(json['d'] as Map<String, dynamic>?,
        version: json['v'],
        issuedAt: DateTime.fromMillisecondsSinceEpoch(json['iat']),
        notBefore: json.containsKey('nbf')
            ? DateTime.fromMillisecondsSinceEpoch(json['nbf'])
            : null,
        expires: json.containsKey('exp')
            ? DateTime.fromMillisecondsSinceEpoch(json['exp'])
            : null,
        debug: json['debug'] ?? false,
        admin: json['admin'] ?? false);
  }

  Map<String, dynamic> toJson() {
    var out = {'v': version, 'iat': issuedAt.millisecondsSinceEpoch, 'd': data};
    if (notBefore != null) out['nbf'] = notBefore!.millisecondsSinceEpoch;
    if (expires != null) out['exp'] = expires!.millisecondsSinceEpoch;
    if (debug == true) out['debug'] = true;
    if (admin == true) out['admin'] = true;

    return out;
  }
}
