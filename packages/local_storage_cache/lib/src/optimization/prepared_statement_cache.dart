// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:collection';

/// Represents a cached prepared statement.
class CachedStatement {
  /// Creates a cached statement.
  CachedStatement({
    required this.sql,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// The SQL query.
  final String sql;

  /// When the statement was created.
  final DateTime createdAt;

  /// When the statement was last used.
  DateTime? lastUsedAt;

  /// Number of times this statement has been used.
  int useCount = 0;

  /// Marks the statement as used.
  void markUsed() {
    lastUsedAt = DateTime.now();
    useCount++;
  }

  /// Age of the statement in milliseconds.
  int get ageMs => DateTime.now().difference(createdAt).inMilliseconds;

  /// Idle time in milliseconds.
  int get idleMs {
    if (lastUsedAt == null) return ageMs;
    return DateTime.now().difference(lastUsedAt!).inMilliseconds;
  }
}

/// Configuration for prepared statement cache.
class PreparedStatementCacheConfig {
  /// Creates prepared statement cache configuration.
  const PreparedStatementCacheConfig({
    this.maxSize = 100,
    this.maxAge = const Duration(hours: 1),
    this.maxIdleTime = const Duration(minutes: 30),
  });

  /// Maximum number of cached statements.
  final int maxSize;

  /// Maximum age of a cached statement.
  final Duration maxAge;

  /// Maximum idle time before evicting a statement.
  final Duration maxIdleTime;
}

/// Manages caching of prepared SQL statements.
///
/// The PreparedStatementCache improves performance by caching and reusing
/// prepared statements instead of parsing the same SQL repeatedly.
class PreparedStatementCache {
  /// Creates a prepared statement cache with the specified configuration.
  PreparedStatementCache({
    PreparedStatementCacheConfig? config,
  }) : _config = config ?? const PreparedStatementCacheConfig();

  final PreparedStatementCacheConfig _config;
  final LinkedHashMap<String, CachedStatement> _cache = LinkedHashMap();

  /// Gets a cached statement or creates a new one.
  CachedStatement getOrCreate(String sql) {
    // Check if statement exists in cache
    if (_cache.containsKey(sql)) {
      final statement = _cache[sql]!;

      // Check if statement is still valid
      if (_isValid(statement)) {
        statement.markUsed();
        // Move to end (most recently used)
        _cache.remove(sql);
        _cache[sql] = statement;
        return statement;
      } else {
        // Remove invalid statement
        _cache.remove(sql);
      }
    }

    // Create new statement
    final statement = CachedStatement(
      sql: sql,
      createdAt: DateTime.now(),
    )..markUsed();

    // Add to cache
    _cache[sql] = statement;

    // Evict if necessary
    _evictIfNecessary();

    return statement;
  }

  /// Checks if a statement is cached.
  bool contains(String sql) {
    if (!_cache.containsKey(sql)) return false;

    final statement = _cache[sql]!;
    if (!_isValid(statement)) {
      _cache.remove(sql);
      return false;
    }

    return true;
  }

  /// Removes a statement from the cache.
  void remove(String sql) {
    _cache.remove(sql);
  }

  /// Clears all cached statements.
  void clear() {
    _cache.clear();
  }

  /// Gets cache statistics.
  Map<String, dynamic> getStats() {
    return {
      'size': _cache.length,
      'maxSize': _config.maxSize,
      'statements': _cache.values.map((s) {
        return {
          'sql': s.sql.length > 50 ? '${s.sql.substring(0, 50)}...' : s.sql,
          'useCount': s.useCount,
          'ageMs': s.ageMs,
          'idleMs': s.idleMs,
        };
      }).toList(),
    };
  }

  /// Gets the most frequently used statements.
  List<CachedStatement> getMostUsed({int limit = 10}) {
    final sorted = _cache.values.toList()
      ..sort((a, b) => b.useCount.compareTo(a.useCount));

    return sorted.take(limit).toList();
  }

  /// Performs cleanup of expired statements.
  void cleanup() {
    final toRemove = <String>[];

    for (final entry in _cache.entries) {
      if (!_isValid(entry.value)) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      _cache.remove(key);
    }
  }

  bool _isValid(CachedStatement statement) {
    // Check age
    if (statement.ageMs > _config.maxAge.inMilliseconds) {
      return false;
    }

    // Check idle time
    if (statement.idleMs > _config.maxIdleTime.inMilliseconds) {
      return false;
    }

    return true;
  }

  void _evictIfNecessary() {
    if (_cache.length <= _config.maxSize) return;

    // Remove oldest (least recently used) statement
    final firstKey = _cache.keys.first;
    _cache.remove(firstKey);
  }
}
