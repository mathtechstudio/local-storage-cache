// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/optimization/connection_pool.dart';

void main() {
  group('ConnectionPool', () {
    late ConnectionPool pool;
    var connectionCounter = 0;

    Future<PooledConnection> createConnection() async {
      return PooledConnection(
        id: 'conn_${connectionCounter++}',
        createdAt: DateTime.now(),
      );
    }

    setUp(() {
      connectionCounter = 0;
      pool = ConnectionPool(
        config: const ConnectionPoolConfig(
          minConnections: 2,
          maxConnections: 5,
          connectionTimeout: Duration(seconds: 1),
        ),
        connectionFactory: createConnection,
      );
    });

    tearDown(() async {
      await pool.shutdown();
    });

    group('Initialization', () {
      test('should create minimum connections on initialize', () async {
        await pool.initialize();

        final stats = pool.getStats();
        expect(stats['totalConnections'], equals(2));
        expect(stats['availableConnections'], equals(2));
      });

      test('should not initialize twice', () async {
        await pool.initialize();
        await pool.initialize(); // Should not throw

        final stats = pool.getStats();
        expect(stats['totalConnections'], equals(2));
      });
    });

    group('Connection Acquisition', () {
      test('should acquire connection from pool', () async {
        await pool.initialize();

        final connection = await pool.acquire();

        expect(connection, isNotNull);
        expect(connection.isInUse, isTrue);

        final stats = pool.getStats();
        expect(stats['inUseConnections'], equals(1));
        expect(stats['availableConnections'], equals(1));
      });

      test('should create new connection if pool is empty', () async {
        await pool.initialize();

        final conn1 = await pool.acquire();
        final conn2 = await pool.acquire();
        final conn3 = await pool.acquire();

        expect(conn1.id, isNot(equals(conn2.id)));
        expect(conn2.id, isNot(equals(conn3.id)));

        final stats = pool.getStats();
        expect(stats['totalConnections'], equals(3));
        expect(stats['inUseConnections'], equals(3));
      });

      test('should wait for connection if max reached', () async {
        await pool.initialize();

        // Acquire all connections
        final connections = <PooledConnection>[];
        for (var i = 0; i < 5; i++) {
          connections.add(await pool.acquire());
        }

        // Try to acquire one more (should wait)
        final acquireFuture = pool.acquire();

        // Release one connection
        await pool.release(connections.first);

        // Should now get the connection
        final connection = await acquireFuture;
        expect(connection, isNotNull);
      });

      test('should timeout if no connection available', () async {
        await pool.initialize();

        // Acquire all connections
        for (var i = 0; i < 5; i++) {
          await pool.acquire();
        }

        // Try to acquire one more (should timeout)
        expect(
          () => pool.acquire(),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should throw if not initialized', () async {
        expect(
          () => pool.acquire(),
          throwsStateError,
        );
      });
    });

    group('Connection Release', () {
      test('should release connection back to pool', () async {
        await pool.initialize();

        final connection = await pool.acquire();
        await pool.release(connection);

        expect(connection.isInUse, isFalse);

        final stats = pool.getStats();
        expect(stats['inUseConnections'], equals(0));
        expect(stats['availableConnections'], equals(2));
      });

      test('should give released connection to waiting request', () async {
        await pool.initialize();

        // Acquire all connections
        final connections = <PooledConnection>[];
        for (var i = 0; i < 5; i++) {
          connections.add(await pool.acquire());
        }

        // Start waiting for a connection
        final acquireFuture = pool.acquire();

        // Release a connection
        await pool.release(connections.first);

        // Should get the released connection
        final connection = await acquireFuture;
        expect(connection, isNotNull);
        expect(connection.isInUse, isTrue);
      });

      test('should handle releasing non-pool connection gracefully', () async {
        await pool.initialize();

        final externalConnection = PooledConnection(
          id: 'external',
          createdAt: DateTime.now(),
        );

        // Should not throw
        await pool.release(externalConnection);
      });
    });

    group('Statistics', () {
      test('should return accurate statistics', () async {
        await pool.initialize();

        final conn1 = await pool.acquire();
        final conn2 = await pool.acquire();

        final stats = pool.getStats();

        expect(stats['totalConnections'], equals(2));
        expect(stats['availableConnections'], equals(0));
        expect(stats['inUseConnections'], equals(2));
        expect(stats['waitingRequests'], equals(0));
        expect(stats['minConnections'], equals(2));
        expect(stats['maxConnections'], equals(5));

        await pool.release(conn1);
        await pool.release(conn2);
      });
    });

    group('Shutdown', () {
      test('should close all available connections', () async {
        await pool.initialize();

        await pool.shutdown();

        final stats = pool.getStats();
        expect(stats['availableConnections'], equals(0));
      });

      test('should reject new acquisition requests', () async {
        await pool.initialize();
        await pool.shutdown();

        expect(
          () => pool.acquire(),
          throwsStateError,
        );
      });

      test('should be idempotent', () async {
        await pool.initialize();

        await pool.shutdown();
        await pool.shutdown(); // Should not throw
      });
    });

    group('PooledConnection', () {
      test('should track usage correctly', () {
        final connection = PooledConnection(
          id: 'test',
          createdAt: DateTime.now(),
        );

        expect(connection.useCount, equals(0));
        expect(connection.isInUse, isFalse);

        connection.markUsed();

        expect(connection.useCount, equals(1));
        expect(connection.isInUse, isTrue);
        expect(connection.lastUsedAt, isNotNull);

        connection.markReleased();

        expect(connection.isInUse, isFalse);
      });

      test('should calculate age correctly', () async {
        final connection = PooledConnection(
          id: 'test',
          createdAt: DateTime.now(),
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(connection.ageMs, greaterThanOrEqualTo(100));
      });

      test('should calculate idle time correctly', () async {
        final connection = PooledConnection(
          id: 'test',
          createdAt: DateTime.now(),
        )..markUsed();

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(connection.idleMs, greaterThanOrEqualTo(100));
      });
    });
  });
}
