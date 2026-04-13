import 'package:firebase_dart/src/app_check/app_check.dart';

import '../core/impl/app.dart';

class FirebaseAppCheckImpl extends FirebaseService implements FirebaseAppCheck {
  FirebaseAppCheckImpl(super.app);

  AppCheckProvider? _provider;

  @override
  Future<void> activate(
      {WebProvider? webProvider,
      AndroidProvider androidProvider = AndroidProvider.playIntegrity,
      AppleProvider appleProvider = AppleProvider.deviceCheck}) async {
    _provider = webProvider;
  }

  @override
  Future<String> getLimitedUseToken() {
    // TODO: implement getLimitedUseToken
    throw UnimplementedError();
  }

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    var t = await _provider?.getToken(app);

    return t?.token;
  }

  @override
  Stream<String?> get onTokenChange => Stream.empty();

  @override
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled) {
    // TODO: implement setTokenAutoRefreshEnabled
    throw UnimplementedError();
  }
}
