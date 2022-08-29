import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/src/auth/rpc/http_util.dart';
import 'package:firebase_dart/src/auth/rpc/rpc_handler.dart';
import 'package:firebase_dart/src/auth/utils.dart';
import 'package:test/test.dart';

import 'jwt_util.dart';
import 'util.dart';

class Tester {
  static const identityToolkitBaseUrl =
      'https://identitytoolkit.googleapis.com/v1';

  final String url;
  final dynamic expectedBody;
  final String method;
  final Future Function()? action;
  final dynamic Function(Map<String, dynamic>)? expectedResult;

  Tester(
      {String? path,
      this.expectedBody,
      this.method = 'POST',
      this.action,
      this.expectedResult})
      : url = '$identityToolkitBaseUrl/$path';

  Tester replace(
          {String? path,
          dynamic expectedBody,
          String? method,
          Future Function()? action,
          dynamic Function(Map<String, dynamic>)? expectedResult}) =>
      Tester(
          path: path ?? Uri.parse(url).pathSegments.last,
          expectedBody: expectedBody ?? this.expectedBody,
          method: method ?? this.method,
          action: action ?? this.action,
          expectedResult: expectedResult ?? this.expectedResult);

  Future<void> shouldSucceed(
      {String? url,
      dynamic expectedBody,
      required FutureOr<Map<String, dynamic>> serverResponse,
      Map<String, String>? expectedHeaders,
      Future Function()? action,
      dynamic Function(Map<String, dynamic>)? expectedResult,
      String? method}) async {
    when(method ?? this.method, url ?? this.url)
      ..expectBody(expectedBody ?? this.expectedBody)
      ..expectHeaders(expectedHeaders)
      ..thenReturn(serverResponse);
    var response = await serverResponse;
    expectedResult ??= this.expectedResult ?? (r) async => r;
    var v = await (action ?? this.action)!();
    expect(json.decode(json.encode(v)), await expectedResult(response));
  }

  Future<void> shouldFail(
      {String? url,
      dynamic expectedBody,
      required FutureOr<Map<String, dynamic>> serverResponse,
      required FirebaseAuthException expectedError,
      Future Function()? action,
      String? method}) async {
    when(method ?? this.method, url ?? this.url)
      ..expectBody(expectedBody ?? this.expectedBody)
      ..thenReturn(serverResponse);
    expect(action ?? this.action, throwsA(expectedError));
  }

  Future<void> shouldFailWithServerErrors(
      {String? url,
      String? method,
      Map<String, dynamic>? expectedBody,
      Future Function()? action,
      required Map<String, FirebaseAuthException> errorMap}) async {
    for (var serverErrorCode in errorMap.keys) {
      var expectedError = errorMap[serverErrorCode];

      when(method ?? this.method, url ?? this.url)
        ..expectBody(expectedBody ?? this.expectedBody)
        ..thenReturn(Tester.errorResponse(serverErrorCode));

      var e = await (action ?? this.action)!()
          .then<dynamic>((v) => v)
          .catchError((e) => e);
      expect(e, expectedError);
    }
  }

  static Map<String, dynamic> errorResponse(String message,
          {Map<String, dynamic>? extras}) =>
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
    var httpClient = MetadataClient(mockHttpClient, firebaseAppId: 'app-id');
    var rpcHandler = RpcHandler('apiKey', httpClient: httpClient);

    var pendingCredResponse = {
      'mfaInfo': [
        {
          'mfaEnrollmentId': 'ENROLLMENT_UID1',
          'enrolledAt': clock.now().toIso8601String(),
          'phoneInfo': '+16505551234'
        }
      ],
      'mfaPendingCredential': 'PENDING_CREDENTIAL'
    };

    WebPlatform platform;

    initPlatform(platform = Platform.web(
        currentUrl: 'http://localhost',
        isMobile: false,
        isOnline: true) as WebPlatform);
    setUp(() {
      rpcHandler.tenantId = null;

      httpClient.locale = null;

      initPlatform(platform = Platform.web(
          currentUrl: 'http://localhost',
          isMobile: false,
          isOnline: true) as WebPlatform);
    });

