// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/local_storage_cache.dart';

void main() {
  group('QueryOptimizer', () {
    late QueryOptimizer optimizer;
    late Map<String, TableSchema> schemas;

    setUp(() {
      // Create test schemas
      schemas = {
        'users': const TableSchema(
          name: 'users',
          fields: [
            FieldSchema(name: 'id', type: DataType.integer, nullable: false),
            FieldSchema(name: 'name', type: DataType.text, nullable: false),
            FieldSchema(name: 'email', type: DataType.text, nullable: false),
            FieldSchema(name: 'age', type: DataType.integer),
          ],
          indexes: [
            IndexSchema(name: 'idx_users_email', fields: ['email']),
          ],
        ),
        'posts': const TableSchema(
          name: 'posts',
          fields: [
            FieldSchema(name: 'id', type: DataType.integer, nullable: false),
            FieldSchema(
              name: 'user_id',
              type: DataType.integer,
              nullable: false,
            ),
            FieldSchema(name: 'title', type: DataType.text, nullable: false),
            FieldSchema(name: 'content', type: DataType.text, nullable: false),
          ],
          indexes: [
            IndexSchema(name: 'idx_posts_user_id', fields: ['user_id']),
          ],
        ),
      };

      optimizer = QueryOptimizer(schemas: schemas);
    });

    group('analyzeQuery', () {
      test('detects SELECT * usage', () {
        final analysis = optimizer.analyzeQuery('SELECT * FROM users');

        expect(analysis.suggestions, contains(contains('SELECT *')));
        expect(analysis.complexityScore, greaterThan(0));
      });

      test('detects full table scan', () {
        final analysis = optimizer.analyzeQuery('SELECT id, name FROM users');

        expect(analysis.hasFullTableScan, isTrue);
        expect(analysis.suggestions, contains(contains('full table scan')));
      });

      test('detects OR conditions', () {
        final analysis = optimizer.analyzeQuery(
          'SELECT * FROM users WHERE name = ? OR email = ?',
        );

        expect(analysis.suggestions, contains(contains('OR conditions')));
      });

      test('detects leading wildcard in LIKE', () {
        final analysis = optimizer.analyzeQuery(
          "SELECT * FROM users WHERE name LIKE '%john%'",
        );

        expect(analysis.suggestions, contains(contains('Leading wildcard')));
      });

      test('detects functions in WHERE clause', () {
        final analysis = optimizer.analyzeQuery(
          'SELECT * FROM users WHERE UPPER(name) = ?',
        );

        expect(analysis.suggestions, contains(contains('Functions in WHERE')));
      });

      test('detects multiple JOINs', () {
        final analysis = optimizer.analyzeQuery(
          '''
          SELECT * FROM users 
          JOIN posts ON users.id = posts.user_id
          JOIN comments ON posts.id = comments.post_id
          JOIN likes ON posts.id = likes.post_id
          JOIN shares ON posts.id = shares.post_id
          ''',
        );

        expect(analysis.suggestions, contains(contains('JOINs')));
        expect(analysis.complexityScore, greaterThan(30));
      });

      test('detects subqueries', () {
        final analysis = optimizer.analyzeQuery(
          'SELECT * FROM users WHERE id IN (SELECT user_id FROM posts)',
        );

        expect(analysis.suggestions, contains(contains('Subqueries')));
      });

      test('returns low complexity for optimized query', () {
        final analysis = optimizer.analyzeQuery(
          'SELECT id, name FROM users WHERE email = ? LIMIT 10',
        );

        expect(analysis.complexityScore, lessThan(20));
        expect(analysis.hasFullTableScan, isFalse);
      });

      test('estimates execution time based on complexity', () {
        final simpleQuery = optimizer.analyzeQuery(
          'SELECT id FROM users WHERE email = ?',
        );
        final complexQuery = optimizer.analyzeQuery(
          'SELECT * FROM users WHERE UPPER(name) LIKE ? OR email LIKE ?',
        );

        expect(
          complexQuery.estimatedTimeMs,
          greaterThan(simpleQuery.estimatedTimeMs),
        );
      });
    });

    group('detectMissingIndexes', () {
      test('detects missing index on name field', () {
        final missingIndexes = optimizer.detectMissingIndexes(
          'SELECT * FROM users WHERE name = ?',
          'users',
        );

        expect(missingIndexes, contains('name'));
      });

      test('does not report index for indexed field', () {
        final missingIndexes = optimizer.detectMissingIndexes(
          'SELECT * FROM users WHERE email = ?',
          'users',
        );

        expect(missingIndexes, isEmpty);
      });

      test('detects multiple missing indexes', () {
        final missingIndexes = optimizer.detectMissingIndexes(
          'SELECT * FROM users WHERE name = ? AND age > ?',
          'users',
        );

        expect(missingIndexes, contains('name'));
        expect(missingIndexes, contains('age'));
      });

      test('returns empty list for unknown table', () {
        final missingIndexes = optimizer.detectMissingIndexes(
          'SELECT * FROM unknown WHERE field = ?',
          'unknown',
        );

        expect(missingIndexes, isEmpty);
      });
    });

    group('detectFullTableScan', () {
      test('detects SELECT without WHERE or LIMIT', () {
        expect(
          optimizer.detectFullTableScan('SELECT * FROM users'),
          isTrue,
        );
      });

      test('does not detect scan with WHERE clause', () {
        expect(
          optimizer.detectFullTableScan('SELECT * FROM users WHERE id = ?'),
          isFalse,
        );
      });

      test('does not detect scan with LIMIT', () {
        expect(
          optimizer.detectFullTableScan('SELECT * FROM users LIMIT 10'),
          isFalse,
        );
      });

      test('detects UPDATE without WHERE', () {
        expect(
          optimizer.detectFullTableScan('UPDATE users SET name = ?'),
          isTrue,
        );
      });

      test('detects DELETE without WHERE', () {
        expect(
          optimizer.detectFullTableScan('DELETE FROM users'),
          isTrue,
        );
      });
    });

    group('estimateExecutionTime', () {
      test('estimates time for simple query', () {
        final time = optimizer.estimateExecutionTime(
          'SELECT id FROM users WHERE email = ?',
        );

        expect(time, greaterThan(0));
        expect(time, lessThan(50));
      });

      test('estimates higher time for complex query', () {
        final simpleTime = optimizer.estimateExecutionTime(
          'SELECT id FROM users WHERE email = ?',
        );
        final complexTime = optimizer.estimateExecutionTime(
          '''
          SELECT * FROM users 
          JOIN posts ON users.id = posts.user_id
          WHERE UPPER(users.name) LIKE ? OR users.email LIKE ?
          ''',
        );

        expect(complexTime, greaterThan(simpleTime));
      });
    });

    group('recordQueryExecution', () {
      test('records query execution', () {
        optimizer.recordQueryExecution('SELECT * FROM users', 50);

        final stats = optimizer.getQueryStats('SELECT * FROM users');
        expect(stats, isNotNull);
        expect(stats!.executionCount, equals(1));
        expect(stats.totalTimeMs, equals(50));
      });

      test('accumulates multiple executions', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 50)
          ..recordQueryExecution('SELECT * FROM users', 30)
          ..recordQueryExecution('SELECT * FROM users', 40);

        final stats = optimizer.getQueryStats('SELECT * FROM users');
        expect(stats!.executionCount, equals(3));
        expect(stats.totalTimeMs, equals(120));
        expect(stats.averageTimeMs, equals(40.0));
      });

      test('tracks different queries separately', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 50)
          ..recordQueryExecution('SELECT * FROM posts', 30);

        final userStats = optimizer.getQueryStats('SELECT * FROM users');
        final postStats = optimizer.getQueryStats('SELECT * FROM posts');

        expect(userStats!.executionCount, equals(1));
        expect(postStats!.executionCount, equals(1));
      });
    });

    group('getQueryStats', () {
      test('returns null for untracked query', () {
        final stats = optimizer.getQueryStats('SELECT * FROM unknown');
        expect(stats, isNull);
      });

      test('returns stats for tracked query', () {
        optimizer.recordQueryExecution('SELECT * FROM users', 50);

        final stats = optimizer.getQueryStats('SELECT * FROM users');
        expect(stats, isNotNull);
        expect(stats!.sql, equals('SELECT * FROM users'));
      });
    });

    group('getAllQueryStats', () {
      test('returns empty map initially', () {
        final allStats = optimizer.getAllQueryStats();
        expect(allStats, isEmpty);
      });

      test('returns all tracked queries', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 50)
          ..recordQueryExecution('SELECT * FROM posts', 30);

        final allStats = optimizer.getAllQueryStats();
        expect(allStats.length, equals(2));
        expect(allStats.keys, contains('SELECT * FROM users'));
        expect(allStats.keys, contains('SELECT * FROM posts'));
      });

      test('returns unmodifiable map', () {
        optimizer.recordQueryExecution('SELECT * FROM users', 50);

        final allStats = optimizer.getAllQueryStats();
        expect(
          () => allStats['new'] = QueryStats(
            sql: 'new',
            lastExecuted: DateTime.now(),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('getSlowQueries', () {
      test('returns empty list when no slow queries', () {
        optimizer.recordQueryExecution('SELECT * FROM users', 10);

        final slowQueries = optimizer.getSlowQueries();
        expect(slowQueries, isEmpty);
      });

      test('returns slow queries', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 150)
          ..recordQueryExecution('SELECT * FROM posts', 50);

        final slowQueries = optimizer.getSlowQueries();
        expect(slowQueries.length, equals(1));
        expect(slowQueries.first.sql, equals('SELECT * FROM users'));
      });

      test('sorts slow queries by average time descending', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 150)
          ..recordQueryExecution('SELECT * FROM posts', 200)
          ..recordQueryExecution('SELECT * FROM comments', 120);

        final slowQueries = optimizer.getSlowQueries();
        expect(slowQueries.length, equals(3));
        expect(slowQueries[0].sql, equals('SELECT * FROM posts'));
        expect(slowQueries[1].sql, equals('SELECT * FROM users'));
        expect(slowQueries[2].sql, equals('SELECT * FROM comments'));
      });
    });

    group('getFrequentQueries', () {
      test('returns empty list initially', () {
        final frequentQueries = optimizer.getFrequentQueries();
        expect(frequentQueries, isEmpty);
      });

      test('returns most frequent queries', () {
        // Execute queries with different frequencies
        for (var i = 0; i < 10; i++) {
          optimizer.recordQueryExecution('SELECT * FROM users', 10);
        }
        for (var i = 0; i < 5; i++) {
          optimizer.recordQueryExecution('SELECT * FROM posts', 10);
        }
        for (var i = 0; i < 3; i++) {
          optimizer.recordQueryExecution('SELECT * FROM comments', 10);
        }

        final frequentQueries = optimizer.getFrequentQueries();
        expect(frequentQueries.length, equals(3));
        expect(frequentQueries[0].sql, equals('SELECT * FROM users'));
        expect(frequentQueries[1].sql, equals('SELECT * FROM posts'));
        expect(frequentQueries[2].sql, equals('SELECT * FROM comments'));
      });

      test('respects limit parameter', () {
        for (var i = 0; i < 5; i++) {
          optimizer.recordQueryExecution('query_$i', 10);
        }

        final frequentQueries = optimizer.getFrequentQueries(limit: 3);
        expect(frequentQueries.length, equals(3));
      });
    });

    group('clearStats', () {
      test('clears all query statistics', () {
        optimizer
          ..recordQueryExecution('SELECT * FROM users', 50)
          ..recordQueryExecution('SELECT * FROM posts', 30);

        expect(optimizer.getAllQueryStats().length, equals(2));

        optimizer.clearStats();

        expect(optimizer.getAllQueryStats(), isEmpty);
      });
    });

    group('QueryAnalysis', () {
      test('needsOptimization returns true for problematic queries', () {
        final analysis = optimizer.analyzeQuery('SELECT * FROM users');

        expect(analysis.needsOptimization, isTrue);
      });

      test('needsOptimization returns false for optimized queries', () {
        final analysis = optimizer.analyzeQuery(
          'SELECT id, name FROM users WHERE email = ? LIMIT 10',
        );

        expect(analysis.needsOptimization, isFalse);
      });
    });

    group('QueryStats', () {
      test('calculates average time correctly', () {
        final stats = QueryStats(sql: 'test', lastExecuted: DateTime.now())
          ..recordExecution(100)
          ..recordExecution(200)
          ..recordExecution(300);

        expect(stats.averageTimeMs, equals(200.0));
      });

      test('returns 0 average for no executions', () {
        final stats = QueryStats(sql: 'test', lastExecuted: DateTime.now());

        expect(stats.averageTimeMs, equals(0.0));
      });

      test('updates last executed time', () {
        final stats = QueryStats(sql: 'test', lastExecuted: DateTime.now());
        final initialTime = stats.lastExecuted;

        // Wait a bit to ensure time difference
        Future.delayed(const Duration(milliseconds: 10), () {
          stats.recordExecution(50);
          expect(stats.lastExecuted.isAfter(initialTime), isTrue);
        });
      });
    });
  });
}
