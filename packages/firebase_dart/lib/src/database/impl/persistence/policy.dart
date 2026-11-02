abstract class CachePolicy {
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries);

  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck);

  int get maxNumberOfQueriesToKeep;

  /// Byte size to reach in one prune.
  int get maximumCacheSizeAfterPrune;

  static const CachePolicy none = NoneCachePolicy();
}

class NoneCachePolicy implements CachePolicy {
  const NoneCachePolicy();

  @override
  bool shouldPrune(int currentSizeBytes, int countOfPrunableQueries) => false;

  @override
  bool shouldCheckCacheSize(int serverUpdatesSinceLastCheck) => false;

  @override
  int get maxNumberOfQueriesToKeep => 1 << 31;

  @override
  int get maximumCacheSizeAfterPrune => 0;
}

class LRUCachePolicy implements CachePolicy {
  static final int _serverUpdatesBetweenCacheSizeChecks = 100;
  static final int maxNumberOfPrunableQueriesToKeep = 1000;

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
  int get maxNumberOfQueriesToKeep => maxNumberOfPrunableQueriesToKeep;

  @override
  int get maximumCacheSizeAfterPrune => (maxSizeBytes * 0.8).floor();
}
