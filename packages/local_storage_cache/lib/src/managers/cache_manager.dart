import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:local_storage_cache/src/cache/disk_cache.dart';
import 'package:local_storage_cache/src/cache/memory_cache.dart';
import 'package:local_storage_cache/src/config/cache_config.dart';
import 'package:local_storage_cache/src/enums/cache_level.dart';
import 'package:local_storage_cache/src/models/cache_expiration_event.dart';
import 'package:local_storage_cache/src/models/cache_stats.dart';
import 'package:local_storage_cache/src/models/warm_cache_entry.dart';

/// Manages multi-level caching with TTL and eviction policies.
class CacheManager {
  /// Creates a cache manager.
  CacheManager(this.config);

  /// Cache configuration.
  final CacheConfig config;

  /// Memory cache.
  late final MemoryCache _memoryCache;

  /// Disk cache.
  late final DiskCache _diskCache;

  /// Cache statistics.
  final CacheStats _stats = CacheStats();

  /// Expiration event stream controller.
  final StreamController<CacheExpirationEvent> _expirationController =
      StreamController<CacheExpirationEvent>.broadcast();

  /// Whether the manager is initialized.
  bool _initialized = false;

  /// Expiration check timer.
  Timer? _expirationTimer;

  /// Initializes the cache manager.
  Future<void> initialize() async {
    if (_initialized) return;

    _memoryCache = MemoryCache(
      maxSize: config.maxMemoryCacheSize,
      evictionPolicy: config.evictionPolicy,
    );

    _diskCache = DiskCache(
      maxSize: config.maxDiskCacheSize,
    );

    await _diskCache.initialize();

    // Start expiration check timer (every minute)
    _expirationTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkExpirations(),
    );

