import 'package:firebase_dart/app_check.dart';
import '../isolate.dart';

class IsolateFirebaseAppCheck extends IsolateFirebaseService
    implements FirebaseAppCheck {
  IsolateFirebaseAppCheck(super.app);

  @override
  Future<void> activate({AppCheckProvider? provider}) {
    // TODO: implement activate
    throw UnimplementedError();
  }

  @override
  Future<String> getLimitedUseToken() {
    // TODO: implement getLimitedUseToken
    throw UnimplementedError();
  }

  @override
  Future<String?> getToken([bool? forceRefresh]) {
    // TODO: implement getToken
    throw UnimplementedError();
  }

  @override
  // TODO: implement onTokenChange
  Stream<String?> get onTokenChange => throw UnimplementedError();

  @override
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled) {
    // TODO: implement setTokenAutoRefreshEnabled
    throw UnimplementedError();
  }
}
