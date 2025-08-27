import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/deep_link_retriever.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';
import 'package:logging/logging.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:platform_info/platform_info.dart' as platform_info;

import 'channel.dart';

class FlutterApplicationVerifier extends BaseApplicationVerifier {
  final bool usePlayIntegrity;

  final bool useApns;

  final BuildContext? Function()? getBuildContext;

  FlutterApplicationVerifier(
      {this.usePlayIntegrity = true,
      this.useApns = true,
      this.getBuildContext});

  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<String>? _lastRecaptchaResult;

  late final Future<bool> _isGooglePlayServicesAvailable = Future(() async {
    if (kIsWeb || !platform_info.Platform.instance.android) return false;
    return await channel.invokeMethod<bool>('isGooglePlayServicesAvailable') ??
        false;
  });

  @override
  Future<String> getVerifyResult(FirebaseApp app) {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await getResult('getVerifyResult');
        _lastRecaptchaResult = null;

        return Uri.parse(v['link']!).queryParameters['recaptchaToken']!;
      });
    } else if (!kIsWeb) {
      return _lastRecaptchaResult ??= Future(() async {
        var v = await _deepLinkRetriever.getDeepLinkResult();
        _lastRecaptchaResult = null;

        return v['recaptchaToken']!;
      });
    }
    throw UnimplementedError();
  }

  @override
  Future<String?> verifyWithApns(FirebaseAuth auth) async {
    if (!useApns) return null;
    try {
      var apns = ApnsPushConnectorOnly();

      var completer = Completer<String>();
      apns.configureApns(
        onMessage: (message) async {
          var v =
              json.decode(message.payload['data']['com.google.firebase.auth']);

          completer.complete('${v['receipt']}:${v['secret']}');
        },
      );

      var tokenCompleter = Completer<String>();
      if (apns.token.value != null) {
        tokenCompleter.complete(apns.token.value);
      } else {
        apns.token.addListener(() async {
          if (tokenCompleter.isCompleted) return;
          tokenCompleter.complete(apns.token.value);
        });
      }

      var defaultTimeout = const Duration(seconds: 5);
      var s = await apns.getAuthorizationStatus().timeout(defaultTimeout);
      if (s != ApnsAuthorizationStatus.authorized) {
        if (!await apns.requestNotificationPermissions()) {
          return null;
        }
      }

      var timeout = await verifyIosClient(auth,
              appToken: await tokenCompleter.future.timeout(defaultTimeout),
              isSandbox: !kReleaseMode)
          .timeout(defaultTimeout);

      return await completer.future.timeout(timeout);
    } catch (e, tr) {
      Logger('firebase_dart_flutter')
          .warning('Failed verifying with APNS', e, tr);
      return null;
    }
  }

  @override
  Future<String?> verifyWithPlayIntegrity(
      FirebaseAuth auth, String nonce) async {
    if (!usePlayIntegrity) return null;
    var available = await _isGooglePlayServicesAvailable;
    if (!available) return null;

    try {
      var n = base64Url.encode(sha256.convert(nonce.codeUnits).bytes);
      var token = await channel.invokeMethod<String>('requestIntegrityToken', {
        'projectNumber': await getProducerProjectNumber(auth),
        'nonce': n,
      });
      return token!;
    } catch (e, tr) {
      Logger('firebase_dart_flutter')
          .warning('Failed getting SafetyNet token', e, tr);
      return null;
    }
  }

  @override
  Future<ApplicationVerificationResult> verify(FirebaseAuth auth, String nonce,
      {bool forceRecaptcha = false}) {
    if (kIsWeb) {
      return const RecaptchaApplicationVerifier()
          .verify(auth, nonce, forceRecaptcha: forceRecaptcha);
    }
    return super.verify(auth, nonce, forceRecaptcha: forceRecaptcha);
  }

  @override
  Future<String> verifyWithRecaptcha(FirebaseAuth auth) async {
    if (getBuildContext != null) {
      var context = getBuildContext!();

      if (context != null && context.mounted) {
        var overlay = Overlay.maybeOf(context, rootOverlay: true);
        if (overlay == null) {
          Iterable<BuildContext>
              findRootChildrenWithWidgetOfType<T extends Widget>(
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

        if (overlay != null) {
          var siteKey =
              await (auth as dynamic).rpcHandler.getRecaptchaSiteKey();
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
                    baseUrl:
                        'http://${auth.app.options.authDomain ?? '127.0.0.1:8080'}',
                  ));
          overlay.insert(entry);
          var token = await completer.future;
          if (token != null) return token;
          throw Exception();
        }
      }
    }
    return super.verifyWithRecaptcha(auth);
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
    await _controller.loadHtmlString(_getHtml(widget.siteKey),
        baseUrl: widget.baseUrl);
    await _controller.addJavaScriptChannel('dart',
        onMessageReceived: (message) {
      widget.onToken(message.message.isEmpty ? null : message.message);
    });
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
