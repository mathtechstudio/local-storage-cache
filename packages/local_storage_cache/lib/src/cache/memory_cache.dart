import 'dart:collection';

import 'package:local_storage_cache/src/enums/eviction_policy.dart';
import 'package:local_storage_cache/src/models/cache_entry.dart';

/// In-memory cache with configurable eviction policy.
class MemoryCache {
  /// Creates a memory cache.
  MemoryCache({
    required this.maxSize,
    required this.evictionPolicy,
  });

  /// Maximum number of entries.
  final int maxSize;

  /// Eviction policy.
  final EvictionPolicy evictionPolicy;

  /// Cache storage.
  final Map<String, CacheEntry<dynamic>> _cache = {};

  /// Access order queue for LRU.
  final Queue<String> _accessQueue = Queue<String>();

  /// Insertion order queue for FIFO.
  final Queue<String> _insertionQueue = Queue<String>();

  /// Frequency map for LFU optimization.
  /// Maps frequency count to set of keys with that frequency.
  final Map<int, Set<String>> _frequencyMap = {};

  /// Minimum frequency for LFU.
  int _minFrequency = 0;

  /// Gets a value from cache.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check expiration
    if (entry.isExpired) {
      remove(key);
      return null;
    }

    final oldAccessCount = entry.accessCount;

    // Update access metadata
    entry.markAccessed();

    // Update LRU queue
    if (evictionPolicy == EvictionPolicy.lru) {
      _accessQueue
        ..remove(key)
        ..addLast(key);
    }

    // Update LFU frequency map
    if (evictionPolicy == EvictionPolicy.lfu) {
      _updateFrequency(key, oldAccessCount, entry.accessCount);
    }

    return entry.value as T;
  }

  /// Puts a value into cache.
  void put(String key, dynamic value, {Duration? ttl}) {
    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      remove(key);
    }

    // Enforce max size
    if (_cache.length >= maxSize) {
      _evict();
    }

    // Create and store entry
    final entry = CacheEntry<dynamic>(
      key: key,
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl,
    );

    _cache[key] = entry;

    // Update queues
    if (evictionPolicy == EvictionPolicy.lru) {
      _accessQueue.addLast(key);
    }
    if (evictionPolicy == EvictionPolicy.fifo) {
      _insertionQueue.addLast(key);
    }

    // Update LFU frequency map (new entries start at frequency 0)
    if (evictionPolicy == EvictionPolicy.lfu) {
      _frequencyMap.putIfAbsent(0, () => {}).add(key);
      _minFrequency = 0;
    }
  }

  /// Removes a value from cache.
  bool remove(String key) {
    final entry = _cache[key];
    final removed = _cache.remove(key) != null;
    if (removed) {
      _accessQueue.remove(key);
      _insertionQueue.remove(key);

      // Remove from LFU frequency map
      if (evictionPolicy == EvictionPolicy.lfu && entry != null) {
        final freq = entry.accessCount;
        _frequencyMap[freq]?.remove(key);
        if (_frequencyMap[freq]?.isEmpty ?? false) {
          _frequencyMap.remove(freq);
        }
      }
    }
    return removed;
  }

  /// Clears all entries.
  void clear() {
    _cache.clear();
    _accessQueue.clear();
    _insertionQueue.clear();
  }

  /// Checks if a key exists.
  bool containsKey(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      remove(key);
      return false;
    }
    return true;
  }

  /// Gets all keys.
  List<String> get keys => _cache.keys.toList();

  /// Gets current size.
  int get size => _cache.length;

  /// Checks if cache is empty.
  bool get isEmpty => _cache.isEmpty;

  /// Checks if cache is full.
  bool get isFull => _cache.length >= maxSize;

  /// Removes expired entries.
  int clearExpired() {
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }

    return expiredKeys.length;
  }

  /// Gets all entries.
  List<CacheEntry<dynamic>> get entries => _cache.values.toList();

  /// Evicts an entry based on the eviction policy.
  void _evict() {
    if (_cache.isEmpty) return;

    String? keyToEvict;

    switch (evictionPolicy) {
      case EvictionPolicy.lru:
        // Evict least recently used
        keyToEvict = _accessQueue.isNotEmpty ? _accessQueue.first : null;

      case EvictionPolicy.lfu:
        // Evict least frequently used using optimized frequency map
        if (_frequencyMap.isNotEmpty) {
          // Find minimum frequency
          final minFreq = _frequencyMap.keys.reduce((a, b) => a < b ? a : b);
          final keysAtMinFreq = _frequencyMap[minFreq];
          if (keysAtMinFreq != null && keysAtMinFreq.isNotEmpty) {
            keyToEvict = keysAtMinFreq.first;
          }
        }

      case EvictionPolicy.fifo:
        // Evict first in
        keyToEvict = _insertionQueue.isNotEmpty ? _insertionQueue.first : null;
    }

    if (keyToEvict != null) {
      remove(keyToEvict);
    }
  }

  /// Updates frequency map when access count changes (for LFU optimization).
  void _updateFrequency(String key, int oldFreq, int newFreq) {
    // Remove from old frequency set
    _frequencyMap[oldFreq]?.remove(key);
    if (_frequencyMap[oldFreq]?.isEmpty ?? false) {
      _frequencyMap.remove(oldFreq);
    }

    // Add to new frequency set
    _frequencyMap.putIfAbsent(newFreq, () => {}).add(key);
  }
}
