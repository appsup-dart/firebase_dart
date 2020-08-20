import 'dart:convert';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:_discoveryapis_commons/src/requests.dart' as client_requests;
import 'package:googleapis/identitytoolkit/v3.dart' as it;
import 'package:http/http.dart' as http;

import '../error.dart';
import '../utils.dart';
import 'error.dart';

export 'package:googleapis/identitytoolkit/v3.dart';

mixin _JsonSerializable {
  void _read(Map<String, dynamic> _json) {}
  Map<String, dynamic> _write(Map<String, dynamic> _json) => _json;
}
mixin _ReturnSecureTokenProperty on _JsonSerializable {
  /// Whether return sts id token and refresh token instead of gitkit token.
  bool returnSecureToken;

  @override
  Map<String, dynamic> _write(Map<String, dynamic> _json) {
    _json = super._write(_json);
    if (returnSecureToken != null) {
      _json['returnSecureToken'] = returnSecureToken;
    }
    return _json;
  }

  @override
  void _read(Map<String, dynamic> _json) {
    super._read(_json);
    if (_json.containsKey('returnSecureToken')) {
      returnSecureToken = _json['returnSecureToken'];
    }
  }
}

mixin IdTokenResponse on _JsonSerializable {
  String get idToken;

  String get refreshToken;

  String get expiresIn;

  dynamic get mfaPendingCredential => _mfaPendingCredential;

  dynamic _mfaPendingCredential;

  @override
  Map<String, dynamic> _write(Map<String, dynamic> _json) {
    _json = super._write(_json);
    if (mfaPendingCredential != null) {
      _json['mfaPendingCredential'] = mfaPendingCredential;
    }
    return _json;
  }

  @override
  void _read(Map<String, dynamic> _json) {
    super._read(_json);
    if (_json.containsKey('mfaPendingCredential')) {
      _mfaPendingCredential = _json['mfaPendingCredential'];
    }
  }
}

mixin _TenantIdProperty on _JsonSerializable {
  /// For multi-tenant use cases, in order to construct sign-in URL with the
  /// correct IDP parameters, Firebear needs to know which Tenant to retrieve
  /// IDP configs from.
  String tenantId;

  @override
  Map<String, dynamic> _write(Map<String, dynamic> _json) {
    _json = super._write(_json);
    if (tenantId != null) {
      _json['tenantId'] = tenantId;
      if (_json.containsKey('tenantId')) {
        tenantId = _json['tenantId'];
      }
    }
    return _json;
  }
}

