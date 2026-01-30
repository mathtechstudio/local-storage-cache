// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:local_storage_cache/src/schema/table_schema.dart';

/// Represents the result of query analysis.
class QueryAnalysis {
  /// Creates a new query analysis result.
  const QueryAnalysis({
    required this.sql,
    required this.estimatedTimeMs,
    required this.hasFullTableScan,
    required this.missingIndexes,
    required this.suggestions,
    required this.complexityScore,
  });

  /// The SQL query being analyzed.
  final String sql;

  /// The estimated execution time in milliseconds.
  final int estimatedTimeMs;

  /// Whether the query performs a full table scan.
  final bool hasFullTableScan;

  /// List of missing indexes that could improve performance.
  final List<String> missingIndexes;

  /// List of suggestions for query optimization.
  final List<String> suggestions;

  /// The complexity score of the query (0-100, higher is more complex).
  final int complexityScore;

  /// Returns true if the query needs optimization.
  bool get needsOptimization =>
      hasFullTableScan || missingIndexes.isNotEmpty || complexityScore > 70;
}

/// Represents statistics for a frequently executed query.
class QueryStats {
  /// Creates new query statistics.
  QueryStats({
    required this.sql,
    required this.lastExecuted,
    this.executionCount = 0,
    this.totalTimeMs = 0,
  });

  /// The SQL query.
  final String sql;

  /// Number of times the query has been executed.
  int executionCount;

  /// Total execution time in milliseconds.
  int totalTimeMs;

  /// Average execution time in milliseconds.
  double get averageTimeMs =>
      executionCount > 0 ? totalTimeMs / executionCount : 0;

  /// Last execution time.
  DateTime lastExecuted;

  /// Records a new execution.
  void recordExecution(int timeMs) {
    executionCount++;
    totalTimeMs += timeMs;
    lastExecuted = DateTime.now();
  }
}

/// Manages query optimization and analysis.
///
/// The QueryOptimizer analyzes SQL queries to detect performance issues
/// and suggest optimizations. It tracks query execution statistics and
/// can automatically optimize frequently executed queries.
class QueryOptimizer {
  /// Creates a new query optimizer.
  ///
  /// Parameters:
  /// - schemas: Map of table names to their schemas
  /// - slowQueryThresholdMs: Threshold for considering a query slow (default: 100ms)
  /// - autoOptimizeThreshold: Number of executions before auto-optimization (default: 100)
  QueryOptimizer({
    required Map<String, TableSchema> schemas,
    int slowQueryThresholdMs = 100,
    int autoOptimizeThreshold = 100,
  })  : _schemas = schemas,
        _slowQueryThresholdMs = slowQueryThresholdMs,
        _autoOptimizeThreshold = autoOptimizeThreshold;
  final Map<String, QueryStats> _queryStats = {};
  final Map<String, TableSchema> _schemas;
  final int _slowQueryThresholdMs;
  final int _autoOptimizeThreshold;

  /// Analyzes a SQL query and returns optimization suggestions.
  QueryAnalysis analyzeQuery(String sql) {
    final missingIndexes = <String>[];
    final suggestions = <String>[];
    var hasFullTableScan = false;
    var complexityScore = 0;

    final normalizedSql = sql.trim().toUpperCase();

    if (normalizedSql.contains('SELECT *')) {
      suggestions.add('Avoid SELECT *. Specify only needed columns.');
      complexityScore += 10;
    }

    if (normalizedSql.startsWith('SELECT') &&
        !normalizedSql.contains('WHERE') &&
        !normalizedSql.contains('LIMIT')) {
      hasFullTableScan = true;
      suggestions.add('Query performs full table scan. Add WHERE or LIMIT.');
      complexityScore += 30;
    }

    if (normalizedSql.contains(' OR ')) {
      suggestions.add('OR conditions may prevent index usage. Consider UNION.');
      complexityScore += 15;
    }

    if (normalizedSql.contains("LIKE '%")) {
      suggestions.add('Leading wildcard in LIKE prevents index usage.');
      complexityScore += 20;
    }

    if (_hasFunctionInWhere(normalizedSql)) {
      suggestions
          .add('Functions in WHERE clause prevent index usage on that column.');
      complexityScore += 15;
    }

    final joinCount = 'JOIN'.allMatches(normalizedSql).length;
    if (joinCount > 3) {
      suggestions.add('Query has $joinCount JOINs. Consider denormalization.');
      complexityScore += joinCount * 10;
    }

    if (normalizedSql.contains('SELECT') &&
        normalizedSql.indexOf('SELECT') !=
            normalizedSql.lastIndexOf('SELECT')) {
      suggestions.add('Subqueries can be slow. Consider JOINs or CTEs.');
      complexityScore += 20;
    }

    final whereIndexes = _detectMissingIndexes(sql);
    missingIndexes.addAll(whereIndexes);
    if (whereIndexes.isNotEmpty) {
      complexityScore += whereIndexes.length * 15;
    }

    final estimatedTimeMs = _estimateExecutionTime(complexityScore);

    return QueryAnalysis(
      sql: sql,
      estimatedTimeMs: estimatedTimeMs,
      hasFullTableScan: hasFullTableScan,
      missingIndexes: missingIndexes,
      suggestions: suggestions,
      complexityScore: complexityScore,
    );
  }