    group('identitytoolkit', () {
      group('identitytoolkit general', () {
        var tester = Tester(
          path: 'accounts:signUp',
          expectedBody: {},
          expectedResult: (response) => {'id_token': response['idToken']},
          action: () => rpcHandler
              .signInAnonymously()
              .then((v) => {'id_token': v.credential.response!['id_token']}),
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
              expectedError: FirebaseAuthException.invalidCustomToken()
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
              expectedError: FirebaseAuthException.internalError()
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
              expectedError: FirebaseAuthException.internalError()
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
              expectedError: FirebaseAuthException.internalError()
                  .replace(message: json.encode(serverResponse)),
            );
          });
        });
      });

      group('getAuthorizedDomains', () {
        var tester = Tester(
            path: 'projects',
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
            path: 'recaptchaParams',
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
            expectedError: FirebaseAuthException.internalError(),
          );
        });
      });
      group('getDynamicLinkDomain', () {
        var tester = Tester(
          path: 'projects',
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
            expectedError: FirebaseAuthException.internalError(),
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
            expectedError: FirebaseAuthException.dynamicLinkNotActivated(),
          );
        });
      });

      group('isIosBundleIdValid', () {
        var tester = Tester(
          path: 'projects',
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
            expectedError: FirebaseAuthException.invalidAppId(),
          );
        });
      });

      group('isAndroidPackageNameValid', () {
        var tester = Tester(
          path: 'projects',
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
              expectedError: FirebaseAuthException.invalidAppId(),
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
              expectedError: FirebaseAuthException.invalidCertHash(),
            );
          });
        });
      });

      group('isOAuthCliendIdValid', () {
        var tester = Tester(
          path: 'projects',
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
            expectedError: FirebaseAuthException.invalidOAuthClientId(),
          );
        });
      });

      group('fetchSignInMethodsForIdentifier', () {
        var identifier = 'user@example.com';
        var tester = Tester(
          path: 'accounts:createAuthUri',
          expectedBody: () =>
              {'identifier': identifier, 'continueUri': platform.currentUrl},
          action: () => rpcHandler.fetchSignInMethodsForIdentifier(identifier),
          expectedResult: (r) => r['signinMethods'] ?? [],
        );

        test('fetchSignInMethodsForIdentifier: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
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
              'registered': true,
              'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
            },
          );
        });
        test('fetchSignInMethodsForIdentifier: non http or https', () async {
          // Simulate non http or https current URL.
          platform = Platform.web(
              currentUrl: 'chrome-extension://234567890/index.html',
              isMobile: true,
              isOnline: true) as WebPlatform;
          initPlatform(platform);
          await tester.shouldSucceed(
            expectedBody: {
              'identifier': identifier,
              // A fallback HTTP URL should be used.
              'continueUri': 'http://localhost'
            },
            serverResponse: {
              'allProviders': ['google.com', 'password'],
              'signinMethods': ['google.com', 'emailLink'],
              'registered': true,
              'sessionId': 'AXT8iKR2x89y2o7zRnroApio_uo'
            },
          );
        });

        test('fetchSignInMethodsForIdentifier: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_IDENTIFIER': FirebaseAuthException.invalidEmail(),
            'MISSING_CONTINUE_URI': FirebaseAuthException.internalError(),
          });
        });
      });

      group('fetchProvidersForIdentifier', () {
        var identifier = 'MY_ID';
        var tester = Tester(
          path: 'accounts:createAuthUri',
          expectedBody: () =>
              {'identifier': identifier, 'continueUri': platform.currentUrl},
          action: () => rpcHandler.fetchProvidersForIdentifier(identifier),
          expectedResult: (r) => r['allProviders'] ?? [],
        );

        test('fetchProvidersForIdentifier: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
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
          platform = Platform.web(
              currentUrl: 'chrome-extension://234567890/index.html',
              isOnline: true,
              isMobile: true) as WebPlatform;
          initPlatform(platform);
          await tester.shouldSucceed(
            expectedBody: {
              'identifier': identifier,
              // A fallback HTTP URL should be used.
              'continueUri': 'http://localhost'
            },
            serverResponse: {
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
            'INVALID_IDENTIFIER': FirebaseAuthException.invalidEmail(),
            'MISSING_CONTINUE_URI': FirebaseAuthException.internalError(),
          });
        });
      });
      group('getAccountInfoByIdToken', () {
        var tester = Tester(
          path: 'accounts:lookup',
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
      group('signInWithCustomToken', () {
        var tester = Tester(
          path: 'accounts:signInWithCustomToken',
          expectedBody: {'token': 'CUSTOM_TOKEN', 'returnSecureToken': true},
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .signInWithCustomToken('CUSTOM_TOKEN')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );

        test('signInWithCustomToken: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'my_id')},
          );
        });

        test('signInWithCustomToken: tenant id', () async {
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

        test('signInWithCustomToken: unsupported tenant operation', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldFailWithServerErrors(expectedBody: {
            'token': 'CUSTOM_TOKEN',
            'returnSecureToken': true,
            'tenantId': '123456789012'
          }, errorMap: {
            'UNSUPPORTED_TENANT_OPERATION':
                FirebaseAuthException.unsupportedTenantOperation(),
          });
        });

        test('signInWithCustomToken: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'MISSING_CUSTOM_TOKEN': FirebaseAuthException.internalError(),
            'INVALID_CUSTOM_TOKEN': FirebaseAuthException.invalidCustomToken(),
            'CREDENTIAL_MISMATCH': FirebaseAuthException.credentialMismatch(),
            'INVALID_TENANT_ID': FirebaseAuthException.invalidTenantId(),
            'TENANT_ID_MISMATCH': FirebaseAuthException.tenantIdMismatch(),
          });
        });

        test('signInWithCustomToken: unknown server response', () async {
          await tester.shouldFail(
              expectedBody: {
                'token': 'CUSTOM_TOKEN',
                'returnSecureToken': true
              },
              serverResponse: {},
              expectedError: FirebaseAuthException.internalError(),
              action: () => rpcHandler.signInWithCustomToken('CUSTOM_TOKEN'));
        });
      });

      group('signInWithEmailLink', () {
        var tester = Tester(
            path: 'accounts:signInWithEmailLink',
            expectedBody: {
              'email': 'user@example.com',
              'oobCode': 'OTP_CODE',
            },
            expectedResult: (response) {
              return {'id_token': response['idToken']};
            },
            action: () => rpcHandler
                .signInWithEmailLink('user@example.com', 'OTP_CODE')
                .then((v) => {'id_token': v.credential.response!['id_token']}));
        test('signInWithEmailLink: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('signInWithEmailLink: multi factor required', () async {
          await tester.shouldFail(
            expectedError: FirebaseAuthException.mfaRequired(),
            serverResponse: pendingCredResponse,
          );
        });

        test('signInWithEmailLink: tenant id', () async {
          rpcHandler.tenantId = 'TENANT_ID';
          await tester.shouldSucceed(
            expectedBody: {
              'email': 'user@example.com',
              'oobCode': 'OTP_CODE',
              'tenantId': 'TENANT_ID'
            },
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('signInWithEmailLink: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_EMAIL': FirebaseAuthException.invalidEmail(),
          });
        });

        test('signInWithEmailLink: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('signInWithEmailLink: empty action code error', () async {
          // Test when empty action code is passed in signInWithEmailLink request.
          expect(() => rpcHandler.signInWithEmailLink('user@example.com', ''),
              throwsA(FirebaseAuthException.internalError()));
        });
        test('signInWithEmailLink: invalid email error', () async {
          // Test when invalid email is passed in signInWithEmailLink request.
          expect(
              () => rpcHandler.signInWithEmailLink('user.invalid', 'OTP_CODE'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
      });

      group('signUp', () {
        var tester = Tester(
          path: 'accounts:signUp',
          expectedBody: {
            'email': 'uid123@fake.com',
            'password': 'mysupersecretpassword',
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .signUp('uid123@fake.com', 'mysupersecretpassword')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );
        test('signUp: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });
        test('signUp: tenant id', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldSucceed(
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'tenantId': '123456789012'
            },
            serverResponse: {'idToken': createMockJwt(uid: 'user1')},
          );
        });

        test('signUp: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EMAIL_EXISTS': FirebaseAuthException.emailExists(),
              'PASSWORD_LOGIN_DISABLED':
                  FirebaseAuthException.operationNotAllowed(),
              'OPERATION_NOT_ALLOWED':
                  FirebaseAuthException.operationNotAllowed(),
              'WEAK_PASSWORD': FirebaseAuthException.weakPassword(),
              'ADMIN_ONLY_OPERATION':
                  FirebaseAuthException.adminOnlyOperation(),
              'INVALID_TENANT_ID': FirebaseAuthException.invalidTenantId(),
            },
          );
        });
        test('signUp: unknown server response', () async {
          // Test when server returns unexpected response with no error message.
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('signUp: no password error', () async {
          expect(() => rpcHandler.signUp('uid123@fake.com', ''),
              throwsA(FirebaseAuthException.weakPassword()));
        });
        test('signUp: invalid email error', () async {
          expect(
              () =>
                  rpcHandler.signUp('uid123.invalid', 'mysupersecretpassword'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
      });

      group('deleteAccount', () {
        var tester = Tester(
            path: 'accounts:delete',
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
                  FirebaseAuthException.credentialTooOldLoginAgain(),
              'INVALID_ID_TOKEN': FirebaseAuthException.invalidAuth(),
              'USER_NOT_FOUND': FirebaseAuthException.tokenExpired(),
              'TOKEN_EXPIRED': FirebaseAuthException.tokenExpired(),
              'USER_DISABLED': FirebaseAuthException.userDisabled(),
              'ADMIN_ONLY_OPERATION':
                  FirebaseAuthException.adminOnlyOperation(),
            },
          );
        });

        test('deleteAccount: invalid request error', () async {
          expect(() => rpcHandler.deleteAccount(null),
              throwsA(FirebaseAuthException.internalError()));
        });
      });

      group('signInWithPassword', () {
        var tester = Tester(
            path: 'accounts:signInWithPassword',
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true
            },
            expectedResult: (response) {
              return {'id_token': response['idToken']};
            },
            action: () => rpcHandler
                .signInWithPassword('uid123@fake.com', 'mysupersecretpassword')
                .then((v) => {'id_token': v.credential.response!['id_token']}));
        test('signInWithPassword: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': createMockJwt(uid: 'uid123', providerId: 'password')
            },
          );
        });

        test('signInWithPassword: multi factor required', () async {
          await tester.shouldFail(
            expectedError: FirebaseAuthException.mfaRequired(),
            serverResponse: pendingCredResponse,
          );
        });

        test('signInWithPassword: tenant id', () async {
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

        test('signInWithPassword: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_EMAIL': FirebaseAuthException.invalidEmail(),
              'INVALID_PASSWORD': FirebaseAuthException.invalidPassword(),
              'TOO_MANY_ATTEMPTS_TRY_LATER':
                  FirebaseAuthException.tooManyAttemptsTryLater(),
              'USER_DISABLED': FirebaseAuthException.userDisabled(),
              'INVALID_TENANT_ID': FirebaseAuthException.invalidTenantId(),
            },
          );
        });

        test('signInWithPassword: unknown server response', () async {
          await tester.shouldFail(
            expectedBody: {
              'email': 'uid123@fake.com',
              'password': 'mysupersecretpassword',
              'returnSecureToken': true
            },
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
            action: () => rpcHandler.signInWithPassword(
                'uid123@fake.com', 'mysupersecretpassword'),
          );
        });

        test('signInWithPassword: invalid password request', () async {
          expect(() => rpcHandler.signInWithPassword('uid123@fake.com', ''),
              throwsA(FirebaseAuthException.invalidPassword()));
        });

        test('signInWithPassword: invalid email error', () async {
          // Test when invalid email is passed in signInWithPassword request.
          // Test when request is invalid.
          expect(
              () => rpcHandler.signInWithPassword(
                  'uid123.invalid', 'mysupersecretpassword'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
      });

      group('signInAnonymously', () {
        var tester = Tester(
          path: 'accounts:signUp',
          expectedBody: {},
          expectedResult: (response) => {'id_token': response['idToken']},
          action: () => rpcHandler
              .signInAnonymously()
              .then((v) => {'id_token': v.credential.response!['id_token']}),
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
            expectedBody: {'tenantId': '123456789012'},
            serverResponse: {
              'idToken': createMockJwt(
                  uid: generateRandomString(24), providerId: 'anonymous')
            },
          );
        });
        test('signInAnonymously: unsupported tenant operation', () async {
          rpcHandler.tenantId = '123456789012';
          await tester.shouldFailWithServerErrors(
            expectedBody: {'tenantId': '123456789012'},
            errorMap: {
              'UNSUPPORTED_TENANT_OPERATION':
                  FirebaseAuthException.unsupportedTenantOperation(),
            },
          );
        });
        test('signInAnonymously: unknown server response', () async {
          // Test when server returns unexpected response with no error message.
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
      });
      group('signInWithIdp', () {
        var tester = Tester(
          path: 'accounts:signInWithIdp',
          expectedBody: {
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            'returnSecureToken': true
          },
          expectedResult: (v) => v['idToken'],
          action: () => rpcHandler
              .signInWithIdp(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse')
              .then((v) => v.credential.idToken.toCompactSerialization()),
        );
        test('signInWithIdp: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': createMockJwt(uid: 'my_id'),
              'oauthAccessToken': 'ACCESS_TOKEN',
              'oauthExpireIn': 3600,
              'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
            },
          );
        });
        test('signInWithIdp: with session id nonce: success', () async {
          var token = createMockJwt(uid: 'my_id');
          await tester.shouldSucceed(
            expectedBody: {
              'sessionId': 'NONCE',
              'requestUri':
                  'http://localhost/callback#id_token=ID_TOKEN&state=STATE',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': token,
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider'
            },
            action: () => rpcHandler
                .signInWithIdp(
                    sessionId: 'NONCE',
                    requestUri:
                        'http://localhost/callback#id_token=ID_TOKEN&state=STATE')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
        });
        test('signInWithIdp: with post body nonce: success', () async {
          var token = createMockJwt(uid: 'my_id');
          await tester.shouldSucceed(
            expectedBody: {
              'postBody':
                  'id_token=$token&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': token,
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider',
            },
            action: () => rpcHandler
                .signInWithIdp(
                    postBody:
                        'id_token=$token&providerId=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
        });
        test('signInWithIdp: pending token response: success', () async {
          var token = createMockJwt(uid: 'my_id');
          // Nonce should not be injected since pending token is present in response.
          await tester.shouldSucceed(
            expectedBody: {
              'postBody':
                  'id_token=$token&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            serverResponse: {
              'idToken': token,
              'oauthIdToken': 'OIDC_ID_TOKEN',
              'pendingToken': 'PENDING_TOKEN',
              'oauthExpireIn': 3600,
              'providerId': 'oidc.provider'
            },
            action: () => rpcHandler
                .signInWithIdp(
                    postBody:
                        'id_token=$token&providerId=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
        });
        group('signInWithIdp: pending token request', () {
          test('signInWithIdp: pending token request: success', () async {
            await tester.shouldSucceed(
              expectedBody: {
                'pendingIdToken': 'PENDING_TOKEN',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'idToken': createMockJwt(uid: 'my_id'),
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN2',
                'oauthExpireIn': 3600,
              },
              action: () => rpcHandler
                  .signInWithIdp(
                      pendingIdToken: 'PENDING_TOKEN',
                      requestUri: 'http://localhost')
                  .then((v) => v.credential.idToken.toCompactSerialization()),
            );
          });

          test('signInWithIdp: pending token request: server caught error',
              () async {
            await tester.shouldFailWithServerErrors(
              expectedBody: {
                'pendingIdToken': 'PENDING_TOKEN',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              action: () => rpcHandler.signInWithIdp(
                pendingIdToken: 'PENDING_TOKEN',
                requestUri: 'http://localhost',
              ),
              errorMap: {
                'INVALID_IDP_RESPONSE':
                    FirebaseAuthException.invalidIdpResponse(),
                'INVALID_PENDING_TOKEN':
                    FirebaseAuthException.invalidIdpResponse(),
              },
            );
          });
        });
        group('signInWithIdp: return idp credential', () {
          test('signInWithIdp: return idp credential: no recovery error',
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
              expectedError: FirebaseAuthException.userDisabled(),
              action: () => rpcHandler.signInWithIdp(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse'),
            );
          });
        });
        test('signInWithIdp: error', () async {
          expect(
              () => rpcHandler.signInWithIdp(
                  requestUri: 'http://localhost/callback#oauthResponse'),
              throwsA(FirebaseAuthException.internalError()));
        });
        test('signInWithIdp: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            expectedBody: {
              'postBody':
                  'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=invalid',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdp(
              postBody:
                  'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=invalid',
              requestUri: 'http://localhost',
            ),
            errorMap: {
              'INVALID_IDP_RESPONSE':
                  FirebaseAuthException.invalidIdpResponse(),
              'USER_DISABLED': FirebaseAuthException.userDisabled(),
              'FEDERATED_USER_ID_ALREADY_LINKED':
                  FirebaseAuthException.credentialAlreadyInUse(),
              'OPERATION_NOT_ALLOWED':
                  FirebaseAuthException.operationNotAllowed(),
              'USER_CANCELLED': FirebaseAuthException.userCancelled(),
              'MISSING_OR_INVALID_NONCE':
                  FirebaseAuthException.missingOrInvalidNonce()
            },
          );
        });
        test('signInWithIdp: invalid request error', () async {
          // Test when request is invalid.
          expect(() => rpcHandler.signInWithIdp(postBody: '....'),
              throwsA(FirebaseAuthException.internalError()));
        });

        group('signInWithIdp: need confirmation error', () {
          test(
              'signInWithIdp: need confirmation error: oauth response and email',
              () {
            // Test Auth linking error when need confirmation flag is returned.
            var credential =
                GoogleAuthProvider.credential(accessToken: 'googleAccessToken');

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
              expectedError: FirebaseAuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody:
                      'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                  requestUri: 'http://localhost'),
            );
          });
          test('signInWithIdp: need confirmation error: nonce id token',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');

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
              expectedError: FirebaseAuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });

          test('signInWithIdp: need confirmation error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');

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
              expectedError: FirebaseAuthException.needConfirmation()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test('signInWithIdp: need confirmation error: pending token',
              () async {
            // Expected error thrown with OIDC credential containing pending token and
            // no nonce.
            var credential = OAuthCredential(
                providerId: 'oidc.provider',
                signInMethod: 'oauth',
                idToken: 'OIDC_ID_TOKEN',
                secret: 'PENDING_TOKEN');

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
                expectedError: FirebaseAuthException.needConfirmation()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });

          test('signInWithIdp: need confirmation error: pending token',
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
                expectedError: FirebaseAuthException.needConfirmation()
                    .replace(email: 'user@example.com'),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id'
                        '=google.com',
                    requestUri: 'http://localhost'));
          });

          test('signInWithIdp: need confirmation error: no extra info',
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
                expectedError: FirebaseAuthException.needConfirmation(),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                    requestUri: 'http://localhost'));
          });
        });

        group('signInWithIdp: credentials already in use error', () {
          test(
              'signInWithIdp: credentials already in use error: oauth response and email',
              () async {
            // Test Auth linking error when FEDERATED_USER_ID_ALREADY_LINKED errorMessage
            // is returned.
            var credential =
                GoogleAuthProvider.credential(accessToken: 'googleAccessToken');
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
                  'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                  'email': 'user@example.com',
                  'oauthAccessToken': 'googleAccessToken',
                  'oauthExpireIn': 5183999,
                  'providerId': 'google.com'
                },
                expectedError: FirebaseAuthException.credentialAlreadyInUse()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=googleIdToken&access_token=accessToken&provider_id=google.com',
                    requestUri: 'http://localhost'));
          });
          test(
              'signInWithIdp: credentials already in use error: nonce id token',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                  'email': 'user@example.com',
                  'oauthExpireIn': 5183999,
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'providerId': 'oidc.provider'
                },
                expectedError: FirebaseAuthException.credentialAlreadyInUse()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });
          test(
              'signInWithIdp: credentials already in use error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                'sessionId': 'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: FirebaseAuthException.credentialAlreadyInUse()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test('signInWithIdp: credentials already in use error: pending token',
              () async {
            // Expected error thrown with OIDC credential containing pending token and no
            // nonce.
            var credential = OAuthCredential(
                providerId: 'oidc.provider',
                signInMethod: 'oauth',
                secret: 'PENDING_TOKEN',
                idToken: 'OIDC_ID_TOKEN');
            await tester.shouldFail(
              expectedBody: {
                'postBody':
                    'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'errorMessage': 'FEDERATED_USER_ID_ALREADY_LINKED',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider',
                'pendingToken': 'PENDING_TOKEN'
              },
              expectedError: FirebaseAuthException.credentialAlreadyInUse()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });
        });

        group('signInWithIdp: email exists error', () {
          test('signInWithIdp: email exists error: oauth response and email',
              () async {
            // Test Auth linking error when EMAIL_EXISTS errorMessage is returned.
            var credential =
                FacebookAuthProvider.credential('facebookAccessToken');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'access_token=accessToken&provider_id=facebook.com',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthAccessToken': 'facebookAccessToken',
                'oauthExpireIn': 5183999,
                'providerId': 'facebook.com'
              },
              expectedError: FirebaseAuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody: 'access_token=accessToken&provider_id=facebook.com',
                  requestUri: 'http://localhost'),
            );
          });
          test('signInWithIdp: email exists error: nonce id token', () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');
            await tester.shouldFail(
                expectedBody: {
                  'postBody':
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true
                },
                serverResponse: {
                  'errorMessage': 'EMAIL_EXISTS',
                  'email': 'user@example.com',
                  'oauthExpireIn': 5183999,
                  'oauthIdToken': 'OIDC_ID_TOKEN',
                  'providerId': 'oidc.provider'
                },
                expectedError: FirebaseAuthException.emailExists()
                    .replace(email: 'user@example.com', credential: credential),
                action: () => rpcHandler.signInWithIdp(
                    postBody:
                        'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost'));
          });
          test('signInWithIdp: email exists error: id token session id',
              () async {
            // Expected error thrown with OIDC credential containing nonce.
            var credential = OAuthProvider.credential(
                providerId: 'oidc.provider',
                idToken: 'OIDC_ID_TOKEN',
                rawNonce: 'NONCE');
            await tester.shouldFail(
              expectedBody: {
                'postBody': 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                'sessionId': 'NONCE',
                'requestUri': 'http://localhost',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              serverResponse: {
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider'
              },
              expectedError: FirebaseAuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody: 'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider',
                  sessionId: 'NONCE',
                  requestUri: 'http://localhost'),
            );
          });
          test('signInWithIdp: email exists error: pending token', () async {
            // Expected error thrown with OIDC credential containing no nonce since
            // pending token returned from server.
            var credential = OAuthCredential(
                providerId: 'oidc.provider',
                signInMethod: 'oauth',
                secret: 'PENDING_TOKEN',
                idToken: 'OIDC_ID_TOKEN');
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
                'errorMessage': 'EMAIL_EXISTS',
                'email': 'user@example.com',
                'oauthExpireIn': 5183999,
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'providerId': 'oidc.provider',
                'pendingToken': 'PENDING_TOKEN'
              },
              expectedError: FirebaseAuthException.emailExists()
                  .replace(email: 'user@example.com', credential: credential),
              action: () => rpcHandler.signInWithIdp(
                  postBody:
                      'id_token=OIDC_ID_TOKEN&provider_id=oidc.provider&nonce=NONCE',
                  requestUri: 'http://localhost'),
            );
          });
        });
      });

      group('signInWithIdpForLinking', () {
        var tester = Tester(
          path: 'accounts:signInWithIdp',
          expectedBody: {
            'idToken': 'existingIdToken',
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            'returnSecureToken': true
          },
          action: () => rpcHandler.signInWithIdpForLinking(
              idToken: 'existingIdToken',
              sessionId: 'SESSION_ID',
              requestUri: 'http://localhost/callback#oauthResponse'),
        );
        test('signInWithIdpForLinking: success', () async {
          await tester.shouldSucceed(serverResponse: {
            'idToken': 'ID_TOKEN',
            'oauthAccessToken': 'ACCESS_TOKEN',
            'oauthExpireIn': 3600,
            'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
          });
        });

        group('signInWithIdpForLinking: withSessionIdNonce', () {
          var t = tester.replace(
              expectedBody: {
                'idToken': 'existingIdToken',
                'sessionId': 'NONCE',
                'requestUri':
                    'http://localhost/callback#id_token=ID_TOKEN&state=STATE',
                'returnIdpCredential': true,
                'returnSecureToken': true
              },
              action: () => rpcHandler.signInWithIdpForLinking(
                  idToken: 'existingIdToken',
                  sessionId: 'NONCE',
                  requestUri:
                      'http://localhost/callback#id_token=ID_TOKEN&state=STATE'));
          test('signInWithIdpForLinking: withSessionIdNonce: success',
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

        group('signInWithIdpForLinking: with post body nonce', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForLinking(
                idToken: 'existingIdToken',
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('signInWithIdpForLinking: with post body nonce: success',
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

        group('signInWithIdpForLinking: pending token response', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'postBody':
                  'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForLinking(
                idToken: 'existingIdToken',
                postBody:
                    'id_token=ID_TOKEN&providerId=oidc.provider&nonce=NONCE',
                requestUri: 'http://localhost'),
          );
          test('signInWithIdpForLinking: pending token response: success',
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
        group('signInWithIdpForLinking: pending token request', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'existingIdToken',
              'pendingIdToken': 'PENDING_TOKEN',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForLinking(
                idToken: 'existingIdToken',
                pendingToken: 'PENDING_TOKEN',
                requestUri: 'http://localhost'),
          );
          test('signInWithIdpForLinking: pending token request: success',
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
        group('signInWithIdpForLinking: return idp credential', () {
          var t = tester.replace(
            expectedBody: {
              'idToken': 'ID_TOKEN',
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForLinking(
                idToken: 'ID_TOKEN',
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test(
              'signInWithIdpForLinking: return idp credential: no recovery error',
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
              expectedError: FirebaseAuthException.userDisabled(),
            );
          });
        });

        test('signInWithIdpForLinking: error', () async {
          expect(
              () => rpcHandler.signInWithIdpForLinking(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse'),
              throwsA(FirebaseAuthException.internalError()));
        });
      });

      group('signInWithIdpForExisting', () {
        var tester = Tester(
          path: 'accounts:signInWithIdp',
          expectedBody: {
            'sessionId': 'SESSION_ID',
            'requestUri': 'http://localhost/callback#oauthResponse',
            'returnIdpCredential': true,
            // autoCreate flag should be passed and set to false.
            'autoCreate': false,
            'returnSecureToken': true
          },
          expectedResult: (v) => v['idToken'],
          action: () => rpcHandler
              .signInWithIdpForExisting(
                  sessionId: 'SESSION_ID',
                  requestUri: 'http://localhost/callback#oauthResponse')
              .then((v) => v.credential.idToken.toCompactSerialization()),
        );
        test('signInWithIdpForExisting: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'idToken': createMockJwt(uid: 'my_id'),
              'oauthAccessToken': 'ACCESS_TOKEN',
              'oauthExpireIn': 3600,
              'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
            },
          );
        });

        group('signInWithIdpForExisting: with session id nonce', () {
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
            expectedResult: (v) => v['idToken'],
            action: () => rpcHandler
                .signInWithIdpForExisting(
                    sessionId: 'NONCE',
                    requestUri:
                        'http://localhost/callback#id_token=ID_TOKEN&state=STATE')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
          test('signInWithIdpForExisting: with session id nonce: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': createMockJwt(uid: 'my_id'),
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider'
              },
            );
          });
        });
        group('signInWithIdpForExisting: with post body nonce', () {
          var t = tester.replace(
            expectedBody: {
              'postBody':
                  'id_token=${createMockJwt(uid: 'my_id')}&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            expectedResult: (v) => v['idToken'],
            action: () => rpcHandler
                .signInWithIdpForExisting(
                    postBody:
                        'id_token=${createMockJwt(uid: 'my_id')}&providerId=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
          test('signInWithIdpForExisting: with post body nonce: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': createMockJwt(uid: 'my_id'),
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider',
              },
            );
          });
        });
        group('signInWithIdpForExisting: pending token response', () {
          var t = tester.replace(
            expectedBody: {
              'postBody':
                  'id_token=${createMockJwt(uid: 'my_id')}&providerId=oidc.provider&nonce=NONCE',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            expectedResult: (v) => v['idToken'],
            action: () => rpcHandler
                .signInWithIdpForExisting(
                    postBody:
                        'id_token=${createMockJwt(uid: 'my_id')}&providerId=oidc.provider&nonce=NONCE',
                    requestUri: 'http://localhost')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
          test('signInWithIdpForExisting: pending token response: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': createMockJwt(uid: 'my_id'),
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN',
                'oauthExpireIn': 3600,
                'providerId': 'oidc.provider'
              },
            );
          });
        });
        group('signInWithIdpForExisting: pending token request', () {
          var t = tester.replace(
            expectedBody: {
              'pendingIdToken': 'PENDING_TOKEN',
              'requestUri': 'http://localhost',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            expectedResult: (v) => v['idToken'],
            action: () => rpcHandler
                .signInWithIdpForExisting(
                    pendingToken: 'PENDING_TOKEN',
                    requestUri: 'http://localhost')
                .then((v) => v.credential.idToken.toCompactSerialization()),
          );
          test('signInWithIdpForExisting: pending token request: success',
              () async {
            await t.shouldSucceed(
              serverResponse: {
                'idToken': createMockJwt(uid: 'my_id'),
                'oauthIdToken': 'OIDC_ID_TOKEN',
                'pendingToken': 'PENDING_TOKEN2',
                'oauthExpireIn': 3600
              },
            );
          });
        });
        group('signInWithIdpForExisting: return idp credential', () {
          var t = tester.replace(
            expectedBody: {
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForExisting(
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test(
              'signInWithIdpForExisting: return idp credential: no recovery error',
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
              expectedError: FirebaseAuthException.userDisabled(),
            );
          });
        });

        group('signInWithIdpForExisting: error', () {
          var t = tester.replace(
            expectedBody: {
              'sessionId': 'SESSION_ID',
              'requestUri': 'http://localhost/callback#oauthResponse',
              'returnIdpCredential': true,
              // autoCreate flag should be passed and set to false.
              'autoCreate': false,
              'returnSecureToken': true
            },
            action: () => rpcHandler.signInWithIdpForExisting(
                sessionId: 'SESSION_ID',
                requestUri: 'http://localhost/callback#oauthResponse'),
          );
          test('signInWithIdpForExisting: error', () async {
            // Same client side validation as signInWithIdp.
            expect(
                () => rpcHandler.signInWithIdpForExisting(
                    requestUri: 'http://localhost/callback#oauthResponse'),
                throwsA(FirebaseAuthException.internalError()));
          });
          test('signInWithIdpForExisting: error: user not found', () async {
            // No user is found. No idToken returned.
            await t.shouldFail(
              serverResponse: {
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE',
                'errorMessage': 'USER_NOT_FOUND'
              },
              expectedError: FirebaseAuthException.userDeleted(),
            );
          });
          test('signInWithIdpForExisting: error: no idToken', () async {
            // No idToken returned for whatever reason.
            await t.shouldFail(
              serverResponse: {
                'oauthAccessToken': 'ACCESS_TOKEN',
                'oauthExpireIn': 3600,
                'oauthAuthorizationCode': 'AUTHORIZATION_CODE'
              },
              expectedError: FirebaseAuthException.internalError(),
            );
          });
        });
        test('signInWithIdpForExisting: invalid request error', () async {
          // Test when request is invalid.
          expect(() => rpcHandler.signInWithIdpForExisting(postBody: '....'),
              throwsA(FirebaseAuthException.internalError()));
        });
        test('signInWithIdpForExisting: server caught error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_IDP_RESPONSE': FirebaseAuthException.invalidIdpResponse(),
            'USER_DISABLED': FirebaseAuthException.userDisabled(),
            'OPERATION_NOT_ALLOWED':
                FirebaseAuthException.operationNotAllowed(),
            'USER_CANCELLED': FirebaseAuthException.userCancelled(),
          });
        });
      });

      group('sendSignInLinkToEmail', () {
        var userEmail = 'user@example.com';
        var tester = Tester(
          path: 'accounts:sendOobCode',
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
              actionCodeSettings: ActionCodeSettings(
                  url: 'https://www.example.com/?state=abc',
                  iOSBundleId: 'com.example.ios',
                  androidPackageName: 'com.example.android',
                  androidInstallApp: true,
                  androidMinimumVersion: '12',
                  handleCodeInApp: true,
                  dynamicLinkDomain: 'example.page.link')),
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
            httpClient.locale = 'es';
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
              throwsA(FirebaseAuthException.invalidEmail()));
        });
        test('sendSignInLinkToEmail: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('sendSignInLinkToEmail: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_RECIPIENT_EMAIL':
                  FirebaseAuthException.invalidRecipientEmail(),
              'INVALID_SENDER': FirebaseAuthException.invalidSender(),
              'INVALID_MESSAGE_PAYLOAD':
                  FirebaseAuthException.invalidMessagePayload(),
              'INVALID_CONTINUE_URI':
                  FirebaseAuthException.invalidContinueUri(),
              'MISSING_ANDROID_PACKAGE_NAME':
                  FirebaseAuthException.missingAndroidPackageName(),
              'MISSING_IOS_BUNDLE_ID':
                  FirebaseAuthException.missingIosBundleId(),
              'UNAUTHORIZED_DOMAIN': FirebaseAuthException.unauthorizedDomain(),
              'INVALID_DYNAMIC_LINK_DOMAIN':
                  FirebaseAuthException.invalidDynamicLinkDomain(),
            },
          );
        });
      });
      group('sendPasswordResetEmail', () {
        var userEmail = 'user@example.com';
        var tester = Tester(
            path: 'accounts:sendOobCode',
            expectedBody: {
              'requestType': 'PASSWORD_RESET',
              'email': userEmail,
              'continueUrl': 'https://www.example.com/?state=abc',
              'iOSBundleId': 'com.example.ios',
              'androidPackageName': 'com.example.android',
              'androidInstallApp': true,
              'androidMinimumVersion': '12',
              'canHandleCodeInApp': true,
              'dynamicLinkDomain': 'example.page.link'
            },
            expectedResult: (_) => userEmail,
            action: () => rpcHandler.sendPasswordResetEmail(
                email: 'user@example.com',
                actionCodeSettings: ActionCodeSettings(
                    url: 'https://www.example.com/?state=abc',
                    iOSBundleId: 'com.example.ios',
                    androidPackageName: 'com.example.android',
                    androidInstallApp: true,
                    androidMinimumVersion: '12',
                    handleCodeInApp: true,
                    dynamicLinkDomain: 'example.page.link')));

        test('sendPasswordResetEmail: success: action code settings', () async {
          await tester.shouldSucceed(
            serverResponse: {'email': userEmail},
          );
        });

        group('sendPasswordResetEmail: no action code settings', () {
          var t = tester.replace(
              expectedBody: {
                'requestType': 'PASSWORD_RESET',
                'email': userEmail
              },
              action: () =>
                  rpcHandler.sendPasswordResetEmail(email: 'user@example.com'));
          test('sendPasswordResetEmail: success: no action code settings',
              () async {
            await t.shouldSucceed(
              serverResponse: {'email': userEmail},
            );
          });

          test('sendPasswordResetEmail: success: custom locale: no action code',
              () async {
            httpClient.locale = 'es';

            await tester.shouldSucceed(
              serverResponse: {'email': userEmail},
              expectedHeaders: {
                'Content-Type': 'application/json',
                'X-Firebase-Locale': 'es'
              },
            );
          });
        });
        test('sendPasswordResetEmail: invalid email error', () async {
          // Test when invalid email is passed in getOobCode request.

          expect(() => rpcHandler.sendPasswordResetEmail(email: 'user.invalid'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
        test('sendPasswordResetEmail: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('sendPasswordResetEmail: caught server error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'EMAIL_NOT_FOUND': FirebaseAuthException.userDeleted(),
            'RESET_PASSWORD_EXCEED_LIMIT':
                FirebaseAuthException.tooManyAttemptsTryLater(),
            'INVALID_RECIPIENT_EMAIL':
                FirebaseAuthException.invalidRecipientEmail(),
            'INVALID_SENDER': FirebaseAuthException.invalidSender(),
            'INVALID_MESSAGE_PAYLOAD':
                FirebaseAuthException.invalidMessagePayload(),
            'INVALID_CONTINUE_URI': FirebaseAuthException.invalidContinueUri(),
            'MISSING_ANDROID_PACKAGE_NAME':
                FirebaseAuthException.missingAndroidPackageName(),
            'MISSING_IOS_BUNDLE_ID': FirebaseAuthException.missingIosBundleId(),
            'UNAUTHORIZED_DOMAIN': FirebaseAuthException.unauthorizedDomain(),
            'INVALID_DYNAMIC_LINK_DOMAIN':
                FirebaseAuthException.invalidDynamicLinkDomain(),
          });
        });
      });
      group('sendEmailVerification', () {
        var idToken = 'ID_TOKEN';
        var userEmail = 'user@example.com';
        var tester = Tester(
          path: 'accounts:sendOobCode',
          expectedBody: {
            'requestType': 'VERIFY_EMAIL',
            'idToken': idToken,
            'continueUrl': 'https://www.example.com/?state=abc',
            'iOSBundleId': 'com.example.ios',
            'androidPackageName': 'com.example.android',
            'androidInstallApp': true,
            'androidMinimumVersion': '12',
            'canHandleCodeInApp': true,
            'dynamicLinkDomain': 'example.page.link'
          },
          expectedResult: (_) => userEmail,
          action: () => rpcHandler.sendEmailVerification(
              idToken: idToken,
              actionCodeSettings: ActionCodeSettings(
                  url: 'https://www.example.com/?state=abc',
                  iOSBundleId: 'com.example.ios',
                  androidPackageName: 'com.example.android',
                  androidInstallApp: true,
                  androidMinimumVersion: '12',
                  handleCodeInApp: true,
                  dynamicLinkDomain: 'example.page.link')),
        );
        test('sendEmailVerification: success: action code settings', () async {
          await tester.shouldSucceed(
            serverResponse: {'email': userEmail},
          );
        });

        group('sendEmailVerification: no action code settings', () {
          var t = tester.replace(
            expectedBody: {'requestType': 'VERIFY_EMAIL', 'idToken': idToken},
            action: () => rpcHandler.sendEmailVerification(idToken: idToken),
          );
          test('sendEmailVerification: success: no action code settings',
              () async {
            await t.shouldSucceed(
              serverResponse: {'email': userEmail},
            );
          });
          test(
              'sendEmailVerification: success: custom locale: no action code settings',
              () async {
            httpClient.locale = 'ar';
            await t.shouldSucceed(
              serverResponse: {'email': userEmail},
              expectedHeaders: {
                'Content-Type': 'application/json',
                'X-Firebase-Locale': 'ar'
              },
            );
          });
        });
        test('sendEmailVerification: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('sendEmailVerification: caught server error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EMAIL_NOT_FOUND': FirebaseAuthException.userDeleted(),
              'INVALID_CONTINUE_URI':
                  FirebaseAuthException.invalidContinueUri(),
              'MISSING_ANDROID_PACKAGE_NAME':
                  FirebaseAuthException.missingAndroidPackageName(),
              'MISSING_IOS_BUNDLE_ID':
                  FirebaseAuthException.missingIosBundleId(),
              'UNAUTHORIZED_DOMAIN': FirebaseAuthException.unauthorizedDomain(),
              'INVALID_DYNAMIC_LINK_DOMAIN':
                  FirebaseAuthException.invalidDynamicLinkDomain(),
            },
          );
        });
      });

      group('confirmPasswordReset', () {
        var userEmail = 'user@example.com';
        var newPassword = 'newPass';
        var code = 'PASSWORD_RESET_OOB_CODE';
        var tester = Tester(
          path: 'accounts:resetPassword',
          expectedBody: {'oobCode': code, 'newPassword': newPassword},
          expectedResult: (_) => userEmail,
          action: () => rpcHandler.confirmPasswordReset(code, newPassword),
        );
        test('confirmPasswordReset: success', () async {
          await tester.shouldSucceed(serverResponse: {'email': userEmail});
        });

        test('confirmPasswordReset: missing code', () async {
          expect(() => rpcHandler.confirmPasswordReset('', 'myPassword'),
              throwsA(FirebaseAuthException.invalidOobCode()));
        });

        test('confirmPasswordReset: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('confirmPasswordReset: caught server error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EXPIRED_OOB_CODE': FirebaseAuthException.expiredOobCode(),
              'INVALID_OOB_CODE': FirebaseAuthException.invalidOobCode(),
              'MISSING_OOB_CODE': FirebaseAuthException.internalError(),
            },
          );
        });
      });

      group('checkActionCode', () {
        var code = 'REVOKE_EMAIL_OOB_CODE';
        var tester = Tester(
          path: 'accounts:resetPassword',
          expectedBody: {'oobCode': code},
          action: () => rpcHandler.checkActionCode(code),
        );
        test('checkActionCode: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'email': 'user@example.com',
              'newEmail': 'fake@example.com',
              'requestType': 'PASSWORD_RESET'
            },
          );
        });

        test('checkActionCode: email sign in success', () async {
          // Email field is empty for EMAIL_SIGNIN.
          await tester.shouldSucceed(
            serverResponse: {'requestType': 'EMAIL_SIGNIN'},
          );
        });

        test('checkActionCode: missing code', () async {
          expect(() => rpcHandler.checkActionCode(''),
              throwsA(FirebaseAuthException.invalidOobCode()));
        });
        test('checkActionCode: uncaught server error', () async {
          // Required fields missing in response.
          await tester.shouldFail(
            expectedBody: {'oobCode': code},
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('checkActionCode: uncaught server error', () async {
          // Required requestType field missing in response.
          await tester.shouldFail(
            serverResponse: {
              'email': 'user@example.com',
              'newEmail': 'fake@example.com'
            },
            expectedError: FirebaseAuthException.internalError(),
          );
        });
        test('checkActionCode: caught server error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EXPIRED_OOB_CODE': FirebaseAuthException.expiredOobCode(),
              'INVALID_OOB_CODE': FirebaseAuthException.invalidOobCode(),
              'MISSING_OOB_CODE': FirebaseAuthException.internalError()
            },
          );
        });
      });

      group('applyActionCode', () {
        var userEmail = 'user@example.com';
        var code = 'EMAIL_VERIFICATION_OOB_CODE';
        var tester = Tester(
          path: 'accounts:update',
          expectedBody: {'oobCode': code},
          action: () => rpcHandler.applyActionCode(code),
          expectedResult: (_) => userEmail,
        );
        test('applyActionCode: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'email': userEmail},
          );
        });

        test('applyActionCode: missing code', () async {
          expect(() => rpcHandler.applyActionCode(''),
              throwsA(FirebaseAuthException.invalidOobCode()));
        });

        test('applyActionCode: unknown server response', () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('applyActionCode: caught server error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'EXPIRED_OOB_CODE': FirebaseAuthException.expiredOobCode(),
              'EMAIL_NOT_FOUND': FirebaseAuthException.userDeleted(),
              'INVALID_OOB_CODE': FirebaseAuthException.invalidOobCode(),
              'USER_DISABLED': FirebaseAuthException.userDisabled(),
            },
          );
        });
      });
      group('deleteLinkedAccounts', () {
        var tester = Tester(
          path: 'accounts:update',
          expectedBody: {
            'idToken': 'ID_TOKEN',
            'deleteProvider': ['github.com', 'facebook.com']
          },
          action: () => rpcHandler
              .deleteLinkedAccounts('ID_TOKEN', ['github.com', 'facebook.com']),
        );
        test('deleteLinkedAccounts: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'email': 'user@example.com',
              'providerUserInfo': [
                {'providerId': 'google.com'}
              ]
            },
          );
        });

        test('deleteLinkedAccounts: invalid request error', () async {
          expect(() => rpcHandler.deleteLinkedAccounts('ID_TOKEN', null),
              throwsA(FirebaseAuthException.internalError()));
        });

        test('deleteLinkedAccounts: server caught errors', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {'USER_NOT_FOUND': FirebaseAuthException.tokenExpired()},
          );
        });
      });

      group('updateProfile', () {
        var tester = Tester(
          path: 'accounts:update',
          expectedBody: {
            'idToken': 'ID_TOKEN',
            'displayName': 'John Doe',
            'photoUrl': 'http://abs.twimg.com/sticky/default.png',
            'returnSecureToken': true
          },
          action: () => rpcHandler.updateProfile('ID_TOKEN', {
            'displayName': 'John Doe',
            'photoUrl': 'http://abs.twimg.com/sticky/default.png'
          }),
        );
        test('updateProfile: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'email': 'uid123@fake.com',
              'displayName': 'John Doe',
              'photoUrl': 'http://abs.twimg.com/sticky/default.png'
            },
          );
        });

        test('updateProfile: blank fields', () async {
          await tester.shouldSucceed(
            serverResponse: {
              // We test here that a response without email is a valid response.
              'email': '',
              'displayName': ''
            },
          );
        });

        test('updateProfile: omittedFields', () async {
          var t = tester.replace(
              expectedBody: {
                'idToken': 'ID_TOKEN',
                'displayName': 'John Doe',
                'returnSecureToken': true
              },
              action: () => rpcHandler
                  .updateProfile('ID_TOKEN', {'displayName': 'John Doe'}));

          await t.shouldSucceed(
            serverResponse: {
              'email': 'uid123@fake.com',
              'displayName': 'John Doe',
              'photoUrl': 'http://abs.twimg.com/sticky/default.png'
            },
          );
        });

        test('updateProfile: delete fields', () async {
          var t = tester.replace(
              expectedBody: {
                'idToken': 'ID_TOKEN',
                'displayName': 'John Doe',
                'deleteAttribute': ['PHOTO_URL'],
                'returnSecureToken': true
              },
              action: () => rpcHandler.updateProfile(
                  'ID_TOKEN', {'displayName': 'John Doe', 'photoUrl': null}));
          await t.shouldSucceed(
            serverResponse: {
              'email': 'uid123@fake.com',
              'displayName': 'John Doe'
            },
          );
        });

        test('updateProfile: error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INTERNAL_ERROR': FirebaseAuthException.internalError().replace(
                  message:
                      '{"error":{"errors":[{"message":"INTERNAL_ERROR"}],"code":400,"message":"INTERNAL_ERROR"}}')
            },
          );
        });
      });

      group('updateEmail', () {
        var token = createMockJwt(uid: 'uid123');

        var tester = Tester(
          path: 'accounts:update',
          expectedBody: {
            'idToken': token,
            'email': 'newuser@example.com',
            'returnSecureToken': true
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .updateEmail(token, 'newuser@example.com')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );
        test('updateEmail: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'email': 'newuser@example.com', 'idToken': token},
          );
        });

        test('updateEmail: custom locale success', () async {
          httpClient.locale = 'tr';
          await tester.shouldSucceed(
            serverResponse: {'email': 'newuser@example.com', 'idToken': token},
            expectedHeaders: {
              'Content-Type': 'application/json',
              'X-Firebase-Locale': 'tr'
            },
          );
        });

        test('updateEmail: invalid email', () async {
          expect(() => rpcHandler.updateEmail('ID_TOKEN', 'newuser.invalid'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
      });

      group('updatePassword', () {
        var token = createMockJwt(uid: 'uid123');
        var tester = Tester(
          path: 'accounts:update',
          expectedBody: {
            'idToken': token,
            'password': 'newPassword',
            'returnSecureToken': true
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .updatePassword(token, 'newPassword')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );
        test('updatePassword: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'email': 'user@example.com', 'idToken': token},
          );
        });

        test('updatePassword: no password', () async {
          expect(() => rpcHandler.updatePassword('ID_TOKEN', ''),
              throwsA(FirebaseAuthException.weakPassword()));
        });
      });

      group('signInWithEmailLinkForLinking', () {
        var tester = Tester(
          path: 'accounts:signInWithEmailLink',
          expectedBody: {
            'idToken': 'ID_TOKEN',
            'email': 'user@example.com',
            'oobCode': 'OTP_CODE',
          },
          action: () => rpcHandler.signInWithEmailLinkForLinking(
              'ID_TOKEN', 'user@example.com', 'OTP_CODE'),
        );
        test('signInWithEmailLinkForLinking: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'idToken': 'ID_TOKEN'},
          );
        });

        test('signInWithEmailLinkForLinking: server caught error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_EMAIL': FirebaseAuthException.invalidEmail(),
              'TOO_MANY_ATTEMPTS_TRY_LATER':
                  FirebaseAuthException.tooManyAttemptsTryLater(),
              'USER_DISABLED': FirebaseAuthException.userDisabled()
            },
          );
        });

        test('signInWithEmailLinkForLinking: unknown server response',
            () async {
          // Test when server returns unexpected response with no error message.

          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('signInWithEmailLinkForLinking: empty action code error',
            () async {
          // Test when empty action code is passed in signInWithEmailLinkForLinking request.

          expect(
              () => rpcHandler.signInWithEmailLinkForLinking(
                  'ID_TOKEN', 'user@example.com', ''),
              throwsA(FirebaseAuthException.internalError()));
        });
        test('signInWithEmailLinkForLinking: invalid email error', () async {
          // Test when invalid email is passed in signInWithEmailLinkForLinking request.

          expect(
              () => rpcHandler.signInWithEmailLinkForLinking(
                  'ID_TOKEN', 'user.invalid', 'OTP_CODE'),
              throwsA(FirebaseAuthException.invalidEmail()));
        });
        test('signInWithEmailLinkForLinking: empty idToken error', () async {
          // Test when empty ID token is passed in signInWithEmailLinkForLinking request.

          expect(
              () => rpcHandler.signInWithEmailLinkForLinking(
                  '', 'user@example.com', 'OTP_CODE'),
              throwsA(FirebaseAuthException.internalError()));
        });
      });

      group('getAuthUri', () {
        var expectedCustomParameters = {
          'hd': 'example.com',
          'login_hint': 'user@example.com'
        };
        var tester = Tester(
          path: 'accounts:createAuthUri',
          expectedBody: {
            'identifier': 'user@example.com',
            'providerId': 'google.com',
            'continueUri': 'http://localhost/widget',
            'customParameter': expectedCustomParameters,
            'oauthScope': json.encode({'google.com': 'scope1,scope2,scope3'})
          },
          action: () => rpcHandler.getAuthUri(
              'google.com',
              'http://localhost/widget',
              expectedCustomParameters,
              ['scope1', 'scope2', 'scope3'],
              'user@example.com'),
        );

        test('getAuthUri: success', () async {
          await tester.shouldSucceed(
            serverResponse: {
              'authUri': 'https://accounts.google.com',
              'providerId': 'google.com',
              'registered': true,
              'forExistingProvider': true,
              'sessionId': 'SESSION_ID'
            },
          );
        });

        test('getAuthUri: success saml', () async {
          var t = tester.replace(
            expectedBody: {
              'providerId': 'saml.provider',
              'continueUri': 'http://localhost/widget'
            },
            action: () => rpcHandler.getAuthUri(
                'saml.provider',
                'http://localhost/widget',
                // Custom parameters should be ignored.
                expectedCustomParameters,
                // Scopes should be ignored.
                ['scope1', 'scope2', 'scope3'],
                null),
          );
          await t.shouldSucceed(
            serverResponse: {
              'authUri':
                  'https://www.example.com/samlp/?SAMLRequest=1234567890',
              'providerId': 'saml.provider',
              'registered': false,
              'sessionId': 'SESSION_ID'
            },
          );
        });

        test('getAuthUri: error missing continue uri', () async {
          expect(
              () => rpcHandler.getAuthUri(
                  'saml.provider',
                  null,
                  // Custom parameters should be ignored.
                  expectedCustomParameters,
                  // Scopes should be ignored.
                  ['scope1', 'scope2', 'scope3'],
                  'user@example.com'),
              throwsA(FirebaseAuthException.missingContinueUri()));
        });
        test('getAuthUri: error missing provider id', () async {
          expect(
              () => rpcHandler.getAuthUri(
                  // No provider ID.
                  null,
                  'http://localhost/widget',
                  // Custom parameters should be ignored.
                  expectedCustomParameters,
                  // Scopes should be ignored.
                  ['scope1', 'scope2', 'scope3'],
                  'user@example.com'),
              throwsA(FirebaseAuthException.internalError().replace(
                  message: 'A provider ID must be provided in the request.')));
        });

        test('getAuthUri: caught server error', () async {
          await tester.shouldFailWithServerErrors(
            errorMap: {
              'INVALID_PROVIDER_ID': FirebaseAuthException.invalidProviderId()
            },
          );
        });

        test('getAuthUri: google provider with session id', () async {
          var t = tester.replace(
            expectedBody: {
              'identifier': 'user@example.com',
              'providerId': 'google.com',
              'continueUri': 'http://localhost/widget',
              'customParameter': expectedCustomParameters,
              'oauthScope': json.encode({'google.com': 'scope1,scope2,scope3'}),
              'sessionId': 'SESSION_ID',
              'authFlowType': 'CODE_FLOW'
            },
            action: () => rpcHandler.getAuthUri(
                'google.com',
                'http://localhost/widget',
                expectedCustomParameters,
                ['scope1', 'scope2', 'scope3'],
                'user@example.com',
                'SESSION_ID'),
          );
          await t.shouldSucceed(
            serverResponse: {
              'authUri': 'https://accounts.google.com',
              'providerId': 'google.com',
              'registered': true,
              'forExistingProvider': true,
              'sessionId': 'SESSION_ID'
            },
          );
        });

        test('getAuthUri: other provider with session id', () async {
          var t = tester.replace(
            expectedBody: {
              'providerId': 'facebook.com',
              'continueUri': 'http://localhost/widget',
              'customParameter': {},
              'oauthScope':
                  json.encode({'facebook.com': 'scope1,scope2,scope3'}),
              'sessionId': 'SESSION_ID'
            },
            action: () => rpcHandler.getAuthUri(
                'facebook.com',
                'http://localhost/widget',
                null,
                ['scope1', 'scope2', 'scope3'],
                null,
                'SESSION_ID'),
          );
          await t.shouldSucceed(
            serverResponse: {
              'authUri': 'https://facebook.com/login',
              'providerId': 'facebook.com',
              'registered': true,
              'sessionId': 'SESSION_ID'
            },
          );
        });

        test('getAuthUri: error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INTERNAL_ERROR': FirebaseAuthException.internalError().replace(
                message:
                    '{"error":{"errors":[{"message":"INTERNAL_ERROR"}],"code":400,"message":"INTERNAL_ERROR"}}')
          });
        });

        test('getAuthUri: error no auth uri', () async {
          var t = tester.replace(
            expectedBody: {
              'identifier': 'user@example.com',
              'providerId': 'google.com',
              'continueUri': 'http://localhost/widget',
              'customParameter': expectedCustomParameters,
              'oauthScope': json.encode({'google.com': 'scope1,scope2,scope3'})
            },
            action: () => rpcHandler.getAuthUri(
                'google.com',
                'http://localhost/widget',
                expectedCustomParameters,
                ['scope1', 'scope2', 'scope3'],
                'user@example.com'),
          );
          await t.shouldFail(
            serverResponse: {
              'providerId': 'google.com',
              'registered': true,
              'forExistingProvider': true,
              'sessionId': 'SESSION_ID'
            },
            expectedError: FirebaseAuthException.internalError().replace(
                message:
                    'Unable to determine the authorization endpoint for the specified '
                    'provider. This may be an issue in the provider configuration.'),
          );
        });
      });

      group('sendVerificationCode', () {
        var tester = Tester(
          path: 'accounts:sendVerificationCode',
          expectedBody: {
            'phoneNumber': '15551234567',
            'recaptchaToken': 'RECAPTCHA_TOKEN'
          },
          expectedResult: (_) => 'SESSION_INFO',
          action: () => rpcHandler.sendVerificationCode(
              phoneNumber: '15551234567', recaptchaToken: 'RECAPTCHA_TOKEN'),
        );
        test('sendVerificationCode: success', () async {
          await tester.shouldSucceed(
            serverResponse: {'sessionInfo': 'SESSION_INFO'},
          );
        });

        test('sendVerificationCode: invalid request missing phone number',
            () async {
          expect(
              () => rpcHandler.sendVerificationCode(
                  recaptchaToken: 'RECAPTCHA_TOKEN'),
              throwsA(FirebaseAuthException.internalError()));
        });

        test('sendVerificationCode: invalid request missing recaptcha token',
            () async {
          expect(
              () => rpcHandler.sendVerificationCode(phoneNumber: '15551234567'),
              throwsA(FirebaseAuthException.internalError()));
        });

        test('sendVerificationCode: unknown server response', () async {
          await tester.shouldFail(
            // No sessionInfo returned.
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('sendVerificationCode: caught server error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'CAPTCHA_CHECK_FAILED': FirebaseAuthException.captchaCheckFailed(),
            'INVALID_APP_CREDENTIAL':
                FirebaseAuthException.invalidAppCredential(),
            'INVALID_PHONE_NUMBER': FirebaseAuthException.invalidPhoneNumber(),
            'MISSING_APP_CREDENTIAL':
                FirebaseAuthException.missingAppCredential(),
            'MISSING_PHONE_NUMBER': FirebaseAuthException.missingPhoneNumber(),
            'QUOTA_EXCEEDED': FirebaseAuthException.quotaExceeded(),
            'REJECTED_CREDENTIAL': FirebaseAuthException.rejectedCredential(),
          });
        });
      });

      group('signInWithPhoneNumber', () {
        // Token response with expiresIn.
        var tokenResponseWithExpiresIn = {
          'idToken': createMockJwt(uid: 'uid123', providerId: 'phone'),
          'refreshToken': 'refreshToken',
          'expiresIn': '3600'
        };

        var tester = Tester(
          path: 'accounts:signInWithPhoneNumber',
          expectedBody: {'sessionInfo': 'SESSION_INFO', 'code': '123456'},
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .signInWithPhoneNumber(
                  sessionInfo: 'SESSION_INFO', code: '123456')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );

        group('signInWithPhoneNumber: using code', () {
          test('signInWithPhoneNumber: success using code', () async {
            // Tests successful signInWithPhoneNumber RPC call using an SMS code.

            await tester.shouldSucceed(
              serverResponse: tokenResponseWithExpiresIn,
            );
          });

          test('signInWithPhoneNumber: success custom locale using code',
              () async {
            // Tests successful signInWithPhoneNumber RPC call using an SMS code and passing
            // custom locale.
            httpClient.locale = 'ru';
            await tester.shouldSucceed(
                serverResponse: tokenResponseWithExpiresIn,
                expectedHeaders: {
                  'Content-Type': 'application/json',
                  'X-Firebase-Locale': 'ru'
                });
          });
          test('signInWithPhoneNumber: invalid request missing session info',
              () async {
            expect(() => rpcHandler.signInWithPhoneNumber(code: '123456'),
                throwsA(FirebaseAuthException.missingSessionInfo()));
          });
          test('signInWithPhoneNumber: invalid request missing code', () async {
            expect(
                () => rpcHandler.signInWithPhoneNumber(
                    sessionInfo: 'SESSION_INFO'),
                throwsA(FirebaseAuthException.missingCode()));
          });
          test('signInWithPhoneNumber: unknown server response', () async {
            await tester.shouldFail(
              serverResponse: {},
              expectedError: FirebaseAuthException.internalError(),
            );
          });

          test('signInWithPhoneNumber: caught server error', () async {
            await tester.shouldFailWithServerErrors(errorMap: {
              'INVALID_CODE': FirebaseAuthException.invalidCode(),
              'INVALID_SESSION_INFO':
                  FirebaseAuthException.invalidSessionInfo(),
              'INVALID_TEMPORARY_PROOF':
                  FirebaseAuthException.invalidIdpResponse(),
              'MISSING_CODE': FirebaseAuthException.missingCode(),
              'MISSING_SESSION_INFO':
                  FirebaseAuthException.missingSessionInfo(),
              'SESSION_EXPIRED': FirebaseAuthException.codeExpired(),
              'REJECTED_CREDENTIAL': FirebaseAuthException.rejectedCredential(),
            });
          });
        });

        group('signInWithPhoneNumber: using temporary proof', () {
          var t = tester.replace(
            expectedBody: {
              'phoneNumber': '16505550101',
              'temporaryProof': 'TEMPORARY_PROOF'
            },
            action: () => rpcHandler
                .signInWithPhoneNumber(
                    phoneNumber: '16505550101',
                    temporaryProof: 'TEMPORARY_PROOF')
                .then((v) => {'id_token': v.credential.response!['id_token']}),
          );
          test('signInWithPhoneNumber: success using temporary proof',
              () async {
            // Tests successful signInWithPhoneNumber RPC call using a temporary proof.
            await t.shouldSucceed(
              serverResponse: tokenResponseWithExpiresIn,
            );
          });

          test('signInWithPhoneNumber: error no phone number', () async {
            expect(
                () => rpcHandler.signInWithPhoneNumber(
                    temporaryProof: 'TEMPORARY_PROOF'),
                throwsA(FirebaseAuthException.internalError()));
          });
          test('signInWithPhoneNumber: error no temporary proof', () async {
            expect(
                () => rpcHandler.signInWithPhoneNumber(
                    phoneNumber: '16505550101'),
                throwsA(FirebaseAuthException.internalError()));
          });
        });
      });

      group('signInWithPhoneNumberForLinking', () {
        // Token response with expiresIn.
        var tokenResponseWithExpiresIn = {
          'idToken': createMockJwt(uid: 'uid123', providerId: 'phone'),
          'refreshToken': 'refreshToken',
          'expiresIn': '3600'
        };

        var tester = Tester(
          path: 'accounts:signInWithPhoneNumber',
          expectedBody: {
            'sessionInfo': 'SESSION_INFO',
            'code': '123456',
            'idToken': 'ID_TOKEN'
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .signInWithPhoneNumberForLinking(
                  idToken: 'ID_TOKEN',
                  sessionInfo: 'SESSION_INFO',
                  code: '123456')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );
        test('signInWithPhoneNumberForLinking: success using code', () async {
          await tester.shouldSucceed(
            serverResponse: tokenResponseWithExpiresIn,
          );
        });

        test(
            'signInWithPhoneNumberForLinking: invalid request missing session info',
            () async {
          expect(
              () => rpcHandler.signInWithPhoneNumberForLinking(
                  code: '123456', idToken: 'ID_TOKEN'),
              throwsA(FirebaseAuthException.missingSessionInfo()));
        });

        test('signInWithPhoneNumberForLinking: invalid request missing code',
            () async {
          expect(
              () => rpcHandler.signInWithPhoneNumberForLinking(
                  sessionInfo: 'SESSION_INFO', idToken: 'ID_TOKEN'),
              throwsA(FirebaseAuthException.missingCode()));
        });

        test(
            'signInWithPhoneNumberForLinking: invalid request missing id token',
            () async {
          expect(
              () => rpcHandler.signInWithPhoneNumberForLinking(
                  sessionInfo: 'SESSION_INFO', code: '123456'),
              throwsA(FirebaseAuthException.internalError()));
        });

        test('signInWithPhoneNumberForLinking: unknown server response',
            () async {
          await tester.shouldFail(
            serverResponse: {},
            expectedError: FirebaseAuthException.internalError(),
          );
        });

        test('signInWithPhoneNumberForLinking: caught server error', () async {
          await tester.shouldFailWithServerErrors(errorMap: {
            'INVALID_CODE': FirebaseAuthException.invalidCode(),
            'INVALID_SESSION_INFO': FirebaseAuthException.invalidSessionInfo(),
            'INVALID_TEMPORARY_PROOF':
                FirebaseAuthException.invalidIdpResponse(),
            'MISSING_CODE': FirebaseAuthException.missingCode(),
            'MISSING_SESSION_INFO': FirebaseAuthException.missingSessionInfo(),
            'SESSION_EXPIRED': FirebaseAuthException.codeExpired(),
          });
        });

        test('signInWithPhoneNumberForLinking: credential already in use error',
            () async {
          await tester.shouldFail(
            serverResponse: {
              'temporaryProof': 'theTempProof',
              'phoneNumber': '16505550101'
            },
            expectedError: FirebaseAuthException.credentialAlreadyInUse()
                .replace(
                    phoneNumber: '16505550101',
                    credential: PhoneAuthProvider.credentialFromTemporaryProof(
                        temporaryProof: 'theTempProof',
                        phoneNumber: '16505550101')),
          );
        });
      });

      group('signInWithPhoneNumberForExisting', () {
        // Token response with expiresIn.
        var tokenResponseWithExpiresIn = {
          'idToken': createMockJwt(uid: 'uid123', providerId: 'phone'),
          'refreshToken': 'refreshToken',
          'expiresIn': '3600'
        };

        var tester = Tester(
          path: 'accounts:signInWithPhoneNumber',
          expectedBody: {
            'sessionInfo': 'SESSION_INFO',
            'code': '123456',
            'operation': 'REAUTH'
          },
          expectedResult: (response) {
            return {'id_token': response['idToken']};
          },
          action: () => rpcHandler
              .signInWithPhoneNumberForExisting(
                  sessionInfo: 'SESSION_INFO', code: '123456')
              .then((v) => {'id_token': v.credential.response!['id_token']}),
        );

        group('signInWithPhoneNumberForExisting: using code', () {
          test('signInWithPhoneNumberForExisting: success using code',
              () async {
            await tester.shouldSucceed(
              serverResponse: tokenResponseWithExpiresIn,
            );
          });

          test(
              'signInWithPhoneNumberForExisting: invalid request missing session info',
              () async {
            expect(
                () => rpcHandler.signInWithPhoneNumberForExisting(
                      code: '123456',
                    ),
                throwsA(FirebaseAuthException.missingSessionInfo()));
          });

          test('signInWithPhoneNumberForExisting: invalid request missing code',
              () async {
            expect(
                () => rpcHandler.signInWithPhoneNumberForExisting(
                      sessionInfo: 'SESSION_INFO',
                    ),
                throwsA(FirebaseAuthException.missingCode()));
          });

          test('signInWithPhoneNumberForExisting: unknown server response',
              () async {
            await tester.shouldFail(
              serverResponse: {},
              expectedError: FirebaseAuthException.internalError(),
            );
          });

          test('signInWithPhoneNumberForExisting: caught server error',
              () async {
            await tester.shouldFailWithServerErrors(errorMap: {
              // This should be overridden from the default error mapping.
              'USER_NOT_FOUND': FirebaseAuthException.userDeleted(),
              'INVALID_CODE': FirebaseAuthException.invalidCode(),
              'INVALID_SESSION_INFO':
                  FirebaseAuthException.invalidSessionInfo(),
              'INVALID_TEMPORARY_PROOF':
                  FirebaseAuthException.invalidIdpResponse(),
              'MISSING_CODE': FirebaseAuthException.missingCode(),
              'MISSING_SESSION_INFO':
                  FirebaseAuthException.missingSessionInfo(),
              'SESSION_EXPIRED': FirebaseAuthException.codeExpired(),
            });
          });
        });

        group('signInWithPhoneNumberForExisting: using temporary proof', () {
          var t = tester.replace(
            expectedBody: {
              'phoneNumber': '16505550101',
              'temporaryProof': 'TEMPORARY_PROOF',
              'operation': 'REAUTH'
            },
            action: () => rpcHandler
                .signInWithPhoneNumberForExisting(
                    temporaryProof: 'TEMPORARY_PROOF',
                    phoneNumber: '16505550101')
                .then((v) => {'id_token': v.credential.response!['id_token']}),
          );
          test(
              'signInWithPhoneNumberForExisting: success using temporary proof',
              () async {
            await t.shouldSucceed(
              serverResponse: tokenResponseWithExpiresIn,
            );
          });

          test(
              'signInWithPhoneNumberForExisting: invalid request missing phone number',
              () async {
            expect(
                () => rpcHandler.signInWithPhoneNumberForExisting(
                      temporaryProof: 'TEMPORARY_PROOF',
                    ),
                throwsA(FirebaseAuthException.internalError()));
          });

          test(
              'signInWithPhoneNumberForExisting: invalid request missing temp proof',
              () async {
            expect(
                () => rpcHandler.signInWithPhoneNumberForExisting(
                      phoneNumber: '16505550101',
                    ),
                throwsA(FirebaseAuthException.internalError()));
          });
        });
      });

      group('Send Firebase backend request', () {
        var identifier = 'user@example.com';
        var tester = Tester(
          path: 'accounts:createAuthUri',
          expectedBody: {
            'identifier': identifier,
            'continueUri': platform.currentUrl
          },
          expectedResult: (_) => ['google.com', 'myauthprovider.com'],
          action: () => rpcHandler.fetchProvidersForIdentifier(identifier),
        );
        test('Send Firebase backend request: timeout', () async {
          fakeAsync((fake) {
            tester.shouldFail(
              serverResponse: Future.delayed(Duration(days: 1), () => {}),
              expectedError: FirebaseAuthException.networkRequestFailed(),
            );

            // This will cause the timeout above to fire immediately, without waiting
            // 5 seconds of real time.
            fake.elapse(Duration(minutes: 1));
          });
        });

        group('Send Firebase backend request: offline', () {
          setUp(() {
            initPlatform(platform = Platform.web(
                currentUrl: 'http://localhost',
                isOnline: false,
                isMobile: true) as WebPlatform);
          });
          test('Send Firebase backend request: offline false alert', () async {
            fakeAsync((fake) {
              tester.shouldSucceed(
                serverResponse: Future.delayed(
                    Duration(milliseconds: 4999),
                    () => {
                          'authUri':
                              'https://accounts.google.com/o/oauth2/auth?foo=bar',
                          'providerId': 'google.com',
                          'allProviders': ['google.com', 'myauthprovider.com'],
                          'registered': true,
                          'forExistingProvider': true,
                          'sessionId': 'MY_SESSION_ID'
                        }),
              );

              fake.elapse(Duration(minutes: 1));
            });
          });
          test('Send Firebase backend request: offline slow response',
              () async {
            fakeAsync((fake) {
              tester.shouldFail(
                serverResponse: Future.delayed(
                    Duration(milliseconds: 5001),
                    () => {
                          'authUri':
                              'https://accounts.google.com/o/oauth2/auth?foo=bar',
                          'providerId': 'google.com',
                          'allProviders': ['google.com', 'myauthprovider.com'],
                          'registered': true,
                          'forExistingProvider': true,
                          'sessionId': 'MY_SESSION_ID'
                        }),
                expectedError: FirebaseAuthException.networkRequestFailed(),
              );

              fake.elapse(Duration(minutes: 1));
            });
          });
        });
      });
    });
  });
}