class SetAccountInfoResponse extends it.SetAccountInfoResponse
    with _JsonSerializable, IdTokenResponse {
  SetAccountInfoResponse();

  SetAccountInfoResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class VerifyPasswordResponse extends it.VerifyPasswordResponse
    with _JsonSerializable, IdTokenResponse {
  VerifyPasswordResponse();

  VerifyPasswordResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse
    extends it.IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse
    with _JsonSerializable, IdTokenResponse {
  IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse();

  IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse.fromJson(Map _json)
      : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class VerifyCustomTokenResponse extends it.VerifyCustomTokenResponse
    with _JsonSerializable, IdTokenResponse {
  VerifyCustomTokenResponse();

  VerifyCustomTokenResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class EmailLinkSigninResponse extends it.EmailLinkSigninResponse
    with _JsonSerializable, IdTokenResponse {
  EmailLinkSigninResponse();

  EmailLinkSigninResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class SignupNewUserResponse extends it.SignupNewUserResponse
    with _JsonSerializable, IdTokenResponse {
  SignupNewUserResponse();

  SignupNewUserResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class VerifyAssertionResponse extends it.VerifyAssertionResponse
    with _JsonSerializable, IdTokenResponse {
  String _pendingToken;

  String nonce;

  String get pendingToken => _pendingToken;

  VerifyAssertionResponse();

  VerifyAssertionResponse.fromJson(Map _json) : super.fromJson(_json) {
    _read(_json);
  }

  @override
  void _read(Map<String, dynamic> _json) {
    super._read(_json);
    _pendingToken = _json['pendingToken'];
    nonce = _json['nonce'];
  }

  @override
  Map<String, dynamic> _write(Map<String, dynamic> _json) {
    return {
      ...super._write(_json),
      if (pendingToken != null) 'pendingToken': pendingToken,
      if (nonce != null) 'nonce': nonce
    };
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class Relyingparty extends it.Relyingparty {
  String dynamicLinkDomain;

  Relyingparty();

  Relyingparty.fromJson(Map _json) : super.fromJson(_json) {
    dynamicLinkDomain = _json['dynamicLinkDomain'];
  }

  @override
  Map<String, Object> toJson() => {
        ...super.toJson(),
        if (dynamicLinkDomain != null) 'dynamicLinkDomain': dynamicLinkDomain
      };
}

class IdentitytoolkitRelyingpartyEmailLinkSigninRequest
    extends it.IdentitytoolkitRelyingpartyEmailLinkSigninRequest
    with _JsonSerializable, _ReturnSecureTokenProperty, _TenantIdProperty {
  IdentitytoolkitRelyingpartyEmailLinkSigninRequest();

  IdentitytoolkitRelyingpartyEmailLinkSigninRequest.fromJson(Map _json)
      : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class IdentitytoolkitRelyingpartySignupNewUserRequest
    extends it.IdentitytoolkitRelyingpartySignupNewUserRequest
    with _JsonSerializable, _ReturnSecureTokenProperty {
  IdentitytoolkitRelyingpartySignupNewUserRequest();

  IdentitytoolkitRelyingpartySignupNewUserRequest.fromJson(Map _json)
      : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class IdentitytoolkitRelyingpartyVerifyCustomTokenRequest
    extends it.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest
    with _JsonSerializable, _TenantIdProperty {
  IdentitytoolkitRelyingpartyVerifyCustomTokenRequest();

  IdentitytoolkitRelyingpartyVerifyCustomTokenRequest.fromJson(Map _json)
      : super.fromJson(_json) {
    _read(_json);
  }

  @override
  Map<String, Object> toJson() => _write(super.toJson());
}

class _MyApiRequester extends commons.ApiRequester {
  _MyApiRequester(
      http.Client httpClient, String rootUrl, String basePath, String userAgent)
      : super(httpClient, rootUrl, basePath, userAgent);

  final Duration _shortTimeout = Duration(seconds: 30);
  final Duration _longTimeout = Duration(seconds: 60);

  static const _offlineTimeout = Duration(seconds: 5);

  Duration get timeoutDuration {
    // navigator.onLine is unreliable in some cases.
    // Failing hard in those cases may make it impossible to recover for end user.
    // Waiting for the regular full duration when there is no network can result
    // in a bad experience.
    // Instead return a short timeout duration. If there is no network connection,
    // the user would wait 5 seconds to detect that. If there is a connection
    // (false alert case), the user still has the ability to try to send the
    // request. If it fails (timeout too short), they can still retry.
    if (!platform.isOnline) {
      // Pick the shorter timeout.
      return _offlineTimeout < _shortTimeout ? _offlineTimeout : _shortTimeout;
    }
    // If running in a mobile environment, return the long delay, otherwise
    // return the short delay.
    // This could be improved in the future to dynamically change based on other
    // variables instead of just reading the current environment.
    return platform.isMobile ? _longTimeout : _shortTimeout;
  }

  @override
  Future request(String requestUrl, String method,
      {String body,
      Map<String, List<String>> queryParams,
      commons.Media uploadMedia,
      commons.UploadOptions uploadOptions,
      commons.DownloadOptions downloadOptions =
          client_requests.DownloadOptions.Metadata}) async {
    try {
      var fields = queryParams.remove('fields') ?? [];

      return await super
          .request(requestUrl, method,
              body: body,
              queryParams: {
                ...queryParams,
                if (fields.isNotEmpty)
                  ...Uri.splitQueryString(fields.first)
                      .map((k, v) => MapEntry(k, [v])),
              },
              uploadMedia: uploadMedia,
              uploadOptions: uploadOptions,
              downloadOptions: downloadOptions)
          .timeout(timeoutDuration,
              onTimeout: () =>
                  throw FirebaseAuthException.networkRequestFailed());
    } on it.DetailedApiRequestError catch (e) {
      var errorCode = e.message;
      var errorMessage;
      // Get detailed message if available.
      var match = RegExp(r'^([^\s]+)\s*:\s*(.*)$').firstMatch(errorCode);
      if (match != null) {
        errorCode = match.group(1);
        errorMessage = match.group(2);
      }

      var error = authErrorFromServerErrorCode(errorCode);
      if (error == null) {
        error = FirebaseAuthException.internalError();
        errorMessage ??= json.encode(e.jsonResponse);
      }
      throw error.replace(message: errorMessage);
    }
  }
}

class _Client extends http.BaseClient {
  final http.Client baseClient;

  _Client(this.baseClient);

  String locale;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (locale != null) request.headers['X-Firebase-Locale'] = locale;
    return baseClient.send(request);
  }
}

class IdentitytoolkitApi implements it.IdentitytoolkitApi {
  final commons.ApiRequester _requester;
  final _Client _client;

  /// Updates the custom locale header.
  void updateCustomLocaleHeader(String languageCode) {
    _client.locale = languageCode;
  }

  @override
  RelyingpartyResourceApi get relyingparty =>
      RelyingpartyResourceApi(_requester);

  IdentitytoolkitApi._(this._client,
      {String rootUrl = 'https://www.googleapis.com/',
      String servicePath = 'identitytoolkit/v3/relyingparty/'})
      : _requester =
            _MyApiRequester(_client, rootUrl, servicePath, it.USER_AGENT);

  IdentitytoolkitApi(http.Client client,
      {String rootUrl = 'https://www.googleapis.com/',
      String servicePath = 'identitytoolkit/v3/relyingparty/'})
      : this._(_Client(client), rootUrl: rootUrl, servicePath: servicePath);
}

class RelyingpartyResourceApi extends it.RelyingpartyResourceApi {
  final commons.ApiRequester _requester;

  RelyingpartyResourceApi(this._requester) : super(_requester);

  @override
  Future<VerifyPasswordResponse> verifyPassword(
      it.IdentitytoolkitRelyingpartyVerifyPasswordRequest request,
      {String $fields}) async {
    return VerifyPasswordResponse.fromJson(
        await _do('verifyPassword', request, $fields: $fields));
  }

  @override
  Future<IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse>
      verifyPhoneNumber(
          it.IdentitytoolkitRelyingpartyVerifyPhoneNumberRequest request,
          {String $fields}) async {
    return IdentitytoolkitRelyingpartyVerifyPhoneNumberResponse.fromJson(
        await _do('verifyPhoneNumber', request, $fields: $fields));
  }

  @override
  Future<SetAccountInfoResponse> setAccountInfo(
      it.IdentitytoolkitRelyingpartySetAccountInfoRequest request,
      {String $fields}) async {
    return SetAccountInfoResponse.fromJson(
        await _do('setAccountInfo', request, $fields: $fields));
  }

  @override
  Future<VerifyCustomTokenResponse> verifyCustomToken(
      it.IdentitytoolkitRelyingpartyVerifyCustomTokenRequest request,
      {String $fields}) async {
    return VerifyCustomTokenResponse.fromJson(
        await _do('verifyCustomToken', request, $fields: $fields));
  }

  @override
  Future<EmailLinkSigninResponse> emailLinkSignin(
      it.IdentitytoolkitRelyingpartyEmailLinkSigninRequest request,
      {String $fields}) async {
    return EmailLinkSigninResponse.fromJson(
        await _do('emailLinkSignin', request, $fields: $fields));
  }

  @override
  Future<SignupNewUserResponse> signupNewUser(
      it.IdentitytoolkitRelyingpartySignupNewUserRequest request,
      {String $fields}) async {
    return SignupNewUserResponse.fromJson(
        await _do('signupNewUser', request, $fields: $fields));
  }

  @override
  Future<VerifyAssertionResponse> verifyAssertion(
      it.IdentitytoolkitRelyingpartyVerifyAssertionRequest request,
      {String $fields}) async {
    return VerifyAssertionResponse.fromJson(
        await _do('verifyAssertion', request, $fields: $fields));
  }

  Future<dynamic> _do(String url, dynamic request, {String $fields}) {
    var body = request == null ? null : json.encode(request);

    return _requester.request(url, 'POST',
        body: body,
        queryParams: {
          if ($fields != null) 'fields': [$fields]
        },
        downloadOptions: commons.DownloadOptions.Metadata);
  }
}
