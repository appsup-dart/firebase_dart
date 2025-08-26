import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core.dart';
import 'auth.dart';
import 'impl/auth.dart';

class RecaptchaVerifierImpl implements RecaptchaVerifier {
  final String _appId;

  final String? container;

  final RecaptchaVerifierSize size;

  final RecaptchaVerifierTheme theme;

  final RecaptchaVerifierOnSuccess? onSuccess;

  final RecaptchaVerifierOnError? onError;

  final RecaptchaVerifierOnExpired? onExpired;

  final Completer<String> _completer = Completer();

  RecaptchaVerifierImpl({
    required FirebaseAuth auth,
    this.container,
    this.size = RecaptchaVerifierSize.normal,
    this.theme = RecaptchaVerifierTheme.light,
    this.onSuccess,
    this.onError,
    this.onExpired,
  }) : _appId = auth.app.name;

  FirebaseAuth get auth => FirebaseAuth.instanceFor(app: Firebase.app(_appId));

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
    var siteKey =
        await (auth as FirebaseAuthImpl).rpcHandler.getRecaptchaSiteKey();
    var html = '''
<html>
  <head>
    <title>reCAPTCHA demo: Simple page</title>
    <script>
      var onloadCallback = function() {
        var widgetId = grecaptcha.render('recaptcha', {
          sitekey: '$siteKey',
          size: 'invisible',
          theme: 'light',
          callback: function(token) {
            fetch('', {
              method: 'POST',
              body: 'g-recaptcha-response=' + token
            });
          },
          expiredCallback: function() {
            console.log('expired-callback');
          },
          errorCallback: function(error) {
            console.log('error-callback', error);
          }
        });
        grecaptcha.execute(widgetId);
      };
    </script>
    <script src="https://www.google.com/recaptcha/api.js?render=explicit&onload=onloadCallback&sitekey=$siteKey" async defer></script>
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
              _completer.complete(v['g-recaptcha-response']);
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
