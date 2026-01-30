/// Statistics about cache usage.
class CacheStats {
  /// Creates cache statistics with the specified values.
  CacheStats({
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.cacheEvictions = 0,
    this.memoryCacheSize = 0,
    this.diskCacheSize = 0,
  });

  /// Total cache hits.
  int cacheHits;

  /// Total cache misses.
  int cacheMisses;

  /// Total cache evictions.
  int cacheEvictions;

  /// Current memory cache size.
  int memoryCacheSize;

  /// Current disk cache size.
  int diskCacheSize;

  /// Cache hit rate (0.0 to 1.0).
  double get hitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  /// Resets all statistics.
  void reset() {
    cacheHits = 0;
    cacheMisses = 0;
    cacheEvictions = 0;
  }

  /// Converts the statistics to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'cacheEvictions': cacheEvictions,
      'memoryCacheSize': memoryCacheSize,
      'diskCacheSize': diskCacheSize,
      'hitRate': hitRate,
    };
  }
}
