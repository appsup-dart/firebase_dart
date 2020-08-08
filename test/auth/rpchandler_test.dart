import 'package:clock/clock.dart';
import 'package:firebase_dart/src/auth/auth_providers.dart';
import 'package:firebase_dart/src/auth/utils.dart';
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

  Tester replace(
          {String path,
          dynamic expectedBody,
          String method,
          Future Function() action,
          dynamic Function(Map<String, dynamic>) expectedResult}) =>
      Tester(
          path: path ?? Uri.parse(url).pathSegments.last,
          expectedBody: expectedBody ?? this.expectedBody,
          method: method ?? this.method,
          action: action ?? this.action,
          expectedResult: expectedResult ?? this.expectedResult);

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

    var pendingCredResponse = {
      'mfaInfo': {
        'mfaEnrollmentId': 'ENROLLMENT_UID1',
        'enrolledAt': clock.now().toIso8601String(),
        'phoneInfo': '+16505551234'
      },
      'mfaPendingCredential': 'PENDING_CREDENTIAL'
    };

    setUp(() {
      rpcHandler
        ..tenantId = null
        ..updateCustomLocaleHeader(null);
      platform = Platform(currentUrl: 'http://localhost');
    });

    group('identitytoolkit', () {
      group('identitytoolkit general', () {
        var tester = Tester(
          path: 'signupNewUser',
          expectedBody: {'returnSecureToken': true},
          expectedResult: (response) => {'id_token': response['idToken']},
          action: () => rpcHandler
              .signInAnonymously()
              .then((v) => {'id_token': v.response['id_token']}),
        );
        group('server provided error message', () {
          test('server provided error message: known error code', () async {
            // Test when server returns an error message with the details appended:
            // INVALID_CUSTOM_TOKEN : [error detail here]
            // The above error message should generate an Auth error with code
            // client equivalent of INVALID_CUSTOM_TOKEN and the message:
            // [error detail here]
            await tester.shouldFail(
              serverResponse: Tester.errorResponse(
                  'INVALID_CUSTOM_TOKEN : Some specific reason.',
                  extras: {
                    'domain': 'global',
                    'reason': 'invalid',
                  }),
              expectedError: AuthException.invalidCustomToken()
                  .replace(message: 'Some specific reason.'),
            );
          });

          test('server provided error message: unknown error code', () async {
            // Test when server returns an error message with the details appended:
            // UNKNOWN_CODE : [error detail here]
            // The above error message should generate an Auth error with internal-error
            // ccode and the message:
            // [error detail here]
            await tester.shouldFail(
              serverResponse: Tester.errorResponse(
                  'WHAAAAAT?: Something strange happened.',
                  extras: {
                    'domain': 'global',
                    'reason': 'invalid',
                  }),
              expectedError: AuthException.internalError()
                  .replace(message: 'Something strange happened.'),
            );
          });

          test('server provided error message: no error code', () async {
            // Test when server returns an unexpected error message with a colon in the
            // message field that it does not treat the string after the colon as the
            // detailed error message. Instead the whole response should be serialized.
            var serverResponse = Tester.errorResponse(
                'Error getting access token from FACEBOOK, response: OA'
                'uth2TokenResponse{params: %7B%22error%22:%7B%22message%22:%22This+IP+'
                'can\'t+make+requests+for+that+application.%22,%22type%22:%22OAuthExce'
                'ption%22,%22code%22:5,%22fbtrace_id%22:%22AHHaoO5cS1K%22%7D%7D&error='
                'OAuthException&error_description=This+IP+can\'t+make+requests+for+tha'
                't+application., httpMetadata: HttpMetadata{status=400, cachePolicy=NO'
                '_CACHE, cacheDuration=null, staleWhileRevalidate=null, filename=null,'
                'lastModified=null, headers=HTTP/1.1 200 OK\r\n\r\n, cookieList=[]}}, '
                'OAuth2 redirect uri is: https://example12345.firebaseapp.com/__/auth/'
                'handler',
                extras: {
                  'domain': 'global',
                  'reason': 'invalid',
                });
            await tester.shouldFail(
              serverResponse: serverResponse,
              expectedError: AuthException.internalError()
                  .replace(message: json.encode(serverResponse)),
            );
          });
        });
        group('unexpected Apiary error', () {
          test('unexpected Apiary error', () async {
            // Test when an unexpected Apiary error is returned that serialized server
            // response is used as the client facing error message.

            // Server response.
            var serverResponse = Tester.errorResponse('Bad Request', extras: {
              'domain': 'usageLimits',
              'reason': 'keyExpired',
            });

            await tester.shouldFail(
              serverResponse: serverResponse,
              expectedError: AuthException.internalError()
                  .replace(message: json.encode(serverResponse)),
            );
          });
        });
      });

      group('getAuthorizedDomains', () {
        var tester = Tester(
            path: 'getProjectConfig',
            expectedBody: null,
            expectedResult: (response) => response['authorizedDomains'],
            action: () => rpcHandler.getAuthorizedDomains(),
            method: 'GET');

        test('getAuthorizedDomains: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'authorizedDomains': ['domain.com', 'www.mydomain.com']
            },
          );
        });
      });

      group('getRecaptchaParam', () {
        var tester = Tester(
            path: 'getRecaptchaParam',
            expectedBody: null,
            action: () => rpcHandler.getRecaptchaParam(),
            method: 'GET');

        test('getRecaptchaParam: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'recaptchaSiteKey': 'RECAPTCHA_SITE_KEY'},
            action: () => rpcHandler.getRecaptchaParam(),
          );
        });

        test('getRecaptchaParam: invalid response: missing site key', () async {
          await tester.shouldFail(
            // If for some reason, sitekey is not returned.
            serverResponse: {},
            expectedError: AuthException.internalError(),
          );
        });
      });
      group('getDynamicLinkDomain', () {
        var tester = Tester(
          path: 'getProjectConfig',
          expectedBody: {'returnDynamicLink': 'true'},
          action: () => rpcHandler.getDynamicLinkDomain(),
          expectedResult: (r) => r['dynamicLinksDomain'],
          method: 'GET',
        );

        test('getDynamicLinkDomain: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'projectId': '12345678',
              'authorizedDomains': ['domain.com', 'www.mydomain.com'],
              'dynamicLinksDomain': 'example.app.goog.gl'
            },
          );
        });
        test('getDynamicLinkDomain: internal error', () async {
          await tester.shouldFail(
            // If for some reason, sitekey is not returned.
            serverResponse: {
              'projectId': '12345678',
              'authorizedDomains': ['domain.com', 'www.mydomain.com']
            },
            expectedError: AuthException.internalError(),
          );
        });
        test('getDynamicLinkDomain: not activated', () async {
          await tester.shouldFail(
            // If for some reason, sitekey is not returned.
            serverResponse: Tester.errorResponse(
              'DYNAMIC_LINK_NOT_ACTIVATED',
              extras: {
                'domain': 'global',
                'reason': 'invalid',
              },
            ),
            expectedError: AuthException.dynamicLinkNotActivated(),
          );
        });
      });

      group('isIosBundleIdValid', () {
        var tester = Tester(
          path: 'getProjectConfig',
          expectedBody: {'iosBundleId': 'com.example.app'},
          action: () => rpcHandler.isIosBundleIdValid('com.example.app'),
          expectedResult: (r) => null,
          method: 'GET',
        );

        test('isIosBundleIdValid: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'projectId': '12345678',
              'authorizedDomains': ['domain.com', 'www.mydomain.com']
            },
          );
        });
        test('isIosBundleIdValid: error', () async {
          await tester.shouldFail(
            // If for some reason, sitekey is not returned.
            serverResponse: Tester.errorResponse('INVALID_APP_ID'),
            expectedError: AuthException.invalidAppId(),
          );
        });
      });

      group('isAndroidPackageNameValid', () {
        var tester = Tester(
          path: 'getProjectConfig',
          expectedBody: {'androidPackageName': 'com.example.app'},
          expectedResult: (r) => null,
          method: 'GET',
        );

        group('isAndroidPackageNameValid: no sha1Cert', () {
          tester = tester.replace(
            action: () =>
                rpcHandler.isAndroidPackageNameValid('com.example.app'),
          );

          test('isAndroidPackageNameValid: no sha1Cert: success', () async {
            await tester.shouldSucceed(
              serverResponse: {
                'projectId': '12345678',
                'authorizedDomains': ['domain.com', 'www.mydomain.com']
              },
            );
          });
          test('isAndroidPackageNameValid: no sha1Cert: error', () async {
            await tester.shouldFail(
              serverResponse: Tester.errorResponse('INVALID_APP_ID'),
              expectedError: AuthException.invalidAppId(),
            );
          });
        });

        group('isAndroidPackageNameValid: sha1Cert', () {
          tester = tester.replace(
            action: () => rpcHandler.isAndroidPackageNameValid(
                'com.example.app', 'SHA_1_ANDROID_CERT'),
            expectedBody: {
              'androidPackageName': 'com.example.app',
              'sha1Cert': 'SHA_1_ANDROID_CERT'
            },
          );

          test('isAndroidPackageNameValid: sha1Cert: success', () async {
            await tester.shouldSucceed(
              serverResponse: {
                'projectId': '12345678',
                'authorizedDomains': ['domain.com', 'www.mydomain.com']
              },
            );
          });
          test('isAndroidPackageNameValid: sha1Cert: error', () async {
            await tester.shouldFail(
              serverResponse: Tester.errorResponse('INVALID_CERT_HASH'),
              expectedError: AuthException.invalidCertHash(),
            );
          });
        });
      });

      group('isOAuthCliendIdValid', () {
        var tester = Tester(
          path: 'getProjectConfig',
          expectedBody: {'clientId': '123456.apps.googleusercontent.com'},
          action: () => rpcHandler
              .isOAuthClientIdValid('123456.apps.googleusercontent.com'),
          expectedResult: (r) => null,
          method: 'GET',
        );

        test('isOAuthCliendIdValid: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'projectId': '12345678',
              'authorizedDomains': ['domain.com', 'www.mydomain.com']
            },
          );
        });
        test('isOAuthCliendIdValid: error', () async {
          await tester.shouldFail(
            serverResponse: Tester.errorResponse('INVALID_OAUTH_CLIENT_ID'),
            expectedError: AuthException.invalidOAuthClientId(),
          );
        });
      });

      group('fetchSignInMethodsForIdentifier', () {
        var identifier = 'user@example.com';
        var tester = Tester(
          path: 'createAuthUri',
          expectedBody: () =>
              {'identifier': identifier, 'continueUri': platform.currentUrl},
          action: () => rpcHandler.fetchSignInMethodsForIdentifier(identifier),
          expectedResult: (r) => r['signinMethods'] ?? [],
        );

        test('fetchSignInMethodsForIdentifier: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'kind': 'identitytoolkit#CreateAuthUriResponse',
              'allProviders': ['google.com', 'password'],
              'signinMethods': ['google.com', 'emailLink'],
              'registered': true,
              'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
            },
          );
        });

        test('fetchSignInMethodsForIdentifier: tenantId', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
              serverResponse: {
                'kind': 'identitytoolkit#CreateAuthUriResponse',
                'allProviders': ['google.com', 'password'],
                'signinMethods': ['google.com', 'emailLink'],
                'registered': true,
                'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
              },
              expectedBody: () => {
                    'identifier': identifier,
                    'continueUri': platform.currentUrl,
                    'tenantId': '123456789012'
                  });
        });

        test('fetchSignInMethodsForIdentifier: no signin methods returned',
            () async {
          await tester.shouldSucceed(
            serverResponse: {
              'kind': 'identitytoolkit#CreateAuthUriResponse',
              'registered': true,
              'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
            },
          );
        });
        test('fetchSignInMethodsForIdentifier: non http or https', () async {
          // Simulate non http or https current URL.
          platform =
              Platform(currentUrl: 'chrome-extension://234567890/index.html');
          await tester.shouldSucceed(
            expectedBody: {
              'identifier': identifier,
              // A fallback HTTP URL should be used.
              'continueUri': 'http://localhost'
            },
            serverResponse: {
              'kind': 'identitytoolkit#CreateAuthUriResponse',
              'allProviders': ['google.com', 'password'],
              'signinMethods': ['google.com', 'emailLink'],
              'registered': true,
              'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
            },
          );
        });

        test('fetchSignInMethodsForIdentifier: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_IDENTIFIER': AuthException.invalidEmail(),
            'MISSING_CONTINUE_URI': AuthException.internalError(),
          });
        });
      });

      group('fetchProvidersForIdentifier', () {
        var identifier = 'MY_ID';
        var tester = Tester(
          path: 'createAuthUri',
          expectedBody: () =>
              {'identifier': identifier, 'continueUri': platform.currentUrl},
          action: () => rpcHandler.fetchProvidersForIdentifier(identifier),
          expectedResult: (r) => r['allProviders'] ?? [],
        );

        test('fetchProvidersForIdentifier: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'kind': 'identitytoolkit#CreateAuthUriResponse',
              'authUri': 'https://accounts.google.com/o/oauth2/auth?foo=bar',
              'providerId': 'google.com',
              'allProviders': ['google.com', 'myauthprovider.com'],
              'registered': true,
              'forExistingProvider': true,
              'sessionId': 'MY_SESSION_ID'
            },
          );
        });

        test('fetchProvidersForIdentifier: tenantId', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
              serverResponse: {
                'kind': 'identitytoolkit#CreateAuthUriResponse',
                'authUri': 'https://accounts.google.com/o/oauth2/auth?foo=bar',
                'providerId': 'google.com',
                'allProviders': ['google.com', 'myauthprovider.com'],
                'registered': true,
                'forExistingProvider': true,
                'sessionId': 'MY_SESSION_ID'
              },
              expectedBody: () => {
                    'identifier': identifier,
                    'continueUri': platform.currentUrl,
                    'tenantId': '123456789012'
                  });
        });

        test('fetchProvidersForIdentifier: non http or https', () async {
          // Simulate non http or https current URL.
          platform =
              Platform(currentUrl: 'chrome-extension://234567890/index.html');
          await tester.shouldSucceed(
            expectedBody: {
              'identifier': identifier,
              // A fallback HTTP URL should be used.
              'continueUri': 'http://localhost'
            },
            serverResponse: {
              'kind': 'identitytoolkit#CreateAuthUriResponse',
              'authUri': 'https://accounts.google.com/o/oauth2/auth?foo=bar',
              'providerId': 'google.com',
              'allProviders': ['google.com', 'myauthprovider.com'],
              'registered': true,
              'forExistingProvider': true,
              'sessionId': 'MY_SESSION_ID'
            },
          );
        });

        test('fetchProvidersForIdentifier: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_IDENTIFIER': AuthException.invalidEmail(),
            'MISSING_CONTINUE_URI': AuthException.internalError(),
          });
        });
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
      group('verifyCustomToken', () {
        var tester = Tester(
          path: 'verifyCustomToken',
          expectedBody: {'token': 'CUSTOM_TOKEN', 'returnSecureToken': true},
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .verifyCustomToken('CUSTOM_TOKEN')
              .then((v) => {'id_token': v.response['id_token']}),
        );

        test('verifyCustomToken: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'my_id')},
          );
        });

        test('verifyCustomToken: multi factor required', () async {
          await tester.shouldFail(
            expectedError: AuthException.mfaRequired(),
            serverResponse: pendingCredResponse,
          );
        });

        test('verifyCustomToken: tenant id', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
            expectedBody: {
              'token': 'CUSTOM_TOKEN',
              'returnSecureToken': true,
              'tenantId': '123456789012'
            },
            serverResponse: {'idToken': createMockJwt(uid: 'my_id')},
          );
        });

        test('verifyCustomToken: unsupported tenant operation', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldFailWithServerErrors(expectedBody: {
            'token': 'CUSTOM_TOKEN',
            'returnSecureToken': true,
            'tenantId': '123456789012'
          }, errorMap: {
            'UNSUPPORTED_TENANT_OPERATION':
                AuthException.unsupportedTenantOperation(),
          });
        });

        test('verifyCustomToken: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'MISSING_CUSTOM_TOKEN': AuthException.internalError(),
            'INVALID_CUSTOM_TOKEN': AuthException.invalidCustomToken(),
            'CREDENTIAL_MISMATCH': AuthException.credentialMismatch(),
            'INVALID_TENANT_ID': AuthException.invalidTenantId(),
            'TENANT_ID_MISMATCH': AuthException.tenantIdMismatch(),
          });
        });

        test('verifyCustomToken: unknown server response', () async {
          await tester.shouldFail(
              expectedBody: {
                'token': 'CUSTOM_TOKEN',
                'returnSecureToken': true
              },
              serverResponse: {},
              expectedError: AuthException.internalError(),
              action: () => rpcHandler.verifyCustomToken('CUSTOM_TOKEN'));
        });
      });

      group('emailLinkSignIn', () {
        var tester = Tester(
            path: 'emailLinkSignin',
            expectedBody: {
              'email': 'user@example.com',
              'oobCode': 'OTP_CODE',
              'returnSecureToken': true
            },
            expectedResult: (response) {
              return {'id_token': response['idToken']};
            },
            action: () => rpcHandler
                .emailLinkSignIn('user@example.com', 'OTP_CODE')
                .then((v) => {'id_token': v.response['id_token']}));
        test('emailLinkSignIn: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('emailLinkSignIn: multi factor required', () async {
          await tester.shouldFail(
            expectedError: AuthException.mfaRequired(),
            serverResponse: pendingCredResponse,
          );
        });

        test('emailLinkSignIn: tenant id', () async {
          rpcHandler.tenantId = 'TENANT_ID';
          await tester.shouldSucceed(
            expectedBody: {
              'email': 'user@example.com',
              'oobCode': 'OTP_CODE',
              'returnSecureToken': true,
              'tenantId': 'TENANT_ID'
            },
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('emailLinkSignIn: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_EMAIL': AuthException.invalidEmail(),
          });
        });

        test('emailLinkSignIn: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: AuthException.internalError(),
          );
        });

        test('emailLinkSignIn: empty action code error', () async {
          // Test when empty action code is passed in emailLinkSignIn request.
          expect(() => rpcHandler.emailLinkSignIn('user@example.com', ''),
              throwsA(AuthException.internalError()));
        });
        test('emailLinkSignIn: invalid email error', () async {
          // Test when invalid email is passed in emailLinkSignIn request.
          expect(() => rpcHandler.emailLinkSignIn('user.invalid', 'OTP_CODE'),
              throwsA(AuthException.invalidEmail()));
        });
      });

      group('createAccount', () {
        var tester = Tester(
          path: 'signupNewUser',
          expectedBody: {
            'email': 'uid123@fake.com',
            'password': 'mysupersecretpassword',
            'returnSecureToken': true
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .createAccount('uid123@fake.com', 'mysupersecretpassword')
              .then((v) => {'id_token': v.response['id_token']}),
        );
        test('createAccount: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });
        test('createAccount: tenant id', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true,
              'tenantId': '123456789012'
            },
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('createAccount: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EMAIL_EXISTS': AuthException.emailExists(),
              'PASSWORD_LOGIN_DISABLED': AuthException.operationNotAllowed(),
              'OPERATION_NOT_ALLOWED': AuthException.operationNotAllowed(),
              'WEAK_PASSWORD': AuthException.weakPassword(),
              'ADMIN_ONLY_OPERATION': AuthException.adminOnlyOperation(),
              'INVALID_TENANT_ID': AuthException.invalidTenantId(),
            },
          );
        });
        test('createAccount: unknown server response', () async {
          // Test when server returns unexpected response with no error message.
          await tester.shouldFail(
            serverResponse: {},
            expectedError: AuthException.internalError(),
          );
        });

        test('createAccount: no password error', () async {
          expect(() => rpcHandler.createAccount('uid123@fake.com', ''),
              throwsA(AuthException.weakPassword()));
        });
        test('createAccount: invalid email error', () async {
          expect(
              () => rpcHandler.createAccount(
                  'uid123.invalid', 'mysupersecretpassword'),
              throwsA(AuthException.invalidEmail()));
        });
      });

      group('deleteAccount', () {
        var tester = Tester(
            path: 'deleteAccount',
            expectedBody: {'idToken': 'ID_TOKEN'},
            action: () => rpcHandler.deleteAccount('ID_TOKEN'),
            expectedResult: (_) => null);
        test('deleteAccount: success', () async {
          await tester.shouldSucceed(
            serverResponse: {},
          );
        });

        test('deleteAccount: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'CREDENTIAL_TOO_OLD_LOGIN_AGAIN':
                  AuthException.credentialTooOldLoginAgain(),
              'INVALID_ID_TOKEN': AuthException.invalidAuth(),
              'USER_NOT_FOUND': AuthException.tokenExpired(),
              'TOKEN_EXPIRED': AuthException.tokenExpired(),
              'USER_DISABLED': AuthException.userDisabled(),
              'ADMIN_ONLY_OPERATION': AuthException.adminOnlyOperation(),
            },
          );
        });

        test('deleteAccount: invalid request error', () async {
          expect(() => rpcHandler.deleteAccount(null),
              throwsA(AuthException.internalError()));
        });
      });

      group('verifyPassword', () {
        var tester = Tester(
            path: 'verifyPassword',
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true
            },
            expectedResult: (response) {
              return {'id_token': response['idToken']};
            },
            action: () => rpcHandler
                .verifyPassword('uid123@fake.com', 'mysupersecretpassword')
                .then((v) => {'id_token': v.response['id_token']}));
        test('verifyPassword: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': createMockJwt(uid: 'uid123', providerId: 'password')
            },
          );
        });

        test('verifyPassword: multi factor required', () async {
          await tester.shouldFail(
            expectedError: AuthException.mfaRequired(),
            serverResponse: pendingCredResponse,
          );
        });

        test('verifyPassword: tenant id', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true,
              'tenantId': '123456789012'
            },
            serverResponse: {
              'idToken': createMockJwt(uid: 'uid123', providerId: 'password')
            },
          );
        });

        test('verifyPassword: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_EMAIL': AuthException.invalidEmail(),
              'INVALID_PASSWORD': AuthException.invalidPassword(),
              'TOO_MANY_ATTEMPTS_TRY_LATER':
                  AuthException.tooManyAttemptsTryLater(),
              'USER_DISABLED': AuthException.userDisabled(),
              'INVALID_TENANT_ID': AuthException.invalidTenantId(),
            },
          );
        });

        test('verifyPassword: unknown server response', () async {
          await tester.shouldFail(
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true
            },
            serverResponse: {},
            expectedError: AuthException.internalError(),
            action: () => rpcHandler.verifyPassword(
                'uid123@fake.com', 'mysupersecretpassword'),
          );
        });

        test('verifyPassword: invalid password request', () async {
          expect(() => rpcHandler.verifyPassword('uid123@fake.com', ''),
              throwsA(AuthException.invalidPassword()));
        });

        test('verifyPassword: invalid email error', () async {
          // Test when invalid email is passed in verifyPassword request.
          // Test when request is invalid.
          expect(
              () => rpcHandler.verifyPassword(
                  'uid123.invalid', 'mysupersecretpassword'),
              throwsA(AuthException.invalidEmail()));
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
            expectedBody: {
              'returnSecureToken': true,
              'tenantId': '123456789012'
            },
            serverResponse: {
              'idToken': createMockJwt(
                  uid: generateRandomString(24), providerId: 'anonymous')
            },
          );
        });
        test('signInAnonymously: unsupported tenant operation', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldFailWithServerErrors(
            expectedBody: {
              'returnSecureToken': true,
              'tenantId': '123456789012'
            },
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
      group('verifyAssertion', () {
        var tester = Tester(
          path: 'verifyAssertion',
          expectedBody: {
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            'returnSecureToken': true
          },
          action: () => rpcHandler.verifyAssertion(
              sessionId: 'SESSION_ID',
              requestUri: 'http://localhost/callback#oauthResponse'),
        );
        test('verifyAssertion: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': 'ID_TOKEN',
              'oauthAccessToken': 'ACCESS_TOKEN',
              'oauthExpireIn': 3600,
              'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
            },
          );
        });
        test('verifyAssertion: with session id nonce: success', () async {
          await tester.shouldSucceed(
            expectedBody: {
              'sessionId': 'NONCE',
              'requestUri':
                  'http://localhost/callback#id_token=ID_TOKEN&state=STATE',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': 'ID_TOKEN',
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider'
            },
            expectedResult: (_) => {
              'idToken': 'ID_TOKEN',
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider',
              'nonce': 'NONCE'
            },
            action: () => rpcHandler.verifyAssertion(
                sessionId: 'NONCE',
                requestUri:
                    'http://localhost/callback#id_token=ID_TOKEN&state=STATE'),
          );
        });
        test('verifyAssertion: with post body nonce: success', () async {
          await tester.shouldSucceed(
            expectedBody: {
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': 'ID_TOKEN',
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider',
            },
            expectedResult: (_) => {
              'idToken': 'ID_TOKEN',
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider',
              'nonce': 'NONCE'
            },
            action: () => rpcHandler.verifyAssertion(
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
        });
        test('verifyAssertion: pending token response: success', () async {
          // Nonce should not be injected since pending token is present in response.
          await tester.shouldSucceed(
            expectedBody: {
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': 'ID_TOKEN',
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'pendingToken': 'PENDING_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider'
            },
            action: () => rpcHandler.verifyAssertion(
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
        });
        group('verifyAssertion: pending token request', () {
          test('verifyAssertion: pending token request: success', () async {
            await tester.shouldSucceed(
              expectedBody: {
                'pendingIdToken': 'PENDING_TOKEN',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN2',
                'oauthExpireIn': 3600,
              },
              action: () => rpcHandler.verifyAssertion(
                  pendingIdToken: 'PENDING_TOKEN',
                  requestUri: 'http://localhost'),
            );
          });

          test('verifyAssertion: pending token request: server caught error',
              () async {
            await tester.shouldFailWithServerErrors(
              expectedBody: {
                'pendingIdToken': 'PENDING_TOKEN',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              action: () => rpcHandler.verifyAssertion(
                pendingIdToken: 'PENDING_TOKEN',
                requestUri: 'http://localhost',
              ),
              errorMap: {
                'INVALID_IDP_RESPONSE': AuthException.invalidIdpResponse(),
                'INVALID_PENDING_TOKEN': AuthException.invalidIdpResponse(),
              },
            );
          });
        });
        group('verifyAssertion: return idp credential', () {
          test('verifyAssertion: return idp credential: no recovery error',
              () async {
            // Simulate server response containing unrecoverable errorMessage.
            await tester.shouldFail(
              expectedBody: {
                'sessionId': 'SESSION_ID',
                'requestUri': 'http://localhost/callback#oauthResponse',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'federatedId': 'FEDERATED_ID',
                'providerId': 'google.com',
                'email': 'user@example.com',
                'emailVerified': true,
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE',
                'errorMessage': 'USER_DISABLED'
              },
              expectedError: AuthException.userDisabled(),
              action: () => rpcHandler.verifyAssertion(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse'),
            );
          });
        });
        test('verifyAssertion: error', () async {
          expect(
              () => rpcHandler.verifyAssertion(
                  requestUri: 'http://localhost/callback#oauthResponse'),
              throwsA(AuthException.internalError()));
        });
        test('verifyAssertion: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            expectedBody: {
              'postBody':
                  'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=invalid',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertion(
              postBody:
                  'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=invalid',
              requestUri: 'http://localhost',
            ),
            errorMap: {
              'INVALID_IDP_RESPONSE': AuthException.invalidIdpResponse(),
              'USER_DISABLED': AuthException.userDisabled(),
              'FEDERATED_USER_ID_ALREADY_LINKED':
                  AuthException.credentialAlreadyInUse(),
              'OPERATION_NOT_ALLOWED': AuthException.operationNotAllowed(),
              'USER_CANCELLED': AuthException.userCancelled(),
              'MISSING_OR_INVALID_NONCE': AuthException.missingOrInvalidNonce()
            },
          );
        });
        test('verifyAssertion: invalid request error', () async {
          // Test when request is invalid.
          expect(() => rpcHandler.verifyAssertion(postBody: '....'),
              throwsA(AuthException.internalError()));
        });

        group('verifyAssertion: need confirmation error', () {
          test(
              'verifyAssertion: need confirmation error: oauth response and email',
              () {
            // Test Auth linking error when need confirmation flag is returned.
            var credential = GoogleAuthProvider.getCredential(
                accessToken: 'googleAccessToken');

            tester.shouldFail(
              expectedBody: {
                'postBody':
                    'id_token=googleIdToken&access_token=accessToken&provide'
                        'r_id=google.com',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'needConfirmation': true,
                'idToken': 'PENDING_TOKEN',
                'email': 'user@example.com',
                'oauthAccessToken': 'googleAccessToken',
                'providerId': 'google.com'
              },
              expectedError: AuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody:
                      'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                  requestUri: 'http://localhost'),
            );
          });
          test('verifyAssertion: need confirmation error: nonce id token',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');

            await tester.shouldFail(
              expectedBody: {
                'postBody':
                    'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'needConfirmation': true,
                'email': 'user@example.com',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: AuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });

          test('verifyAssertion: need confirmation error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');

            await tester.shouldFail(
              expectedBody: {
                'postBody': 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                'sessionId': 'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'needConfirmation': true,
                'email': 'user@example.com',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: AuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test('verifyAssertion: need confirmation error: pending token',
              () async {
            // Expected error thrown with OIDC credential containing pending token and
            // no nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(
                    idToken: 'OIDC_ID_TOKEN', pendingToken: 'PENDING_TOKEN');

            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'needConfirmation': true,
                  'email': 'user@example.com',
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'providerId': 'oidc.provider',
                  'pendingToken': 'PENDING_TOKEN'
                },
                expectedError: AuthException.needConfirmation()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });

          test('verifyAssertion: need confirmation error: pending token',
              () async {
            // Test Auth linking error when need confirmation flag is returned.

            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=googleIdToken&access_token=accessToken&provide'
                          'r_id=google.com',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'needConfirmation': true,
                  'idToken': 'PENDING_TOKEN',
                  'email': 'user@example.com'
                },
                expectedError: AuthException.needConfirmation()
                    .replace(email: 'user@example.com'),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id'
                        '=google.com',
                    requestUri: 'http://localhost'));
          });

          test('verifyAssertion: need confirmation error: no extra info',
              () async {
            // Test Auth error when need confirmation flag is returned but OAuth response
            // missing.
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=googleIdToken&access_token=accessToken&provide'
                          'r_id=google.com',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'needConfirmation': true
                },
                expectedError: AuthException.needConfirmation(),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                    requestUri: 'http://localhost'));
          });
        });

        group('verifyAssertion: credentials already in use error', () {
          test(
              'verifyAssertion: credentials already in use error: oauth response and email',
              () async {
            // Test Auth linking error when FEDERATED_USER_ID_ALREADY_LINKED errorMessage
            // is returned.
            var credential = GoogleAuthProvider.getCredential(
                accessToken: 'googleAccessToken');
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=googleIdToken&access_token=accessToken&provide'
                          'r_id=google.com',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'kind': 'identitytoolkit#VerifyAssertionResponse',
                  'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                  'email': 'user@example.com',
                  'oauthAccessToken': 'googleAccessToken',
                  'oauthExpireIn': 5183999,
                  'providerId': 'google.com'
                },
                expectedError: AuthException.credentialAlreadyInUse()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                    requestUri: 'http://localhost'));
          });
          test(
              'verifyAssertion: credentials already in use error: nonce id token',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'kind': 'identitytoolkit#VerifyAssertionResponse',
                  'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                  'email': 'user@example.com',
                  'oauthExpireIn': 5183999,
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'providerId': 'oidc.provider'
                },
                expectedError: AuthException.credentialAlreadyInUse()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });
          test(
              'verifyAssertion: credentials already in use error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                'sessionId': 'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'kind': 'identitytoolkit#VerifyAssertionResponse',
                'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: AuthException.credentialAlreadyInUse()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test(
              'verifyAssertion: credentials already in use error: pending token',
              () async {
            // Expected error thrown with OIDC credential containing pending token and no
            // nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(
                    pendingToken: 'PENDING_TOKEN', idToken: 'OIDC_ID_TOKEN');
            await tester.shouldFail(
              expectedBody: {
                'postBody':
                    'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'kind': 'identitytoolkit#VerifyAssertionResponse',
                'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider',
                'pendingToken': 'PENDING_TOKEN'
              },
              expectedError: AuthException.credentialAlreadyInUse()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });
        });

        group('verifyAssertion: email exists error', () {
          test('verifyAssertion: email exists error: oauth response and email',
              () async {
            // Test Auth linking error when EMAIL_EXISTS errorMessage is returned.
            var credential = FacebookAuthProvider.getCredential(
                accessToken: 'facebookAccessToken');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'access_token=accessToken&provider_id=facebook.com',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'kind': 'identitytoolkit#VerifyAssertionResponse',
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthAccessToken': 'facebookAccessToken',
                'oauthExpireIn': 5183999,
                'providerId': 'facebook.com'
              },
              expectedError: AuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody: 'access_token=accessToken&provider_id=facebook.com',
                  requestUri: 'http://localhost'),
            );
          });
          test('verifyAssertion: email exists error: nonce id token', () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'kind': 'identitytoolkit#VerifyAssertionResponse',
                  'errorMessage': 'EMAIL_EXISTS',
                  'email': 'user@example.com',
                  'oauthExpireIn': 5183999,
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'providerId': 'oidc.provider'
                },
                expectedError: AuthException.emailExists()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.verifyAssertion(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });
          test('verifyAssertion: email exists error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(idToken: 'OIDC_ID_TOKEN', rawNonce: 'NONCE');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                'sessionId': 'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'kind': 'identitytoolkit#VerifyAssertionResponse',
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: AuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test('verifyAssertion: email exists error: pending token', () async {
            // Expected error thrown with OIDC credential containing no nonce since
            // pending token returned from server.
            var credential = OAuthProvider(providerId: 'oidc.provider')
                .getCredential(
                    pendingToken: 'PENDING_TOKEN', idToken: 'OIDC_ID_TOKEN');
            await tester.shouldFail(
              expectedBody: {
                'postBody':
                    'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce='
                        'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'kind': 'identitytoolkit#VerifyAssertionResponse',
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider',
                'pendingToken': 'PENDING_TOKEN'
              },
              expectedError: AuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.verifyAssertion(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });
        });
      });

      group('verifyAssertionForLinking', () {
        var tester = Tester(
          path: 'verifyAssertion',
          expectedBody: {
            'idToken': 'existingIdToken',
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            'returnSecureToken': true
          },
          action: () => rpcHandler.verifyAssertionForLinking(
              idToken: 'existingIdToken',
              sessionId: 'SESSION_ID',
              requestUri: 'http://localhost/callback#oauthResponse'),
        );
        test('verifyAssertionForLinking: success', () async {
          await tester.shouldSucceed(serverResponse: {
            'idToken': 'ID_TOKEN',
            'oauthAccessToken': 'ACCESS_TOKEN',
            'oauthExpireIn': 3600,
            'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
          });
        });

        group('verifyAssertionForLinking: withSessionIdNonce', () {
          var t = tester.replace(
              expectedBody: {
                'idToken': 'existingIdToken',
                'sessionId': 'NONCE',
                'requestUri':
                    'http://localhost/callback#id_token=ID_TOKEN&state=STATE',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              action: () => rpcHandler.verifyAssertionForLinking(
                  idToken: 'existingIdToken',
                  sessionId: 'NONCE',
                  requestUri:
                      'http://localhost/callback#id_token=ID_TOKEN&state=STATE'));
          test('verifyAssertionForLinking: withSessionIdNonce: success',
              () async {
            await t.shouldSucceed(
                serverResponse: {
                  'idToken': 'ID_TOKEN',
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'oauthExpireIn': 3600,
                  'providerId': 'oidc.provider'
                },
                expectedResult: (_) => {
                      'idToken': 'ID_TOKEN',
                      'oauthIdToken': 'OIDC_ID_TOKEN',
                      'oauthExpireIn': 3600,
                      'providerId': 'oidc.provider',
                      'nonce': 'NONCE'
                    });
          });
        });

        group('verifyAssertionForLinking: with post body nonce', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForLinking(
                idToken: 'existingIdToken',
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('verifyAssertionForLinking: with post body nonce: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
              },
              expectedResult: (_) => {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
                'nonce': 'NONCE'
              },
            );
          });
        });

        group('verifyAssertionForLinking: pending token response', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForLinking(
                idToken: 'existingIdToken',
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('verifyAssertionForLinking: pending token response: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider'
              },
            );
          });
        });
        group('verifyAssertionForLinking: pending token request', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'pendingIdToken': 'PENDING_TOKEN',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForLinking(
                idToken: 'existingIdToken',
                pendingToken: 'PENDING_TOKEN',
                requestUri: 'http://localhost'),
          );
          test('verifyAssertionForLinking: pending token request: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN2',
                'oauthExpireIn': 3600
              },
            );
          });
        });
        group('verifyAssertionForLinking: return idp credential', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'ID_TOKEN',
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForLinking(
                idToken: 'ID_TOKEN',
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test(
              'verifyAssertionForLinking: return idp credential: no recovery error',
              () async {
            await t.shouldFail(
              serverResponse: {
                'federatedId': 'FEDERATED_ID',
                'providerId': 'google.com',
                'email': 'user@example.com',
                'emailVerified': true,
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE',
                'errorMessage': 'USER_DISABLED'
              },
              expectedError: AuthException.userDisabled(),
            );
          });
        });

        test('verifyAssertionForLinking: error', () async {
          expect(
              () => rpcHandler.verifyAssertionForLinking(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse'),
              throwsA(AuthException.internalError()));
        });
      });

      group('verifyAssertionForExisting', () {
        var tester = Tester(
          path: 'verifyAssertion',
          expectedBody: {
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            // autoCreate flag should be passed and set to false.
            'autoCreate': false,
            'returnSecureToken': true
          },
          action: () => rpcHandler.verifyAssertionForExisting(
              sessionId: 'SESSION_ID',
              requestUri: 'http://localhost/callback#oauthResponse'),
        );
        test('verifyAssertionForExisting: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': 'ID_TOKEN',
              'oauthAccessToken': 'ACCESS_TOKEN',
              'oauthExpireIn': 3600,
              'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
            },
          );
        });

        group('verifyAssertionForExisting: with session id nonce', () {
          var t = tester.replace(
            expectedBody: {
              'sessionId': 'NONCE',
              'requestUri':
                  'http://localhost/callback#id_token=ID_TOKEN&state=STATE',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                sessionId: 'NONCE',
                requestUri:
                    'http://localhost/callback#id_token=ID_TOKEN&state=STATE'),
          );
          test('verifyAssertionForExisting: with session id nonce: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider'
              },
              expectedResult: (_) => {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
                'nonce': 'NONCE'
              },
            );
          });
        });
        group('verifyAssertionForExisting: with post body nonce', () {
          var t = tester.replace(
            expectedBody: {
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('verifyAssertionForExisting: with post body nonce: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
              },
              expectedResult: (_) => {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
                'nonce': 'NONCE'
              },
            );
          });
        });
        group('verifyAssertionForExisting: pending token response', () {
          var t = tester.replace(
            expectedBody: {
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('verifyAssertionForExisting: pending token response: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider'
              },
            );
          });
        });
        group('verifyAssertionForExisting: pending token request', () {
          var t = tester.replace(
            expectedBody: {
              'pendingIdToken': 'PENDING_TOKEN',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                pendingToken: 'PENDING_TOKEN', requestUri: 'http://localhost'),
          );
          test('verifyAssertionForExisting: pending token request: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': 'ID_TOKEN',
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN2',
                'oauthExpireIn': 3600
              },
            );
          });
        });
        group('verifyAssertionForExisting: return idp credential', () {
          var t = tester.replace(
            expectedBody: {
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test(
              'verifyAssertionForExisting: return idp credential: no recovery error',
              () async {
            await t.shouldFail(
              serverResponse: {
                'federatedId': 'FEDERATED_ID',
                'providerId': 'google.com',
                'email': 'user@example.com',
                'emailVerified': true,
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE',
                'errorMessage': 'USER_DISABLED'
              },
              expectedError: AuthException.userDisabled(),
            );
          });
        });

        group('verifyAssertionForExisting: error', () {
          var t = tester.replace(
            expectedBody: {
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.verifyAssertionForExisting(
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test('verifyAssertionForExisting: error', () async {
            // Same client side validation as verifyAssertion.
            expect(
                () => rpcHandler.verifyAssertionForExisting(
                    requestUri: 'http://localhost/callback#oauthResponse'),
                throwsA(AuthException.internalError()));
          });
          test('verifyAssertionForExisting: error: user not found', () async {
            // No user is found. No idToken returned.
            await t.shouldFail(
              serverResponse: {
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE',
                'errorMessage': 'USER_NOT_FOUND'
              },
              expectedError: AuthException.userDeleted(),
            );
          });
          test('verifyAssertionForExisting: error: no idToken', () async {
            // No idToken returned for whatever reason.
            await t.shouldFail(
              serverResponse: {
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
              },
              expectedError: AuthException.internalError(),
            );
          });
        });
        test('verifyAssertionForExisting: invalid request error', () async {
          // Test when request is invalid.
          expect(() => rpcHandler.verifyAssertionForExisting(postBody: '....'),
              throwsA(AuthException.internalError()));
        });
        test('verifyAssertionForExisting: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_IDP_RESPONSE': AuthException.invalidIdpResponse(),
            'USER_DISABLED': AuthException.userDisabled(),
            'OPERATION_NOT_ALLOWED': AuthException.operationNotAllowed(),
            'USER_CANCELLED': AuthException.userCancelled(),
          });
        });
      });

      group('sendSignInLinkToEmail', () {
        var userEmail = 'user@example.com';
        var additionalRequestData = {
          'continueUrl': 'https://www.example.com/?state=abc',
          'iOSBundleId': 'com.example.ios',
          'androidPackageName': 'com.example.android',
          'androidInstallApp': true,
          'androidMinimumVersion': '12',
          'canHandleCodeInApp': true,
          'dynamicLinkDomain': 'example.page.link'
        };
        var tester = Tester(
          path: 'getOobConfirmationCode',
          expectedBody: {
            'requestType': 'EMAIL_SIGNIN',
            'email': userEmail,
            'continueUrl': 'https://www.example.com/?state=abc',
            'iOSBundleId': 'com.example.ios',
            'androidPackageName': 'com.example.android',
            'androidInstallApp': true,
            'androidMinimumVersion': '12',
            'canHandleCodeInApp': true,
            'dynamicLinkDomain': 'example.page.link'
          },
          action: () => rpcHandler.sendSignInLinkToEmail(
              email: 'user@example.com',
              continueUrl: 'https://www.example.com/?state=abc',
              iOSBundleId: 'com.example.ios',
              androidPackageName: 'com.example.android',
              androidInstallApp: true,
              androidMinimumVersion: '12',
              canHandleCodeInApp: true,
              dynamicLinkDomain: 'example.page.link'),
        );
        group('sendSignInLinkToEmail: success', () {
          test('sendSignInLinkToEmail: success: action code settings',
              () async {
            await tester.shouldSucceed(
              serverResponse: {'email': userEmail},
              expectedResult: (_) => userEmail,
            );
          });
          test('sendSignInLinkToEmail: success: custom locale', () async {
            rpcHandler.updateCustomLocaleHeader('es');
            await tester.shouldSucceed(
              serverResponse: {'email': userEmail},
              expectedHeaders: {
                'Content-Type': 'application/json',
                'X-Firebase-Locale': 'es'
              },
              expectedResult: (_) => userEmail,
            );
          });
        });
        test('sendSignInLinkToEmail: invalid email error', () async {
          // Test when invalid email is passed in getOobCode request.

          expect(() => rpcHandler.sendSignInLinkToEmail(email: 'user.invalid'),
              throwsA(AuthException.invalidEmail()));
        });
        test('sendSignInLinkToEmail: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: AuthException.internalError(),
          );
        });
        test('sendSignInLinkToEmail: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_RECIPIENT_EMAIL': AuthException.invalidRecipientEmail(),
              'INVALID_SENDER': AuthException.invalidSender(),
              'INVALID_MESSAGE_PAYLOAD': AuthException.invalidMessagePayload(),
              'INVALID_CONTINUE_URI': AuthException.invalidContinueUri(),
              'MISSING_ANDROID_PACKAGE_NAME':
                  AuthException.missingAndroidPackageName(),
              'MISSING_IOS_BUNDLE_ID': AuthException.missingIosBundleId(),
              'UNAUTHORIZED_DOMAIN': AuthException.unauthorizedDomain(),
              'INVALID_DYNAMIC_LINK_DOMAIN':
                  AuthException.invalidDynamicLinkDomain(),
            },
          );
        });
      });
    });
  });
}
