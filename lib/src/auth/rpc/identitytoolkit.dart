import 'package:googleapis/identitytoolkit/v3.dart' as it;
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:_discoveryapis_commons/src/requests.dart' as client_requests;
import 'package:http/http.dart' as http;
import '../utils.dart';
import 'dart:convert';

import 'error.dart';
import '../error.dart';

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
      print(queryParams);
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
              onTimeout: () => throw AuthException.networkRequestFailed());
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
        error = AuthException.internalError();
        errorMessage ??= json.encode(e.jsonResponse);
      }
      throw error.replace(message: errorMessage);
    }
  }
}

class IdentitytoolkitApi implements it.IdentitytoolkitApi {
  final commons.ApiRequester _requester;

  @override
  it.RelyingpartyResourceApi get relyingparty =>
      it.RelyingpartyResourceApi(_requester);

  IdentitytoolkitApi(http.Client client,
      {String rootUrl = 'https://www.googleapis.com/',
      String servicePath = 'identitytoolkit/v3/relyingparty/'})
      : _requester =
            _MyApiRequester(client, rootUrl, servicePath, it.USER_AGENT);
}
