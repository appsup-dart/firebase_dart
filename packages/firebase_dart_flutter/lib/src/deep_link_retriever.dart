import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:firebase_dart/auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

class DeepLinkRetriever with WidgetsBindingObserver {
  final StreamController<Uri> _controller = StreamController.broadcast();

  DeepLinkRetriever._() {
    if (!kIsWeb && !platform_info.Platform.instance.mobile) {
      AppLinks().uriLinkStream.listen((uri) {
        didPushRouteInformation(RouteInformation(uri: uri));
      });
    } else {
      WidgetsFlutterBinding.ensureInitialized().addObserver(this);
    }
  }

  static final DeepLinkRetriever instance = DeepLinkRetriever._();

  @override
  Future<bool> didPushRouteInformation(
      RouteInformation routeInformation) async {
    var uri = routeInformation.uri;

    if (uri.host != 'firebaseauth') return false;
    var deepLink = Uri.parse(uri.queryParameters['deep_link_id']!);

    _controller.add(deepLink);

    return true;
  }

  Future<Map<String, String>> getDeepLinkResult() async {
    var deepLink = await _controller.stream.first;

    var v = deepLink.queryParameters;

    Map<String, dynamic>? error =
        v['firebaseError'] == null ? null : json.decode(v['firebaseError']!);
    if (error != null) {
      var code = error['code'] as String;
      if (code.startsWith('auth/')) {
        code = code.substring('auth/'.length);
      }
      throw FirebaseAuthException(code, error['message']);
    }
    return v;
  }
}
