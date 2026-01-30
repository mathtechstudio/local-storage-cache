// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/optimization/prepared_statement_cache.dart';

void main() {
  group('PreparedStatementCache', () {
    late PreparedStatementCache cache;

    setUp(() {
      cache = PreparedStatementCache(
        config: const PreparedStatementCacheConfig(
          maxSize: 5,
          maxAge: Duration(seconds: 10),
          maxIdleTime: Duration(seconds: 5),
        ),
      );
    });

    group('Statement Caching', () {
      test('should cache new statement', () {
        final statement = cache.getOrCreate('SELECT * FROM users');

        expect(statement, isNotNull);
        expect(statement.sql, equals('SELECT * FROM users'));
        expect(statement.useCount, equals(1));
      });

      test('should reuse cached statement', () {
        final statement1 = cache.getOrCreate('SELECT * FROM users');
        final statement2 = cache.getOrCreate('SELECT * FROM users');

        expect(statement1, equals(statement2));
        expect(statement2.useCount, equals(2));
      });

      test('should cache different statements separately', () {
        final statement1 = cache.getOrCreate('SELECT * FROM users');
        final statement2 = cache.getOrCreate('SELECT * FROM posts');

        expect(statement1.sql, isNot(equals(statement2.sql)));

        final stats = cache.getStats();
        expect(stats['size'], equals(2));
      });

      test('should update last used time on reuse', () async {
        final statement1 = cache.getOrCreate('SELECT * FROM users');
        final firstUsedAt = statement1.lastUsedAt;

        await Future<void>.delayed(const Duration(milliseconds: 100));

        final statement2 = cache.getOrCreate('SELECT * FROM users');
        final secondUsedAt = statement2.lastUsedAt;

        expect(secondUsedAt!.isAfter(firstUsedAt!), isTrue);
      });
    });

    group('Cache Eviction', () {
      test('should evict oldest statement when max size reached', () {
        // Fill cache to max
        for (var i = 0; i < 5; i++) {
          cache.getOrCreate('SELECT * FROM table$i');
        }

        expect(cache.getStats()['size'], equals(5));

        // Add one more (should evict oldest)
        cache.getOrCreate('SELECT * FROM table5');

        expect(cache.getStats()['size'], equals(5));
        expect(cache.contains('SELECT * FROM table0'), isFalse);
        expect(cache.contains('SELECT * FROM table5'), isTrue);
      });

      test('should move statement to end on reuse (LRU)', () {
        // Fill cache
        for (var i = 0; i < 5; i++) {
          cache.getOrCreate('SELECT * FROM table$i');
        }

        // Reuse first statement
        cache
          ..getOrCreate('SELECT * FROM table0')

          // Add new statement (should evict table1, not table0)
          ..getOrCreate('SELECT * FROM table5');

        expect(cache.contains('SELECT * FROM table0'), isTrue);
        expect(cache.contains('SELECT * FROM table1'), isFalse);
      });
    });

    group('Statement Validation', () {
      test('should remove expired statement', () async {
        final cache = PreparedStatementCache(
          config: const PreparedStatementCacheConfig(
            maxAge: Duration(milliseconds: 100),
          ),
        )..getOrCreate('SELECT * FROM users');

        expect(cache.contains('SELECT * FROM users'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(cache.contains('SELECT * FROM users'), isFalse);
      });

      test('should remove idle statement', () async {
        final cache = PreparedStatementCache(
          config: const PreparedStatementCacheConfig(
            maxIdleTime: Duration(milliseconds: 100),
          ),
        )..getOrCreate('SELECT * FROM users');

        expect(cache.contains('SELECT * FROM users'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(cache.contains('SELECT * FROM users'), isFalse);
      });
    });

    group('Cache Operations', () {
      test('contains should return true for cached statement', () {
        cache.getOrCreate('SELECT * FROM users');

        expect(cache.contains('SELECT * FROM users'), isTrue);
        expect(cache.contains('SELECT * FROM posts'), isFalse);
      });

      test('remove should delete statement from cache', () {
        cache.getOrCreate('SELECT * FROM users');

        expect(cache.contains('SELECT * FROM users'), isTrue);

        cache.remove('SELECT * FROM users');

        expect(cache.contains('SELECT * FROM users'), isFalse);
      });

      test('clear should remove all statements', () {
        cache
          ..getOrCreate('SELECT * FROM users')
          ..getOrCreate('SELECT * FROM posts');

        expect(cache.getStats()['size'], equals(2));

        cache.clear();

        expect(cache.getStats()['size'], equals(0));
      });

      test('cleanup should remove expired statements', () async {
        final cache = PreparedStatementCache(
          config: const PreparedStatementCacheConfig(
            maxAge: Duration(milliseconds: 100),
          ),
        )
          ..getOrCreate('SELECT * FROM users')
          ..getOrCreate('SELECT * FROM posts');

        await Future<void>.delayed(const Duration(milliseconds: 150));

        cache.cleanup();

        expect(cache.getStats()['size'], equals(0));
      });
    });

    group('Statistics', () {
      test('should return accurate statistics', () {
        cache.getOrCreate('SELECT * FROM users');
        cache.getOrCreate('SELECT * FROM posts');

        final stats = cache.getStats();

        expect(stats['size'], equals(2));
        expect(stats['maxSize'], equals(5));
        expect(stats['statements'], isA<List<dynamic>>());
        expect(stats['statements'].length, equals(2));
      });

      test('should truncate long SQL in statistics', () {
        final longSql = 'SELECT * FROM users WHERE ${'x' * 100}';
        cache.getOrCreate(longSql);

        final stats = cache.getStats();
        final statements = stats['statements'] as List<dynamic>;

        expect(statements.first['sql'].length, lessThanOrEqualTo(53));
        expect(statements.first['sql'], endsWith('...'));
      });

      test('getMostUsed should return statements sorted by use count', () {
        cache
          ..getOrCreate('SELECT * FROM users')
          ..getOrCreate('SELECT * FROM users')
          ..getOrCreate('SELECT * FROM users')
          ..getOrCreate('SELECT * FROM posts')
          ..getOrCreate('SELECT * FROM posts')
          ..getOrCreate('SELECT * FROM comments');

        final mostUsed = cache.getMostUsed(limit: 2);

        expect(mostUsed.length, equals(2));
        expect(mostUsed[0].sql, equals('SELECT * FROM users'));
        expect(mostUsed[0].useCount, equals(3));
        expect(mostUsed[1].sql, equals('SELECT * FROM posts'));
        expect(mostUsed[1].useCount, equals(2));
      });
    });

    group('CachedStatement', () {
      test('should track usage correctly', () {
        final statement = CachedStatement(
          sql: 'SELECT * FROM users',
          createdAt: DateTime.now(),
        );

        expect(statement.useCount, equals(0));
        expect(statement.lastUsedAt, isNull);

        statement.markUsed();

        expect(statement.useCount, equals(1));
        expect(statement.lastUsedAt, isNotNull);

        statement.markUsed();

        expect(statement.useCount, equals(2));
      });

      test('should calculate age correctly', () async {
        final statement = CachedStatement(
          sql: 'SELECT * FROM users',
          createdAt: DateTime.now(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(statement.ageMs, greaterThanOrEqualTo(100));
      });

      test('should calculate idle time correctly', () async {
        final statement = CachedStatement(
          sql: 'SELECT * FROM users',
          createdAt: DateTime.now(),
        )..markUsed();

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(statement.idleMs, greaterThanOrEqualTo(100));
      });

      test('should use age as idle time if never used', () async {
        final statement = CachedStatement(
          sql: 'SELECT * FROM users',
          createdAt: DateTime.now(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(statement.idleMs, equals(statement.ageMs));
      });
    });
  });
}