  /// Detects missing indexes that could improve query performance.
  ///
  /// Analyzes WHERE, ORDER BY, and JOIN clauses to suggest indexes.
  List<String> detectMissingIndexes(String sql, String tableName) {
    final schema = _schemas[tableName];
    if (schema == null) return [];

    final missingIndexes = <String>[];
    final normalizedSql = sql.toUpperCase();

    // Check WHERE clause
    final whereMatch =
        RegExp(r'WHERE\s+(.+?)(?:ORDER|GROUP|LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);

    if (whereMatch != null) {
      final whereClause = whereMatch.group(1) ?? '';

      for (final field in schema.fields) {
        final fieldPattern =
            RegExp('\\b${field.name.toUpperCase()}\\b', caseSensitive: false);

        if (fieldPattern.hasMatch(whereClause)) {
          final hasIndex =
              schema.indexes.any((index) => index.fields.contains(field.name));

          if (!hasIndex && !missingIndexes.contains(field.name)) {
            missingIndexes.add(field.name);
          }
        }
      }
    }

    // Check ORDER BY clause
    final orderByMatch =
        RegExp(r'ORDER\s+BY\s+(.+?)(?:LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);

    if (orderByMatch != null) {
      final orderByClause = orderByMatch.group(1) ?? '';

      for (final field in schema.fields) {
        final fieldPattern =
            RegExp('\\b${field.name.toUpperCase()}\\b', caseSensitive: false);

        if (fieldPattern.hasMatch(orderByClause)) {
          final hasIndex =
              schema.indexes.any((index) => index.fields.contains(field.name));

          if (!hasIndex && !missingIndexes.contains(field.name)) {
            missingIndexes.add(field.name);
          }
        }
      }
    }

    // Check JOIN conditions
    final joinMatches = RegExp(
      r'JOIN\s+\w+\s+ON\s+(.+?)(?:WHERE|ORDER|GROUP|LIMIT|JOIN|$)',
      caseSensitive: false,
    ).allMatches(sql);

    for (final joinMatch in joinMatches) {
      final joinCondition = joinMatch.group(1) ?? '';

      for (final field in schema.fields) {
        final fieldPattern =
            RegExp('\\b${field.name.toUpperCase()}\\b', caseSensitive: false);

        if (fieldPattern.hasMatch(joinCondition)) {
          final hasIndex =
              schema.indexes.any((index) => index.fields.contains(field.name));

          if (!hasIndex && !missingIndexes.contains(field.name)) {
            missingIndexes.add(field.name);
          }
        }
      }
    }

    return missingIndexes;
  }

  /// Detects if the query performs a full table scan.
  bool detectFullTableScan(String sql) {
    final normalizedSql = sql.trim().toUpperCase();

    if (normalizedSql.startsWith('SELECT') &&
        !normalizedSql.contains('WHERE') &&
        !normalizedSql.contains('LIMIT')) {
      return true;
    }

    if ((normalizedSql.startsWith('UPDATE') ||
            normalizedSql.startsWith('DELETE')) &&
        !normalizedSql.contains('WHERE')) {
      return true;
    }

    return false;
  }

  /// Estimates the execution time of a query in milliseconds.
  int estimateExecutionTime(String sql) {
    final analysis = analyzeQuery(sql);
    return analysis.estimatedTimeMs;
  }

  /// Records the execution of a query with its actual execution time.
  void recordQueryExecution(String sql, int executionTimeMs) {
    final stats = _queryStats.putIfAbsent(
      sql,
      () => QueryStats(sql: sql, lastExecuted: DateTime.now()),
    )..recordExecution(executionTimeMs);

    if (stats.executionCount >= _autoOptimizeThreshold &&
        stats.averageTimeMs > _slowQueryThresholdMs) {
      _autoOptimizeQuery(sql);
    }
  }

  /// Gets statistics for a specific query.
  QueryStats? getQueryStats(String sql) {
    return _queryStats[sql];
  }

  /// Gets all tracked query statistics.
  Map<String, QueryStats> getAllQueryStats() {
    return Map.unmodifiable(_queryStats);
  }

  /// Gets slow queries (queries exceeding the threshold).
  List<QueryStats> getSlowQueries() {
    return _queryStats.values
        .where((stats) => stats.averageTimeMs > _slowQueryThresholdMs)
        .toList()
      ..sort((a, b) => b.averageTimeMs.compareTo(a.averageTimeMs));
  }

  /// Gets frequently executed queries.
  List<QueryStats> getFrequentQueries({int limit = 10}) {
    final sorted = _queryStats.values.toList()
      ..sort((a, b) => b.executionCount.compareTo(a.executionCount));

    return sorted.take(limit).toList();
  }

  /// Clears all query statistics.
  void clearStats() {
    _queryStats.clear();
  }

  void _autoOptimizeQuery(String sql) {
    final analysis = analyzeQuery(sql);

    if (analysis.needsOptimization) {
      // In a real implementation, this would:
      // 1. Create missing indexes
      // 2. Rewrite the query if possible
      // 3. Cache the optimized version
      // For now, we just log the optimization opportunity
    }
  }

  List<String> _detectMissingIndexes(String sql) {
    final missingIndexes = <String>[];

    final tableMatch =
        RegExp(r'FROM\s+(\w+)', caseSensitive: false).firstMatch(sql);
    if (tableMatch == null) return missingIndexes;

    final tableName = tableMatch.group(1);
    if (tableName == null) return missingIndexes;

    return detectMissingIndexes(sql, tableName);
  }

  bool _hasFunctionInWhere(String sql) {
    final whereMatch =
        RegExp(r'WHERE\s+(.+?)(?:ORDER|GROUP|LIMIT|$)', caseSensitive: false)
            .firstMatch(sql);

    if (whereMatch != null) {
      final whereClause = whereMatch.group(1) ?? '';
      final functions = [
        'UPPER',
        'LOWER',
        'SUBSTR',
        'LENGTH',
        'TRIM',
        'DATE',
        'DATETIME',
      ];
      return functions.any((func) => whereClause.toUpperCase().contains(func));
    }

    return false;
  }

  int _estimateExecutionTime(int complexityScore) {
    return 1 + (complexityScore * 0.5).round();
  }
}
