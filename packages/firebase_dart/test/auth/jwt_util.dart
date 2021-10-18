import 'dart:math';

import 'package:clock/clock.dart';
import 'package:jose/jose.dart';

final key = JsonWebKey.fromJson({
  'kty': 'oct',
  'k':
      'AyM1SysPpbyDfgZld3umj1qzKObwVMkoqQ-EstJQLr_T-1qS0gZH75aKtMN3Yj0iPS4hcgUuTwjAzZr1Z9CAow'
});

String createMockGoogleIdToken({required String uid, String? email}) {
  var builder = JsonWebSignatureBuilder()
    ..jsonContent = {'sub': uid, if (email != null) 'email': email}
    ..addRecipient(key);
  return builder.build().toCompactSerialization();
}

String createMockJwt({String? uid, String? providerId}) {
  var builder = JsonWebSignatureBuilder()
    ..jsonContent = _jwtPayloadFor(uid, providerId)
    ..addRecipient(key);
  return builder.build().toCompactSerialization();
}

String createMockCustomToken({String? uid}) {
  var builder = JsonWebSignatureBuilder()
    ..jsonContent = {'uid': uid}
    ..addRecipient(key);
  return builder.build().toCompactSerialization();
}

Map<String, dynamic> _jwtPayloadFor(String? uid, String? providerId) {
  var now = clock.now().millisecondsSinceEpoch ~/ 1000;
  return {
    'iss': 'https://securetoken.google.com/12345678',
    if (providerId != null) 'provider_id': providerId,
    'aud': '12345678',
    'auth_time': now,
    'sub': uid,
    'iat': now,
    'exp': now + 3600,
    if (providerId == 'anonymous')
      'firebase': {'identities': {}, 'sign_in_provider': 'anonymous'}
  };
}

final _random = Random(DateTime.now().millisecondsSinceEpoch);

String generateRandomString(int length) {
  var chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  return Iterable.generate(length, (i) => chars[_random.nextInt(chars.length)])
      .join();
}
