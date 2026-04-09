import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart_flutter/src/channel.dart';
import 'package:firebase_dart_flutter/src/deep_link_retriever.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

class RecaptchaRedirectVerifier {
  final FirebaseApp app;

  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<String>? _lastRecaptchaResult;

  RecaptchaRedirectVerifier({required this.app});

  Future<String> verify() async {
    var url = FirebaseAppAuthHandler.createAuthHandlerUrl(
      app: app,
      authType: 'verifyApp',
    );

    FirebaseDart.instance.launchUrl(url);

    return getVerifyResult();
  }

  Future<String> getVerifyResult() {
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
}
