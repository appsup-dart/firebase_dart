import 'dart:async';

import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaWebViewVerifier {
  final BuildContext context;

  final String siteKey;

  final String baseUrl;

  final String? action;

  RecaptchaWebViewVerifier(
      {required this.context,
      required this.siteKey,
      required this.baseUrl,
      this.action});

  Future<String> verify() async {
    var overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      Iterable<BuildContext> findRootChildrenWithWidgetOfType<T extends Widget>(
          BuildContext context) sync* {
        var elements = <BuildContext>[context];

        while (elements.isNotEmpty) {
          var v = elements.removeAt(0);

          if (v.widget is T) {
            yield v;
          } else {
            v.visitChildElements((v) => elements.add(v));
          }
        }
      }

      var children =
          findRootChildrenWithWidgetOfType<Overlay>(context).toList();
      children.sort((a, b) {
        var aRect = a.findRenderObject()?.paintBounds;
        var bRect = b.findRenderObject()?.paintBounds;
        if (aRect == bRect) return 0;
        if (aRect == null) return 1;
        if (bRect == null) return -1;
        var aSize = aRect.width * aRect.height;
        var bSize = bRect.width * bRect.height;
        return aSize.compareTo(bSize);
      });

      overlay = (children.last as StatefulElement).state as OverlayState?;
    }

    if (overlay == null) throw Exception('No overlay found');

    late OverlayEntry entry;
    Completer<String?> completer = Completer();

    entry = OverlayEntry(
        opaque: false,
        builder: (context) => RecaptchaWidget(
              siteKey: siteKey,
              onToken: (token) {
                entry.remove();
                completer.complete(token);
              },
              onError: (error) {
                entry.remove();
                completer.completeError(error);
              },
              baseUrl: baseUrl,
              action: action,
            ));
    overlay.insert(entry);
    var token = await completer.future;
    if (token != null) return token;
    throw Exception();
  }
}

class RecaptchaWidget extends StatefulWidget {
  final String siteKey;

  final String baseUrl;

  final Function(String) onToken;

  final Function(Object) onError;

  final String? action;

  const RecaptchaWidget(
      {super.key,
      required this.siteKey,
      required this.onToken,
      required this.onError,
      this.action,
      this.baseUrl = 'http://127.0.0.1:8080'});

  @override
  State<RecaptchaWidget> createState() => _RecaptchaWidgetState();
}

class _RecaptchaWidgetState extends State<RecaptchaWidget> {
  String _getHtml(String siteKey) {
    var onloadCallback = widget.action == null
        ? '''
      var widgetId = grecaptcha.enterprise.render('recaptcha', {
        sitekey: '$siteKey',
        size: 'invisible',
        theme: 'light',
        callback: async function(token) {
          console.log('callback', token);
          dart.postMessage('g-recaptcha-response=' + token);
          window.close();
        },
        'expired-callback': async function() {
          console.log('expired-callback');
          dart.postMessage('g-recaptcha-error=expired');
          window.close();
        },
        'error-callback': async function() {
          console.log('error-callback');
          dart.postMessage('g-recaptcha-error=error');
          window.close();
        }
      });

      await grecaptcha.enterprise.execute(widgetId);
    '''
        : '''
      try {
        var token = await grecaptcha.enterprise.execute('$siteKey', {
          action: '${widget.action}'
        });
        dart.postMessage('g-recaptcha-response=' + token);
        window.close();
      } catch (e) {
        console.log('error', e);
        dart.postMessage('g-recaptcha-error=error&error=' + encodeURIComponent(e.message));
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
    <script src="https://www.google.com/recaptcha/enterprise.js?render=${widget.action == null ? 'explicit' : siteKey}&onload=onloadCallback" async defer></script>
  </head>
  <body>
    <div id="recaptcha"></div>
  </body>
</html>
  ''';
    return html;
  }

  final WebViewController _controller = WebViewController();

  Future<void> _prepareController() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (!kIsWeb && Platform.current is! MacOsPlatform) {
      await _controller.setBackgroundColor(Colors.black45);
    }
    await _controller.addJavaScriptChannel('dart',
        onMessageReceived: (message) {
      var v = Uri.splitQueryString(message.message);
      if (v['g-recaptcha-error'] != null) {
        widget.onError(FirebaseAuthException(
            'recaptcha-${v['g-recaptcha-error']}', v['error']));
      } else {
        widget.onToken(v['g-recaptcha-response']!);
      }
    });
    await _controller.loadHtmlString(
      _getHtml(widget.siteKey),
      baseUrl: widget.baseUrl,
    );
  }

  @override
  void initState() {
    super.initState();
    _prepareController();
  }

  @override
  void didUpdateWidget(covariant RecaptchaWidget oldWidget) {
    if (oldWidget.siteKey != widget.siteKey) {
      _prepareController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
