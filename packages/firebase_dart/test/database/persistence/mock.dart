import 'package:firebase_dart/src/database/impl/persistence/policy.dart';

class TestCachePolicy implements CachePolicy {
  bool _timeToPrune = false;
  final double _percentToPruneAtOnce;
  final int _maxNumberToKeep;

  TestCachePolicy(this._percentToPruneAtOnce,
      [this._maxNumberToKeep = 1 << 31]);

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
  double getPercentOfQueriesToPruneAtOnce() {
    return _percentToPruneAtOnce;
  }

  @override
  int getMaxNumberOfQueriesToKeep() {
    return _maxNumberToKeep;
  }
}
