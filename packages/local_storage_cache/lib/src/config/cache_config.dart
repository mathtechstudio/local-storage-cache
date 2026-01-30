import 'package:local_storage_cache/src/enums/eviction_policy.dart';

/// Configuration for caching features.
class CacheConfig {
  /// Creates a cache configuration.
  const CacheConfig({
    this.maxMemoryCacheSize = 100,
    this.maxDiskCacheSize = 1000,
    this.defaultTTL = const Duration(hours: 1),
    this.evictionPolicy = EvictionPolicy.lru,
    this.enableQueryCache = true,
    this.enableWarmCache = false,
  });

  /// Creates a default cache configuration.
  factory CacheConfig.defaultConfig() {
    return const CacheConfig();
  }

  /// Creates a high-performance cache configuration.
  factory CacheConfig.highPerformance() {
    return const CacheConfig(
      maxMemoryCacheSize: 500,
      maxDiskCacheSize: 5000,
      defaultTTL: Duration(minutes: 30),
      enableWarmCache: true,
    );
  }

  /// Creates a minimal cache configuration.
  factory CacheConfig.minimal() {
    return const CacheConfig(
      maxMemoryCacheSize: 50,
      maxDiskCacheSize: 200,
      defaultTTL: Duration(minutes: 15),
      evictionPolicy: EvictionPolicy.fifo,
      enableQueryCache: false,
    );
  }

  /// Creates a configuration from a map.
  factory CacheConfig.fromMap(Map<String, dynamic> map) {
    return CacheConfig(
      maxMemoryCacheSize: map['maxMemoryCacheSize'] as int? ?? 100,
      maxDiskCacheSize: map['maxDiskCacheSize'] as int? ?? 1000,
      defaultTTL: Duration(milliseconds: map['defaultTTL'] as int? ?? 3600000),
      evictionPolicy: _parseEvictionPolicy(map['evictionPolicy'] as String?),
      enableQueryCache: map['enableQueryCache'] as bool? ?? true,
      enableWarmCache: map['enableWarmCache'] as bool? ?? false,
    );
  }

  /// Maximum number of items in memory cache.
  final int maxMemoryCacheSize;

  /// Maximum number of items in disk cache.
  final int maxDiskCacheSize;

  /// Default TTL (Time To Live) for cached items.
  final Duration defaultTTL;

  /// Cache eviction policy when cache is full.
  final EvictionPolicy evictionPolicy;

  /// Whether to enable query result caching.
  final bool enableQueryCache;

  /// Whether to enable cache warming on startup.
  final bool enableWarmCache;

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'maxMemoryCacheSize': maxMemoryCacheSize,
      'maxDiskCacheSize': maxDiskCacheSize,
      'defaultTTL': defaultTTL.inMilliseconds,
      'evictionPolicy': evictionPolicy.name,
      'enableQueryCache': enableQueryCache,
      'enableWarmCache': enableWarmCache,
    };
  }

  static EvictionPolicy _parseEvictionPolicy(String? value) {
    switch (value) {
      case 'lfu':
        return EvictionPolicy.lfu;
      case 'fifo':
        return EvictionPolicy.fifo;
      default:
        return EvictionPolicy.lru;
    }
  }

  /// Creates a copy of this configuration with the given fields replaced.
  CacheConfig copyWith({
    int? maxMemoryCacheSize,
    int? maxDiskCacheSize,
    Duration? defaultTTL,
    EvictionPolicy? evictionPolicy,
    bool? enableQueryCache,
    bool? enableWarmCache,
  }) {
    return CacheConfig(
      maxMemoryCacheSize: maxMemoryCacheSize ?? this.maxMemoryCacheSize,
      maxDiskCacheSize: maxDiskCacheSize ?? this.maxDiskCacheSize,
      defaultTTL: defaultTTL ?? this.defaultTTL,
      evictionPolicy: evictionPolicy ?? this.evictionPolicy,
      enableQueryCache: enableQueryCache ?? this.enableQueryCache,
      enableWarmCache: enableWarmCache ?? this.enableWarmCache,
    );
  }
}
