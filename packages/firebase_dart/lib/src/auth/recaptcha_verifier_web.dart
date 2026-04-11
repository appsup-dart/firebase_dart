import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:math';
import 'package:web/web.dart';

import 'error.dart';
import 'grecaptcha.dart' as grecaptcha;
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

  int? widgetId;

  Element? _element;

  Completer<String>? _completer;

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
  void clear() {
    if (widgetId != null) {
      grecaptcha.reset(widgetId!);
      widgetId = null;
      _completer = null;
      _element?.remove();
    }
  }

  @override
  Future<int> render() async {
    await RecaptchaLoader().load(render: action == null ? 'explicit' : siteKey);
    if (action != null) {
      return -1;
    }
    if (widgetId == null) {
      var element = container == null
          ? document.body!
          : document.getElementById(container!)!;
      var guaranteedEmpty = document.createElement('div')..id = 'recaptcha';
      element.appendChild(guaranteedEmpty);
      _element = element = guaranteedEmpty;

      _completer = Completer();

      int? newWidgetId;

      newWidgetId = grecaptcha.render(
          element,
          grecaptcha.GRecaptchaParameters(
              callback: (String? v) {
                if (newWidgetId != widgetId) return;
                if (onSuccess != null) onSuccess!();
                _completer!.complete(v);
              }.toJS,
              errorCallback: () {
                var e = FirebaseAuthException('recaptcha-error');
                if (onError != null) onError!(e);
                _completer!.completeError(e);
              }.toJS,
              expiredCallback: () {
                if (onExpired != null) onExpired!();
                _completer!
                    .completeError(FirebaseAuthException('recaptcha-expired'));
              }.toJS,
              size: container == null ? 'invisible' : size.name,
              theme: theme.name,
              sitekey: siteKey));
      widgetId = newWidgetId;
    }

    return widgetId!;
  }

  @override
  String get type => 'recaptcha';

  @override
  Future<String> verify() async {
    if (action != null) {
      await RecaptchaLoader().load(render: siteKey);
      try {
        var token = (await grecaptcha
                .executeScore(siteKey,
                    grecaptcha.GRecaptchaExecuteOptions(action: action!))
                .toDart)
            .toDart;
        if (onSuccess != null) onSuccess!();
        return token;
      } on JSObject catch (error) {
        var message = error.getProperty<JSString>('message'.toJS).toDart;
        var e = FirebaseAuthException('recaptcha-error', message);
        if (onError != null) onError!(e);
        throw e;
      }
    }

    if (widgetId == null) {
      await render();
    }
    if (container == null) {
      grecaptcha.execute(widgetId!);
    }

    return _completer!.future.whenComplete(() => clear());
  }
}

class RecaptchaLoader {
  static final _instance = RecaptchaLoader._();

  String? _hostLanguage;
  String? _render;

  Future<void>? _loadFuture;

  RecaptchaLoader._();

  factory RecaptchaLoader() => _instance;

  bool _isHostLanguageValid(String hl) {
    return hl.length <= 6 && RegExp(r'^\s*[a-zA-Z0-9\-]*\s*$').hasMatch(hl);
  }

  Future<void> load({String hl = '', String render = 'explicit'}) {
    if (!_isHostLanguageValid(hl)) {
      throw FirebaseAuthException.argumentError('Invalid hl parameter value.');
    }

    if (_hostLanguage == hl && _render == render) {
      return _loadFuture!;
    }

    var completer = Completer<void>();

    var r = Random();

    var name = '_gonload${r.nextInt(1000000)}';
    var script = HTMLScriptElement()
      ..src = Uri.parse('https://www.google.com/recaptcha/enterprise.js')
          .replace(queryParameters: {
        'render': render,
        'onload': name,
        if (hl.isNotEmpty) 'hl': hl,
      }).toString()
      ..async = true;

    globalContext.setProperty(
        name.toJS,
        () {
          completer.complete();
        }.toJS);

    document.body!.append(script);

    _hostLanguage = hl;
    _render = render;
    return _loadFuture = completer.future;
  }
}
