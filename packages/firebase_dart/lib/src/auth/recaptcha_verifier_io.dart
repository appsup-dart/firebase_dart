import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'error.dart';
import 'recaptcha_verifier.dart';

class RecaptchaVerifierImpl implements RecaptchaVerifier {
  final String siteKey;
  final String? action;

  final String? container;

  final RecaptchaVerifierSize size;

  final RecaptchaVerifierTheme theme;

  final RecaptchaVerifierOnSuccess? onSuccess;

  final RecaptchaVerifierOnError? onError;

  final RecaptchaVerifierOnExpired? onExpired;

  final Completer<String> _completer = Completer();

  RecaptchaVerifierImpl({
    required this.siteKey,
    this.action,
    this.container,
    this.size = RecaptchaVerifierSize.normal,
    this.theme = RecaptchaVerifierTheme.light,
    this.onSuccess,
    this.onError,
    this.onExpired,
  });

  @override
  void clear() {}

  @override
  Future<int> render() async {
    return 0;
  }

  @override
  String get type => 'recaptcha';

  @override
  Future<String> verify() async {
    var onloadCallback = action == null
        ? '''
      var widgetId = grecaptcha.enterprise.render('recaptcha', {
        sitekey: '$siteKey',
        size: 'invisible',
        theme: 'light',
        callback: async function(token) {
          console.log('callback', token);
          await fetch('', {
            method: 'POST',
            body: 'g-recaptcha-response=' + token
          });
          window.close();
        },
        'expired-callback': async function() {
          console.log('expired-callback');
          await fetch('', {
            method: 'POST',
            body: 'g-recaptcha-error=expired'
          });
          window.close();
        },
        'error-callback': async function() {
          console.log('error-callback');
          await fetch('', {
            method: 'POST',
            body: 'g-recaptcha-error=error'
          });
          window.close();
        }
      });

      await grecaptcha.enterprise.execute(widgetId);
    '''
        : '''
      try {
        var token = await grecaptcha.enterprise.execute('$siteKey', {
          action: '$action'
        });
        await fetch('', {
          method: 'POST',
          body: 'g-recaptcha-response=' + token
        });
        window.close();
      } catch (e) {
        console.log('error', e);
        await fetch('', {
          method: 'POST',
          body: 'g-recaptcha-error=error&error=' + encodeURIComponent(e.message)
        });
        window.close();
      }
    ''';

    var html = '''
<html>
  <head>
    <title>reCAPTCHA demo: Simple page</title>
    <script>
      var onloadCallback = async function() {
        $onloadCallback
      };
    </script>
    <script src="https://www.google.com/recaptcha/enterprise.js?render=${action == null ? 'explicit' : siteKey}&onload=onloadCallback" async defer></script>
  </head>
  <body>
    <div id="recaptcha"></div>
  </body>
</html>
  ''';
    var s = await _startServer(1111, html);
    _runBrowser('http://127.0.0.1:1111');

    try {
      return await _completer.future;
    } finally {
      await s.close();
    }
  }

  Future<HttpServer> _startServer(int port, String content) {
    return (HttpServer.bind(InternetAddress('127.0.0.1'), port)
      ..then((requestServer) async {
        await for (var request in requestServer) {
          request.response.statusCode = 200;
          request.response.headers.set('Content-type', 'text/html');

          switch (request.method) {
            case 'POST':
              var body = await request.map(utf8.decode).join();
              var v = Uri.splitQueryString(body);
              if (v['g-recaptcha-error'] != null) {
                _completer.completeError(FirebaseAuthException(
                    'recaptcha-${v['g-recaptcha-error']}', v['error']));
              } else {
                _completer.complete(v['g-recaptcha-response']);
              }
              break;
            case 'GET':
            default:
              request.response.writeln(content);
          }

          await request.response.close();
        }
      }));
  }

  void _runBrowser(String url) {
    switch (Platform.operatingSystem) {
      case 'linux':
        Process.run('x-www-browser', [url]);
        break;
      case 'macos':
        Process.run('open', [url]);
        break;
      case 'windows':
        Process.run('explorer', [url]);
        break;
      default:
        throw UnsupportedError(
            'Unsupported platform: ${Platform.operatingSystem}');
    }
  }
}
