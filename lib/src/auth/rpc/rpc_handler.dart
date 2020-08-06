import 'identitytoolkit.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../error.dart';
import 'package:openid_client/openid_client.dart' as openid;

class RpcHandler {
  final IdentitytoolkitApi identitytoolkitApi;

  final http.Client httpClient;

  /// The tenant ID.
  String tenantId;

  RelyingpartyResourceApi get relyingparty => identitytoolkitApi.relyingparty;

  RpcHandler(String apiKey, {this.httpClient})
      : identitytoolkitApi =
            IdentitytoolkitApi(clientViaApiKey(apiKey, baseClient: httpClient));

  /// Signs in a user as anonymous.
  ///
  /// Returns a future that resolves with the ID token.
  Future<openid.Credential> signInAnonymously() async {
    var response = await relyingparty
        .signupNewUser(IdentitytoolkitRelyingpartySignupNewUserRequest()
          ..returnSecureToken = true
          ..tenantId = tenantId);

    if (response.idToken == null) {
      throw AuthException.internalError();
    }

    return _credentialFromIdToken(
        idToken: response.idToken,
        refreshToken: response.refreshToken,
        expiresIn: response.expiresIn);
  }

  Future<openid.Credential> _credentialFromIdToken(
      {String idToken, String refreshToken, String expiresIn}) async {
    var client =
        await openid.Client.forIdToken(idToken, httpClient: httpClient);
    return client.createCredential(
      accessToken: idToken,
      idToken: idToken,
      expiresIn: Duration(seconds: int.parse(expiresIn ?? '3600')),
      refreshToken: refreshToken,
    );
  }
}
