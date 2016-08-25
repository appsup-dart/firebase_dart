// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of firebase_dart;

String _signMessage(String msg, String secret) {
  final hmac = new Hmac(sha256, secret.codeUnits);
  final signature = hmac.convert(msg.codeUnits);
  return BASE64URL.encode(signature.bytes).replaceAll("=","");
}

class InvalidTokenException implements Exception {

  final String token;

  InvalidTokenException(this.token);

  FirebaseToken get payload => const _Decoder(null).convert(token);
}

class _Encoder extends Converter<FirebaseToken, String> {
  static const Map<String,String> _defaultHeader =  const {
    'typ': 'JWT',
    'alg': 'HS256'
  };

  final String secret;

  const _Encoder(this.secret);

  @override
  String convert(FirebaseToken data) {
    var encodedHeader = BASE64URL.encode(JSON.encode(_defaultHeader).codeUnits).replaceAll("=","");
    var encodedPayload = BASE64URL.encode(JSON.encode(data).codeUnits).replaceAll("=","");
    var msg = "$encodedHeader.$encodedPayload";
    return "$msg.${_signMessage(msg, secret)}";
  }


}

class _Decoder extends Converter<String, FirebaseToken> {

  final String secret;

  const _Decoder(this.secret);


  @override
  FirebaseToken convert(String input) {
    var parts = input.split(".");
    var padded = parts[1] + new Iterable.generate((4-parts[1].length%4)%4,(i)=>"=").join();
    var payload = JSON.decode(UTF8.decode(BASE64URL.decode(padded)));

    if (secret!=null) {
      var signature = _signMessage("${parts[0]}.${parts[1]}", secret);
      if (signature!=parts[2]) {
        throw new InvalidTokenException(input);
      }
    }
    return new FirebaseToken.fromJson(payload as Map<String,dynamic>);
  }
}

class FirebaseTokenCodec extends Codec<FirebaseToken,String> {
  final String secret;

  const FirebaseTokenCodec(this.secret);


  @override
  Converter<String, FirebaseToken> get decoder => new _Decoder(secret);

  @override
  Converter<FirebaseToken, String> get encoder => new _Encoder(secret);
}

class FirebaseToken {

  final int version;
  final DateTime issuedAt;
  final Map<String,dynamic> data;

  final DateTime notBefore;
  final DateTime expires;
  final bool admin;
  final bool debug;

  FirebaseToken(this.data, {this.version: 0, DateTime issuedAt, this.notBefore,
  this.expires, this.debug, this.admin}) : issuedAt = issuedAt ?? new DateTime.now();

  factory FirebaseToken.fromJson(Map<String, dynamic> json) {
    return new FirebaseToken(json["d"] as Map<String, dynamic>,
        version: json["v"], issuedAt: new DateTime.fromMillisecondsSinceEpoch(json["iat"]),
        notBefore: json.containsKey("nbf") ? new DateTime.fromMillisecondsSinceEpoch(json["nbf"]) : null,
        expires: json.containsKey("exp") ? new DateTime.fromMillisecondsSinceEpoch(json["exp"]) : null,
        debug: json["debug"] ?? false, admin: json["admin"] ?? false
    );
  }

  Map<String,dynamic> toJson() {
    var out = {
      "v": version,
      "iat": issuedAt.millisecondsSinceEpoch,
      "d": data
    };
    if (notBefore!=null) out["nbf"] = notBefore.millisecondsSinceEpoch;
    if (expires!=null) out["exp"] = expires.millisecondsSinceEpoch;
    if (debug==true) out["debug"] = true;
    if (admin==true) out["admin"] = true;

    return out;
  }
}



