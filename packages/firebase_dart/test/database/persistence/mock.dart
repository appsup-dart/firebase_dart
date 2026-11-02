import 'package:firebase_dart/src/database/impl/persistence/policy.dart';

class TestCachePolicy implements CachePolicy {
  bool _timeToPrune = false;
  final int _maximumCacheSizeAfterPrune;
  final int _maxNumberToKeep;

  TestCachePolicy(
      {int maximumCacheSizeAfterPrune = 0, int maxNumberToKeep = 1 << 31})
      : _maximumCacheSizeAfterPrune = maximumCacheSizeAfterPrune,
        _maxNumberToKeep = maxNumberToKeep;

  void pruneOnNextServerUpdate() {
    _timeToPrune = true;
  }

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) {
    if (_timeToPrune) {
      _timeToPrune = false;
      return true;
    } else {
      return false;
    }
  }

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) {
    return true;
  }

  @override
  int get maxNumberOfQueriesToKeep => _maxNumberToKeep;

  @override
  int get maximumCacheSizeAfterPrune => _maximumCacheSizeAfterPrune;
}
