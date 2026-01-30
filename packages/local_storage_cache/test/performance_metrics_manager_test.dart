import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/managers/performance_metrics_manager.dart';

void main() {
  group('PerformanceMetricsManager', () {
    late PerformanceMetricsManager metricsManager;

    setUp(() {
      metricsManager = PerformanceMetricsManager();
    });

    test('records query execution', () {
      const sql = 'SELECT * FROM users';
      metricsManager.recordQueryExecution(sql, 25);

      final metrics = metricsManager.getQueryMetrics(sql);
      expect(metrics, isNotNull);
      expect(metrics!.executionCount, equals(1));
      expect(metrics.totalExecutionTimeMs, equals(25));
      expect(metrics.averageExecutionTimeMs, equals(25.0));
    });

    test('aggregates multiple query executions', () {
      const sql = 'SELECT * FROM users';
      metricsManager.recordQueryExecution(sql, 20);
      metricsManager.recordQueryExecution(sql, 30);
      metricsManager.recordQueryExecution(sql, 40);

      final metrics = metricsManager.getQueryMetrics(sql);
      expect(metrics!.executionCount, equals(3));
      expect(metrics.totalExecutionTimeMs, equals(90));
      expect(metrics.averageExecutionTimeMs, equals(30.0));
      expect(metrics.minExecutionTimeMs, equals(20));
      expect(metrics.maxExecutionTimeMs, equals(40));
    });

    test('records cache hits', () {
      metricsManager.recordCacheHit();
      metricsManager.recordCacheHit();

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.hits, equals(2));
    });

    test('records cache misses', () {
      metricsManager.recordCacheMiss();
      metricsManager.recordCacheMiss();
      metricsManager.recordCacheMiss();

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.misses, equals(3));
    });

    test('calculates cache hit rate', () {
      metricsManager.recordCacheHit();
      metricsManager.recordCacheHit();
      metricsManager.recordCacheHit();
      metricsManager.recordCacheMiss();

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.hitRate, equals(0.75));
    });

    test('records cache evictions', () {
      metricsManager.recordCacheEviction();

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.evictions, equals(1));
    });

    test('records cache expirations', () {
      metricsManager.recordCacheExpiration();
      metricsManager.recordCacheExpiration();

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.expirations, equals(2));
    });

    test('updates cache size', () {
      metricsManager.updateCacheSize(1024);

      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.totalSize, equals(1024));
    });

    test('updates storage metrics', () {
      metricsManager.updateStorageMetrics(
        totalRecords: 1000,
        totalTables: 5,
        totalSpaces: 2,
        totalSizeBytes: 1048576,
        averageQueryTimeMs: 15.5,
      );

      final metrics = metricsManager.getMetrics();
      expect(metrics.storageMetrics.totalRecords, equals(1000));
      expect(metrics.storageMetrics.totalTables, equals(5));
      expect(metrics.storageMetrics.totalSpaces, equals(2));
      expect(metrics.storageMetrics.totalSizeBytes, equals(1048576));
      expect(metrics.storageMetrics.averageQueryTimeMs, equals(15.5));
    });

    test('identifies slow queries', () {
      metricsManager.recordQueryExecution('SELECT * FROM users', 50);
      metricsManager.recordQueryExecution('SELECT * FROM posts', 150);
      metricsManager.recordQueryExecution('SELECT * FROM comments', 200);

      final slowQueries = metricsManager.getSlowQueries(thresholdMs: 100);
      expect(slowQueries.length, equals(2));
      expect(slowQueries.first.averageExecutionTimeMs, greaterThan(100));
    });

    test('sorts slow queries by execution time', () {
      metricsManager.recordQueryExecution('query1', 150);
      metricsManager.recordQueryExecution('query2', 200);
      metricsManager.recordQueryExecution('query3', 100);

      final slowQueries = metricsManager.getSlowQueries(thresholdMs: 50);
      expect(slowQueries.length, equals(3));
      expect(slowQueries[0].averageExecutionTimeMs, equals(200));
      expect(slowQueries[1].averageExecutionTimeMs, equals(150));
      expect(slowQueries[2].averageExecutionTimeMs, equals(100));
    });

    test('identifies frequent queries', () {
      metricsManager.recordQueryExecution('query1', 10);
      metricsManager.recordQueryExecution('query1', 10);
      metricsManager.recordQueryExecution('query1', 10);

      metricsManager.recordQueryExecution('query2', 10);
      metricsManager.recordQueryExecution('query2', 10);

      metricsManager.recordQueryExecution('query3', 10);

      final frequentQueries = metricsManager.getFrequentQueries(limit: 2);
      expect(frequentQueries.length, equals(2));
      expect(frequentQueries[0].executionCount, equals(3));
      expect(frequentQueries[1].executionCount, equals(2));
    });

    test('clears all metrics', () {
      metricsManager.recordQueryExecution('SELECT * FROM users', 25);
      metricsManager.recordCacheHit();
      metricsManager.updateStorageMetrics(totalRecords: 100);

      metricsManager.clearMetrics();

      final metrics = metricsManager.getMetrics();
      expect(metrics.queryMetrics.isEmpty, isTrue);
      expect(metrics.cacheMetrics.hits, equals(0));
      expect(metrics.storageMetrics.totalRecords, equals(0));
    });

    test('exports metrics to JSON', () {
      metricsManager.recordQueryExecution('SELECT * FROM users', 25);
      metricsManager.recordCacheHit();
      metricsManager.updateStorageMetrics(totalRecords: 100);

      final json = metricsManager.exportMetrics();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['queryMetrics'], isA<Map<dynamic, dynamic>>());
      expect(json['cacheMetrics'], isA<Map<dynamic, dynamic>>());
      expect(json['storageMetrics'], isA<Map<dynamic, dynamic>>());
    });

    test('handles zero cache operations for hit rate', () {
      final metrics = metricsManager.getMetrics();
      expect(metrics.cacheMetrics.hitRate, equals(0.0));
    });

    test('tracks query min and max execution times', () {
      const sql = 'SELECT * FROM users';
      metricsManager.recordQueryExecution(sql, 50);
      metricsManager.recordQueryExecution(sql, 10);
      metricsManager.recordQueryExecution(sql, 100);

      final metrics = metricsManager.getQueryMetrics(sql);
      expect(metrics!.minExecutionTimeMs, equals(10));
      expect(metrics.maxExecutionTimeMs, equals(100));
    });
  });
}
