// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:local_storage_cache/src/models/performance_metrics.dart';

/// Manages performance metrics collection and aggregation.
///
/// The PerformanceMetricsManager tracks query execution times, cache
/// performance, and storage statistics for monitoring and optimization.
///
/// Example:
/// ```dart
/// final metricsManager = PerformanceMetricsManager();
///
/// // Record query execution
/// metricsManager.recordQueryExecution('SELECT * FROM users', 25);
///
/// // Record cache hit
/// metricsManager.recordCacheHit();
///
/// // Get metrics
/// final metrics = metricsManager.getMetrics();
/// print('Cache hit rate: ${metrics.cacheMetrics.hitRate}');
/// ```
class PerformanceMetricsManager {
  final Map<String, QueryMetrics> _queryMetrics = {};
  CacheMetrics _cacheMetrics = const CacheMetrics();
  StorageMetrics _storageMetrics = const StorageMetrics();

  /// Records a query execution.
  void recordQueryExecution(String sql, int executionTimeMs) {
    final existing = _queryMetrics[sql];

    if (existing == null) {
      _queryMetrics[sql] = QueryMetrics(
        sql: sql,
        executionCount: 1,
        totalExecutionTimeMs: executionTimeMs,
        minExecutionTimeMs: executionTimeMs,
        maxExecutionTimeMs: executionTimeMs,
        lastExecuted: DateTime.now(),
      );
    } else {
      // Update existing metrics
      existing.recordExecution(executionTimeMs);
    }
  }

  /// Records a cache hit.
  void recordCacheHit() {
    _cacheMetrics = _cacheMetrics.copyWith(
      hits: _cacheMetrics.hits + 1,
    );
  }

  /// Records a cache miss.
  void recordCacheMiss() {
    _cacheMetrics = _cacheMetrics.copyWith(
      misses: _cacheMetrics.misses + 1,
    );
  }

  /// Records a cache eviction.
  void recordCacheEviction() {
    _cacheMetrics = _cacheMetrics.copyWith(
      evictions: _cacheMetrics.evictions + 1,
    );
  }

  /// Records a cache expiration.
  void recordCacheExpiration() {
    _cacheMetrics = _cacheMetrics.copyWith(
      expirations: _cacheMetrics.expirations + 1,
    );
  }

  /// Updates cache size.
  void updateCacheSize(int sizeBytes) {
    _cacheMetrics = _cacheMetrics.copyWith(
      totalSize: sizeBytes,
    );
  }

  /// Updates storage metrics.
  void updateStorageMetrics({
    int? totalRecords,
    int? totalTables,
    int? totalSpaces,
    int? totalSizeBytes,
    double? averageQueryTimeMs,
  }) {
    _storageMetrics = _storageMetrics.copyWith(
      totalRecords: totalRecords,
      totalTables: totalTables,
      totalSpaces: totalSpaces,
      totalSizeBytes: totalSizeBytes,
      averageQueryTimeMs: averageQueryTimeMs,
    );
  }

  /// Gets current performance metrics.
  PerformanceMetrics getMetrics() {
    return PerformanceMetrics(
      queryMetrics: Map.unmodifiable(_queryMetrics),
      cacheMetrics: _cacheMetrics,
      storageMetrics: _storageMetrics,
    );
  }

  /// Gets metrics for a specific query.
  QueryMetrics? getQueryMetrics(String sql) {
    return _queryMetrics[sql];
  }

  /// Gets slow queries (above threshold).
  List<QueryMetrics> getSlowQueries({int thresholdMs = 100}) {
    return _queryMetrics.values
        .where((m) => m.averageExecutionTimeMs > thresholdMs)
        .toList()
      ..sort(
        (a, b) => b.averageExecutionTimeMs.compareTo(a.averageExecutionTimeMs),
      );
  }

  /// Gets most frequently executed queries.
  List<QueryMetrics> getFrequentQueries({int limit = 10}) {
    final sorted = _queryMetrics.values.toList()
      ..sort((a, b) => b.executionCount.compareTo(a.executionCount));
    return sorted.take(limit).toList();
  }

  /// Clears all metrics.
  void clearMetrics() {
    _queryMetrics.clear();
    _cacheMetrics = const CacheMetrics();
    _storageMetrics = const StorageMetrics();
  }

  /// Exports metrics to JSON.
  Map<String, dynamic> exportMetrics() {
    return getMetrics().toJson();
  }
}
