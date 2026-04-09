import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';

class ApnsVerifier {
  final Future<Duration> Function(String appToken, bool isSandbox)
      iosClientVerifier;

  ApnsVerifier({required this.iosClientVerifier});

  Future<String> verify() async {
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
        throw StateError('Failed to request notification permissions');
      }
    }

    var timeout = await iosClientVerifier(
            await tokenCompleter.future.timeout(defaultTimeout), !kReleaseMode)
        .timeout(defaultTimeout);

    return await completer.future.timeout(timeout);
  }
}
