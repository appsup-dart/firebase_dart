import 'package:firebase_dart/implementation/pure_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:platform_info/platform_info.dart' as platform_info;

import 'channel.dart';

class AndroidSmsRetriever extends SmsRetriever {
  late final Future<String?> _appSignatureHash = Future(() async {
    var v = (await channel.invokeMethod<String>('getAppSignatureHash'))!;
    return v;
  });

  @override
  Future<String?> getAppSignatureHash() {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return _appSignatureHash;
    }
    return Future.value();
  }

  @override
  Future<String?> retrieveSms() {
    if (!kIsWeb && platform_info.Platform.instance.android) {
      return Future<String?>(() async {
        var v = (await channel.invokeMethod<String>('retrieveSms'))!;
        return v;
      }).catchError((e, tr) {
        Logger('firebase_dart_flutter').warning('Failed retrieving SMS', e, tr);
        return null;
      });
    }
    return Future.value();
  }
}
