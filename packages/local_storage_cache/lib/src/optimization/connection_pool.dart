// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:collection';

/// Represents a database connection in the pool.
class PooledConnection {
  /// Creates a pooled connection.
  PooledConnection({
    required this.id,
    required this.createdAt,
    this.lastUsedAt,
  });

  /// Unique identifier for this connection.
  final String id;

  /// When the connection was created.
  final DateTime createdAt;

  /// When the connection was last used.
  DateTime? lastUsedAt;

  /// Whether the connection is currently in use.
  bool isInUse = false;

  /// Whether the connection is healthy.
  bool isHealthy = true;

  /// Number of times this connection has been used.
  int useCount = 0;

  /// Marks the connection as used.
  void markUsed() {
    lastUsedAt = DateTime.now();
    useCount++;
    isInUse = true;
  }

  /// Marks the connection as released.
  void markReleased() {
    isInUse = false;
  }

  /// Age of the connection in milliseconds.
  int get ageMs => DateTime.now().difference(createdAt).inMilliseconds;

  /// Idle time in milliseconds.
  int get idleMs {
    if (lastUsedAt == null) return ageMs;
    return DateTime.now().difference(lastUsedAt!).inMilliseconds;
  }
}

/// Configuration for connection pool.
class ConnectionPoolConfig {
  /// Creates connection pool configuration.
  const ConnectionPoolConfig({
    this.minConnections = 1,
    this.maxConnections = 10,
    this.connectionTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(minutes: 10),
    this.maxConnectionAge = const Duration(hours: 1),
    this.healthCheckInterval = const Duration(minutes: 5),
  });

  /// Minimum number of connections to maintain.
  final int minConnections;

  /// Maximum number of connections allowed.
  final int maxConnections;

  /// Timeout for acquiring a connection.
  final Duration connectionTimeout;

  /// Maximum idle time before closing a connection.
  final Duration idleTimeout;

  /// Maximum age of a connection before recycling.
  final Duration maxConnectionAge;

  /// Interval for health checks.
  final Duration healthCheckInterval;
}

/// Manages a pool of database connections.
///
/// The ConnectionPool maintains a pool of reusable database connections
/// to improve performance by avoiding the overhead of creating new
/// connections for each operation.
class ConnectionPool {
  /// Creates a connection pool with the specified configuration.
  ConnectionPool({
    required Future<PooledConnection> Function() connectionFactory,
    ConnectionPoolConfig? config,
    Future<void> Function(PooledConnection)? connectionDisposer,
    Future<bool> Function(PooledConnection)? healthChecker,
  })  : _config = config ?? const ConnectionPoolConfig(),
        _connectionFactory = connectionFactory,
        _connectionDisposer = connectionDisposer,
        _healthChecker = healthChecker;

  final ConnectionPoolConfig _config;
  final Future<PooledConnection> Function() _connectionFactory;
  final Future<void> Function(PooledConnection)? _connectionDisposer;
  final Future<bool> Function(PooledConnection)? _healthChecker;

  final Queue<PooledConnection> _availableConnections = Queue();
  final Set<PooledConnection> _inUseConnections = {};
  final Queue<Completer<PooledConnection>> _waitingQueue = Queue();

  Timer? _healthCheckTimer;
  bool _isInitialized = false;
  bool _isShuttingDown = false;

  /// Initializes the connection pool.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Create minimum connections
    for (var i = 0; i < _config.minConnections; i++) {
      final connection = await _createConnection();
      _availableConnections.add(connection);
    }

