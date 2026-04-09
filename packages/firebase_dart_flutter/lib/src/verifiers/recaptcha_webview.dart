import 'dart:async';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaWebViewVerifier {
  final BuildContext context;

  final String siteKey;

  final String baseUrl;

  RecaptchaWebViewVerifier(
      {required this.context, required this.siteKey, required this.baseUrl});

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
              baseUrl: baseUrl,
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

  final Function(String?) onToken;

  const RecaptchaWidget(
      {super.key,
      required this.siteKey,
      required this.onToken,
      this.baseUrl = 'http://127.0.0.1:8080'});

  @override
  State<RecaptchaWidget> createState() => _RecaptchaWidgetState();
}

class _RecaptchaWidgetState extends State<RecaptchaWidget> {
  static String _getHtml(String siteKey) => '''
    <html>
      <head>
        <meta name="viewport" 
              content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      
        <script>
            var onSubmit = function(token) {
              dart.postMessage(token);
            };

            var onloadCallback = function() {
              grecaptcha.execute();
            };

            var onDismiss = function() {
              dart.postMessage('');
            };
        </script>
        <script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback" async defer></script>
      </head>
      <body onclick="onDismiss()">
        <div class="g-recaptcha"
              data-sitekey="$siteKey"
              data-callback="onSubmit"
              data-size="invisible">
        </div>
      </body>
    </html>''';

  final WebViewController _controller = WebViewController();

  Future<void> _prepareController() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (!kIsWeb && Platform.current is! MacOsPlatform) {
      await _controller.setBackgroundColor(Colors.black45);
    }
    await _controller.addJavaScriptChannel('dart',
        onMessageReceived: (message) {
      widget.onToken(message.message.isEmpty ? null : message.message);
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
