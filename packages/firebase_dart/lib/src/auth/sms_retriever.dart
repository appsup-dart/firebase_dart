import 'dart:async';

abstract class SmsRetriever {
  Future<String?> getAppSignatureHash();

  Future<String?> retrieveSms();
}

class DummySmsRetriever extends SmsRetriever {
  @override
  Future<String?> getAppSignatureHash() => Future.value();

  @override
  Future<String?> retrieveSms() => Completer<String?>().future;
}