    // Start health check timer
    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthCheck(),
    );

    _isInitialized = true;
  }

  /// Acquires a connection from the pool.
  Future<PooledConnection> acquire() async {
    if (!_isInitialized) {
      throw StateError('Connection pool not initialized');
    }

    if (_isShuttingDown) {
      throw StateError('Connection pool is shutting down');
    }

    // Try to get an available connection
    if (_availableConnections.isNotEmpty) {
      final connection = _availableConnections.removeFirst()..markUsed();
      _inUseConnections.add(connection);
      return connection;
    }

    // Try to create a new connection if under max limit
    if (_totalConnections < _config.maxConnections) {
      final connection = await _createConnection();
      connection.markUsed();
      _inUseConnections.add(connection);
      return connection;
    }

    // Wait for a connection to become available
    final completer = Completer<PooledConnection>();
    _waitingQueue.add(completer);

    return completer.future.timeout(
      _config.connectionTimeout,
      onTimeout: () {
        _waitingQueue.remove(completer);
        throw TimeoutException(
          'Timeout waiting for connection',
          _config.connectionTimeout,
        );
      },
    );
  }

  /// Releases a connection back to the pool.
  Future<void> release(PooledConnection connection) async {
    if (!_inUseConnections.contains(connection)) {
      return; // Connection not from this pool or already released
    }

    _inUseConnections.remove(connection);
    connection.markReleased();

    // Check if connection should be recycled
    if (_shouldRecycleConnection(connection)) {
      await _disposeConnection(connection);
      return;
    }

    // If there are waiting requests, give them the connection
    if (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeFirst();
      connection.markUsed();
      _inUseConnections.add(connection);
      completer.complete(connection);
      return;
    }

    // Return to available pool
    _availableConnections.add(connection);

    // Trim excess connections
    await _trimExcessConnections();
  }

  /// Gets pool statistics.
  Map<String, dynamic> getStats() {
    return {
      'totalConnections': _totalConnections,
      'availableConnections': _availableConnections.length,
      'inUseConnections': _inUseConnections.length,
      'waitingRequests': _waitingQueue.length,
      'minConnections': _config.minConnections,
      'maxConnections': _config.maxConnections,
    };
  }

  /// Shuts down the connection pool.
  Future<void> shutdown() async {
    if (_isShuttingDown) return;

    _isShuttingDown = true;
    _healthCheckTimer?.cancel();

    // Reject all waiting requests
    while (_waitingQueue.isNotEmpty) {}

    // Close all available connections
    while (_availableConnections.isNotEmpty) {
      final connection = _availableConnections.removeFirst();
      await _disposeConnection(connection);
    }

    // Note: In-use connections will be closed when released
  }

  Future<PooledConnection> _createConnection() async {
    final connection = await _connectionFactory();
    connection.id;
    return connection;
  }

  Future<void> _disposeConnection(PooledConnection connection) async {
    if (_connectionDisposer != null) {
      await _connectionDisposer(connection);
    }
  }

  bool _shouldRecycleConnection(PooledConnection connection) {
    // Recycle if unhealthy
    if (!connection.isHealthy) return true;

    // Recycle if too old
    if (connection.ageMs > _config.maxConnectionAge.inMilliseconds) {
      return true;
    }

    // Recycle if idle too long
    if (connection.idleMs > _config.idleTimeout.inMilliseconds) {
      return true;
    }

    return false;
  }

  Future<void> _trimExcessConnections() async {
    while (_availableConnections.length > _config.minConnections) {
      final connection = _availableConnections.removeLast();
      if (_shouldRecycleConnection(connection)) {
        await _disposeConnection(connection);
      } else {
        _availableConnections.add(connection);
        break;
      }
    }
  }

  Future<void> _performHealthCheck() async {
    if (_healthChecker == null) return;

    // Check available connections
    final unhealthyConnections = <PooledConnection>[];

    for (final connection in _availableConnections) {
      final isHealthy = await _healthChecker(connection);
      if (!isHealthy) {
        connection.isHealthy = false;
        unhealthyConnections.add(connection);
      }
    }

    // Remove unhealthy connections
    for (final connection in unhealthyConnections) {
      _availableConnections.remove(connection);
      await _disposeConnection(connection);
    }

    // Ensure minimum connections
    while (_availableConnections.length < _config.minConnections &&
        _totalConnections < _config.maxConnections) {
      final connection = await _createConnection();
      _availableConnections.add(connection);
    }
  }

  int get _totalConnections =>
      _availableConnections.length + _inUseConnections.length;
}
