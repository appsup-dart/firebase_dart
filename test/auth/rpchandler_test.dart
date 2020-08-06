import 'package:test/test.dart';

import 'package:firebase_dart/src/auth/rpc/rpc_handler.dart';
import 'package:firebase_dart/src/auth/error.dart';

import 'dart:convert';
import 'dart:async';
import 'package:meta/meta.dart';

import 'jwt_util.dart';
import 'util.dart';

class Tester {
  static const identityToolkitBaseUrl =
      'https://www.googleapis.com/identitytoolkit/v3/relyingparty';

  final String url;
  final dynamic expectedBody;
  final String method;
  final Future Function() action;
  final dynamic Function(Map<String, dynamic>) expectedResult;

  Tester(
      {String path,
      this.expectedBody,
      this.method = 'POST',
      this.action,
      this.expectedResult})
      : url = '$identityToolkitBaseUrl/$path';

  Future<void> shouldSucceed(
      {String url,
      dynamic expectedBody,
      @required FutureOr<Map<String, dynamic>> serverResponse,
      Map<String, String> expectedHeaders,
      Future Function() action,
      dynamic Function(Map<String, dynamic>) expectedResult,
      String method}) async {
    when(method ?? this.method, url ?? this.url)
      ..expectBody(expectedBody ?? this.expectedBody)
      ..expectHeaders(expectedHeaders)
      ..thenReturn(serverResponse);
    var response = await serverResponse;
    expectedResult ??= this.expectedResult ?? (r) async => r;
    var v = await (action ?? this.action)();
    expect(json.decode(json.encode(v)), await expectedResult(response));
  }

  Future<void> shouldFail(
      {String url,
      dynamic expectedBody,
      @required FutureOr<Map<String, dynamic>> serverResponse,
      @required AuthException expectedError,
      Future Function() action,
      String method}) async {
    when(method ?? this.method, url ?? this.url)
      ..expectBody(expectedBody ?? this.expectedBody)
      ..thenReturn(serverResponse);
    expect(action ?? this.action, throwsA(expectedError));
  }

  Future<void> shouldFailWithServerErrors(
      {String url,
      String method,
      Map<String, dynamic> expectedBody,
      Future Function() action,
      @required Map<String, AuthException> errorMap}) async {
    for (var serverErrorCode in errorMap.keys) {
      var expectedError = errorMap[serverErrorCode];

      when(method ?? this.method, url ?? this.url)
        ..expectBody(expectedBody ?? this.expectedBody)
        ..thenReturn(Tester.errorResponse(serverErrorCode));

      var e = await (action ?? this.action)()
          .then<dynamic>((v) => v)
          .catchError((e) => e);
      await expect(e, expectedError);
    }
  }

  static Map<String, dynamic> errorResponse(String message,
          {Map<String, dynamic> extras}) =>
      {
        'error': {
          'errors': [
            {...?extras, 'message': message}
          ],
          'code': 400,
          'message': message
        }
      };
}

void main() {
  mockOpenidResponses();

  group('RpcHandler', () {
    var rpcHandler = RpcHandler('apiKey', httpClient: mockHttpClient);

    setUp(() {
      rpcHandler..tenantId = null;
    });

    group('getAccountInfoByIdToken', () {
      var tester = Tester(
        path: 'getAccountInfo',
        expectedBody: {'idToken': 'ID_TOKEN'},
        action: () => rpcHandler.getAccountInfoByIdToken('ID_TOKEN'),
      );
      test('getAccountInfoByIdToken: success', () async {
        await tester.shouldSucceed(
          serverResponse: {
            'users': [
              {
                'localId': '14584746072031976743',
                'email': 'uid123@fake.com',
                'emailVerified': true,
                'displayName': 'John Doe',
                'providerUserInfo': [
                  {
                    'providerId': 'google.com',
                    'displayName': 'John Doe',
                    'photoUrl':
                        'https://lh5.googleusercontent.com/123456789/photo.jpg',
                    'federatedId': 'https://accounts.google.com/123456789'
                  },
                  {
                    'providerId': 'twitter.com',
                    'displayName': 'John Doe',
                    'photoUrl':
                        'http://abs.twimg.com/sticky/default_profile_images/def'
                            'ault_profile_3_normal.png',
                    'federatedId': 'http://twitter.com/987654321'
                  }
                ],
                'photoUrl': 'http://abs.twimg.com/sticky/photo.png',
                'passwordUpdatedAt': 0.0,
                'disabled': false
              }
            ]
          },
        );
      });
    });
    group('signInAnonymously', () {
      var tester = Tester(
        path: 'signupNewUser',
        expectedBody: {'returnSecureToken': true},
        expectedResult: (response) => {'id_token': response['idToken']},
        action: () => rpcHandler
            .signInAnonymously()
            .then((v) => {'id_token': v.response['id_token']}),
      );
      test('signInAnonymously: success', () async {
        await tester.shouldSucceed(
          serverResponse: {
            'idToken': createMockJwt(
                uid: generateRandomString(24), providerId: 'anonymous')
          },
        );
      });
      test('signInAnonymously: tenant id', () async {
        rpcHandler.tenantId = '123456789012';
        await tester.shouldSucceed(
          expectedBody: {'returnSecureToken': true, 'tenantId': '123456789012'},
          serverResponse: {
            'idToken': createMockJwt(
                uid: generateRandomString(24), providerId: 'anonymous')
          },
        );
      });
      test('signInAnonymously: unsupported tenant operation', () async {
        rpcHandler.tenantId = '123456789012';
        await tester.shouldFailWithServerErrors(
          expectedBody: {'returnSecureToken': true, 'tenantId': '123456789012'},
          errorMap: {
            'UNSUPPORTED_TENANT_OPERATION':
                AuthException.unsupportedTenantOperation(),
          },
        );
      });
      test('signInAnonymously: unknown server response', () async {
        // Test when server returns unexpected response with no error message.
        await tester.shouldFail(
          serverResponse: {},
          expectedError: AuthException.internalError(),
        );
      });
    });
  });
}
