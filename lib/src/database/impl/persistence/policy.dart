abstract class CachePolicy {
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries);

  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck);

  double getPercentOfQueriesToPruneAtOnce();

  int getMaxNumberOfQueriesToKeep();

  static const CachePolicy none = NoneCachePolicy();
}

class NoneCachePolicy implements CachePolicy {
  const NoneCachePolicy();

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) => false;

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) => false;

  @override
  double getPercentOfQueriesToPruneAtOnce() => 0;

  @override
  int getMaxNumberOfQueriesToKeep() => 1 << 31;
}

class LRUCachePolicy implements CachePolicy {
  static final int _serverUpdatesBetweenCacheSizeChecks = 1000;
  static final int maxNumberOfPrunableQueriesToKeep = 1000;
  static final double percentOfQueriesToPruneAtOnce =
      0.2; // 20% at a time until we're below our max.

  final int maxSizeBytes;

  LRUCachePolicy(this.maxSizeBytes);

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) {
    return currentSizeBytes > maxSizeBytes ||
        countOfPrunableQueries > maxNumberOfPrunableQueriesToKeep;
  }

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) {
    return serverUpdatesSinceLastCheck > _serverUpdatesBetweenCacheSizeChecks;
  }

  @override
  double getPercentOfQueriesToPruneAtOnce() {
    return percentOfQueriesToPruneAtOnce;
  }

  @override
  int getMaxNumberOfQueriesToKeep() {
    return maxNumberOfPrunableQueriesToKeep;
  }
}
