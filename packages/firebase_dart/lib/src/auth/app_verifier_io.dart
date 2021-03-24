import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_dart/src/auth/auth.dart';

import 'app_verifier.dart';
import 'impl/auth.dart';

class RecaptchaVerifier extends BaseRecaptchaVerifier {
  @override
  String get type => 'recaptcha';

  final Completer<String> _completer = Completer();

  Future<HttpServer> _startServer(int port, String content) {
    return (HttpServer.bind(InternetAddress.loopbackIPv4, port)
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

  @override
  Future<String> verify(FirebaseAuth auth) async {
    var siteKey = await getRecaptchaParameters(auth as FirebaseAuthImpl);
    var html = '''
<html>
  <head>
    <title>reCAPTCHA demo: Simple page</title>
    <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  </head>
  <body>
    <form action="?" method="POST">
      <div class="g-recaptcha" data-sitekey="$siteKey"></div>
      <br/>
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
  ''';
    var s = await _startServer(1111, html);
    _runBrowser('http://localhost:1111');

    try {
      return await _completer.future;
    } finally {
      await s.close();
    }
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