    _initialized = true;
  }

  /// Puts a value into cache.
  Future<void> put(
    String key,
    dynamic value, {
    Duration? ttl,
    CacheLevel? level,
  }) async {
    _ensureInitialized();

    final effectiveTTL = ttl ?? config.defaultTTL;
    final effectiveLevel = level ?? CacheLevel.both;

    // Store in memory cache
    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      _memoryCache.put(key, value, ttl: effectiveTTL);
      _stats.memoryCacheSize = _memoryCache.size;
    }

    // Store in disk cache
    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      await _diskCache.put(key, value, ttl: effectiveTTL);
      _stats.diskCacheSize = await _diskCache.size;
    }
  }

  /// Gets a value from cache.
  Future<T?> get<T>(String key, {CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;

    // Try memory cache first
    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      final memoryValue = _memoryCache.get<T>(key);
      if (memoryValue != null) {
        _stats.cacheHits++;
        return memoryValue;
      }
    }

    // Try disk cache
    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      final diskValue = await _diskCache.get<T>(key);
      if (diskValue != null) {
        _stats.cacheHits++;

        // Promote to memory cache if using both levels
        if (effectiveLevel == CacheLevel.both) {
          _memoryCache.put(key, diskValue);
          _stats.memoryCacheSize = _memoryCache.size;
        }

        return diskValue;
      }
    }

    _stats.cacheMisses++;
    return null;
  }

  /// Removes a value from cache.
  Future<void> remove(String key, {CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;

    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      _memoryCache.remove(key);
      _stats.memoryCacheSize = _memoryCache.size;
    }

    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      await _diskCache.remove(key);
      _stats.diskCacheSize = await _diskCache.size;
    }
  }

  /// Clears all cache entries.
  Future<void> clear({CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;

    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      _memoryCache.clear();
      _stats.memoryCacheSize = 0;
    }

    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      await _diskCache.clear();
      _stats.diskCacheSize = 0;
    }
  }

  /// Caches a query result.
  Future<void> cacheQuery(
    String queryKey,
    List<Map<String, dynamic>> result,
    Duration? ttl,
  ) async {
    if (!config.enableQueryCache) return;

    _ensureInitialized();

    final cacheKey = _generateQueryCacheKey(queryKey);
    await put(cacheKey, result, ttl: ttl);
  }

  /// Gets a cached query result.
  Future<List<Map<String, dynamic>>?> getCachedQuery(String queryKey) async {
    if (!config.enableQueryCache) return null;

    _ensureInitialized();

    final cacheKey = _generateQueryCacheKey(queryKey);
    final cached = await get<List<dynamic>>(cacheKey);

    if (cached == null) return null;

    return cached.cast<Map<String, dynamic>>();
  }

  /// Invalidates query cache entries matching a pattern.
  Future<void> invalidateQueryCache(String pattern) async {
    _ensureInitialized();

    final memoryKeys = _memoryCache.keys;
    final diskKeys = await _diskCache.keys;

    final allKeys = {...memoryKeys, ...diskKeys};

    for (final key in allKeys) {
      if (key.startsWith('query_') && key.contains(pattern)) {
        await remove(key);
      }
    }
  }

  /// Warms the cache with predefined entries.
  Future<void> warmCache(List<WarmCacheEntry> entries) async {
    if (!config.enableWarmCache) return;

    _ensureInitialized();

    for (final entry in entries) {
      try {
        final value = await entry.loader();
        await put(entry.key, value, ttl: entry.ttl);
      } catch (e) {
        // Skip entries that fail to load
      }
    }
  }

  /// Clears expired entries from all cache levels.
  Future<int> clearExpired() async {
    _ensureInitialized();

    final memoryCleared = _memoryCache.clearExpired();
    final diskCleared = await _diskCache.clearExpired();

    _stats.memoryCacheSize = _memoryCache.size;
    _stats.diskCacheSize = await _diskCache.size;

    return memoryCleared + diskCleared;
  }

  /// Stream of cache expiration events.
  Stream<CacheExpirationEvent> get expirationStream =>
      _expirationController.stream;

  /// Gets cache statistics.
  CacheStats getStats() {
    _stats.memoryCacheSize = _memoryCache.size;
    return _stats;
  }

  /// Resets cache statistics.
  Future<void> resetStats() async {
    _stats
      ..reset()
      ..memoryCacheSize = _memoryCache.size
      ..diskCacheSize = await _diskCache.size;
  }

  /// Enforces maximum cache size by evicting entries.
  Future<void> enforceMaxSize() async {
    _ensureInitialized();

    // Memory cache enforces size automatically
    // Just update stats
    _stats.memoryCacheSize = _memoryCache.size;

    // Disk cache needs manual enforcement
    while (await _diskCache.size > config.maxDiskCacheSize) {
      final entries = await _diskCache.entries;
      if (entries.isEmpty) break;

      // Sort by creation time and remove oldest
      entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      await _diskCache.remove(entries.first.key);
      _stats.cacheEvictions++;
    }

    _stats.diskCacheSize = await _diskCache.size;
  }

  /// Gets current cache size.
  Future<int> getCurrentSize({CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;

    if (effectiveLevel == CacheLevel.memory) {
      return _memoryCache.size;
    } else if (effectiveLevel == CacheLevel.disk) {
      return _diskCache.size;
    } else {
      return _memoryCache.size + await _diskCache.size;
    }
  }

  /// Checks if a key exists in cache.
  Future<bool> containsKey(String key, {CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;

    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      if (_memoryCache.containsKey(key)) return true;
    }

    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      if (await _diskCache.containsKey(key)) return true;
    }

    return false;
  }

  /// Gets all cache keys.
  Future<List<String>> getKeys({CacheLevel? level}) async {
    _ensureInitialized();

    final effectiveLevel = level ?? CacheLevel.both;
    final keys = <String>{};

    if (effectiveLevel == CacheLevel.memory ||
        effectiveLevel == CacheLevel.both) {
      keys.addAll(_memoryCache.keys);
    }

    if (effectiveLevel == CacheLevel.disk ||
        effectiveLevel == CacheLevel.both) {
      keys.addAll(await _diskCache.keys);
    }

    return keys.toList();
  }

  /// Disposes the cache manager.
  Future<void> dispose() async {
    _expirationTimer?.cancel();
    await _expirationController.close();
  }

  /// Generates a cache key for a query.
  String _generateQueryCacheKey(String queryKey) {
    final hash = sha256.convert(utf8.encode(queryKey));
    return 'query_${hash.toString().substring(0, 16)}';
  }

  /// Checks for expired entries and emits events.
  Future<void> _checkExpirations() async {
    if (!_initialized) return;

    // Check memory cache
    for (final entry in _memoryCache.entries) {
      if (entry.isExpired) {
        _expirationController.add(
          CacheExpirationEvent(
            key: entry.key,
            expiredAt: DateTime.now(),
          ),
        );
      }
    }

    // Check disk cache
    for (final entry in await _diskCache.entries) {
      if (entry.isExpired) {
        _expirationController.add(
          CacheExpirationEvent(
            key: entry.key,
            expiredAt: DateTime.now(),
          ),
        );
      }
    }

    // Clear expired entries
    await clearExpired();
  }

  /// Ensures the manager is initialized.
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'CacheManager not initialized. Call initialize() first.',
      );
    }
  }
}
