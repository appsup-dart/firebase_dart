import 'dart:async';

import 'package:firebase_dart/app_check.dart';
import 'package:firebase_dart/core.dart';
import 'package:firebase_dart/src/implementation/isolate/util.dart';
import 'package:rxdart/rxdart.dart';
import '../isolate.dart';

class IsolateFirebaseAppCheck extends IsolateFirebaseService
    implements FirebaseAppCheck {
  final BehaviorSubject<String?> _subject = BehaviorSubject(sync: true);

  IsolateFirebaseAppCheck(super.app) {
    app.commander
        .subscribe<String?>(AppCheckFunctionCall(
          #onTokenChange,
          app.name,
        ))
        .forEach((v) => _subject.add(v));
  }

  Future<T> invoke<T>(Symbol method,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments]) async {
    var call = AppCheckFunctionCall<FutureOr<T>>(
        method, app.name, positionalArguments, namedArguments);
    return await app.commander.execute(call);
  }

  @override
  Future<void> activate({AppCheckProviders? providers}) {
    return invoke(#activate, [
      providers == null
          ? null
          : [
              for (var provider in providers.providers)
                IsolateAppCheckProvider.from(provider)
            ]
    ]);
  }

  @override
  Future<String> getLimitedUseToken() {
    return invoke(#getLimitedUseToken, []);
  }

  @override
  Future<String?> getToken([bool forceRefresh = false]) {
    return invoke(#getToken, [forceRefresh]);
  }

  @override
  Stream<String?> get onTokenChange => _subject.stream;

  @override
  Future<void> setTokenAutoRefreshEnabled(bool isTokenAutoRefreshEnabled) {
    return invoke(#setTokenAutoRefreshEnabled, [isTokenAutoRefreshEnabled]);
  }
}

class IsolateAppCheckProvider extends AppCheckProvider {
  late final IsolateCommander _commander;

  IsolateAppCheckProvider.from(AppCheckProvider provider) {
    var worker = IsolateWorker()
      ..registerFunction(#getAttestation, (String appName) {
        var app = Firebase.app(appName);
        return provider.getAttestation(app);
      });

    _commander = worker.commander;
  }

  @override
  Future<AppCheckAttestation> getAttestation(FirebaseApp app) {
    return _commander.execute(RegisteredFunctionCall(
      #getAttestation,
      [app.name],
    ));
  }
}

class AppCheckFunctionCall<T> extends BaseFunctionCall<T> {
  final String appName;
  final Symbol functionName;

  AppCheckFunctionCall(this.functionName, this.appName,
      [List<dynamic>? positionalArguments,
      Map<Symbol, dynamic>? namedArguments])
      : super(positionalArguments, namedArguments);

  FirebaseAppCheck get appCheck =>
      FirebaseAppCheck.instanceFor(app: Firebase.app(appName));

  @override
  Function? get function {
    switch (functionName) {
      case #getLimitedUseToken:
        return appCheck.getLimitedUseToken;
      case #getToken:
        return appCheck.getToken;
      case #setTokenAutoRefreshEnabled:
        return appCheck.setTokenAutoRefreshEnabled;
      case #activate:
        return (List<AppCheckProvider>? providers) => appCheck.activate(
            providers: providers == null ? null : AppCheckProviders(providers));
      case #onTokenChange:
        return () => appCheck.onTokenChange;
    }
    return null;
  }
}
