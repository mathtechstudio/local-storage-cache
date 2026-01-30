// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

/// Performance metrics for storage operations.
class PerformanceMetrics {
  /// Creates performance metrics.
  PerformanceMetrics({
    this.queryMetrics = const {},
    this.cacheMetrics = const CacheMetrics(),
    this.storageMetrics = const StorageMetrics(),
  });

  /// Query performance metrics.
  final Map<String, QueryMetrics> queryMetrics;

  /// Cache performance metrics.
  final CacheMetrics cacheMetrics;

  /// Storage performance metrics.
  final StorageMetrics storageMetrics;

  /// Exports metrics to JSON.
  Map<String, dynamic> toJson() {
    return {
      'queryMetrics': queryMetrics.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'cacheMetrics': cacheMetrics.toJson(),
      'storageMetrics': storageMetrics.toJson(),
    };
  }
}

/// Metrics for individual queries.
class QueryMetrics {
  /// Creates query metrics.
  QueryMetrics({
    required this.sql,
    this.executionCount = 0,
    this.totalExecutionTimeMs = 0,
    this.minExecutionTimeMs,
    this.maxExecutionTimeMs,
    this.lastExecuted,
  });

  /// SQL query.
  final String sql;

  /// Number of times executed.
  int executionCount;

  /// Total execution time.
  int totalExecutionTimeMs;

  /// Minimum execution time.
  int? minExecutionTimeMs;

  /// Maximum execution time.
  int? maxExecutionTimeMs;

  /// Last execution time.
  DateTime? lastExecuted;

  /// Average execution time.
  double get averageExecutionTimeMs =>
      executionCount > 0 ? totalExecutionTimeMs / executionCount : 0;

  /// Records a query execution.
  void recordExecution(int timeMs) {
    executionCount++;
    totalExecutionTimeMs += timeMs;
    lastExecuted = DateTime.now();

    if (minExecutionTimeMs == null || timeMs < minExecutionTimeMs!) {
      minExecutionTimeMs = timeMs;
    }
    if (maxExecutionTimeMs == null || timeMs > maxExecutionTimeMs!) {
      maxExecutionTimeMs = timeMs;
    }
  }

  /// Exports to JSON.
  Map<String, dynamic> toJson() {
    return {
      'sql': sql,
      'executionCount': executionCount,
      'totalExecutionTimeMs': totalExecutionTimeMs,
      'averageExecutionTimeMs': averageExecutionTimeMs,
      'minExecutionTimeMs': minExecutionTimeMs,
      'maxExecutionTimeMs': maxExecutionTimeMs,
      'lastExecuted': lastExecuted?.toIso8601String(),
    };
  }
}

/// Cache performance metrics.
class CacheMetrics {
  /// Creates cache metrics.
  const CacheMetrics({
    this.hits = 0,
    this.misses = 0,
    this.evictions = 0,
    this.expirations = 0,
    this.totalSize = 0,
  });

  /// Number of cache hits.
  final int hits;

  /// Number of cache misses.
  final int misses;

  /// Number of evictions.
  final int evictions;

  /// Number of expirations.
  final int expirations;

  /// Total cache size in bytes.
  final int totalSize;

  /// Cache hit rate (0.0 to 1.0).
  double get hitRate {
    final total = hits + misses;
    return total > 0 ? hits / total : 0.0;
  }

  /// Exports to JSON.
  Map<String, dynamic> toJson() {
    return {
      'hits': hits,
      'misses': misses,
      'evictions': evictions,
      'expirations': expirations,
      'totalSize': totalSize,
      'hitRate': hitRate,
    };
  }

  /// Creates a copy with modified fields.
  CacheMetrics copyWith({
    int? hits,
    int? misses,
    int? evictions,
    int? expirations,
    int? totalSize,
  }) {
    return CacheMetrics(
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      evictions: evictions ?? this.evictions,
      expirations: expirations ?? this.expirations,
      totalSize: totalSize ?? this.totalSize,
    );
  }
}

/// Storage performance metrics.
class StorageMetrics {
  /// Creates storage metrics.
  const StorageMetrics({
    this.totalRecords = 0,
    this.totalTables = 0,
    this.totalSpaces = 0,
    this.totalSizeBytes = 0,
    this.averageQueryTimeMs = 0,
  });

  /// Total number of records.
  final int totalRecords;

  /// Total number of tables.
  final int totalTables;

  /// Total number of spaces.
  final int totalSpaces;

  /// Total storage size in bytes.
  final int totalSizeBytes;

  /// Average query execution time.
  final double averageQueryTimeMs;

  /// Exports to JSON.
  Map<String, dynamic> toJson() {
    return {
      'totalRecords': totalRecords,
      'totalTables': totalTables,
      'totalSpaces': totalSpaces,
      'totalSizeBytes': totalSizeBytes,
      'averageQueryTimeMs': averageQueryTimeMs,
    };
  }

  /// Creates a copy with modified fields.
  StorageMetrics copyWith({
    int? totalRecords,
    int? totalTables,
    int? totalSpaces,
    int? totalSizeBytes,
    double? averageQueryTimeMs,
  }) {
    return StorageMetrics(
      totalRecords: totalRecords ?? this.totalRecords,
      totalTables: totalTables ?? this.totalTables,
      totalSpaces: totalSpaces ?? this.totalSpaces,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      averageQueryTimeMs: averageQueryTimeMs ?? this.averageQueryTimeMs,
    );
  }
}
