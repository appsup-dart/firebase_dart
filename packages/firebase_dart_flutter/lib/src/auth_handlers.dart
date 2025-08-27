import 'dart:async';

import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/auth.dart';
import 'package:firebase_dart_flutter/src/deep_link_retriever.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

import 'channel.dart';

class FlutterAuthHandler extends FirebaseAppAuthHandler {
  final DeepLinkRetriever _deepLinkRetriever = DeepLinkRetriever.instance;
  Future<AuthCredential?>? _lastAuthResult;

  @override
  Future<AuthCredential?> getSignInResult(FirebaseApp app) async {
    if (!kIsWeb) {
      return _lastAuthResult ??= Future(() async {
        var v = await (platform_info.Platform.instance.android
            ? getResult('getAuthResult')
            : _deepLinkRetriever.getDeepLinkResult());
        _lastAuthResult = null;
        return createCredential(
            sessionId: v['sessionId'],
            providerId: v['providerId'],
            link: v['link']);
      });
    }
    return null;
  }
}
