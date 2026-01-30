// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:local_storage_cache/src/enums/log_level.dart';

/// Custom logger interface.
abstract class CustomLogger {
  /// Logs a message.
  void log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]);
}

/// Default console logger implementation.
class ConsoleLogger implements CustomLogger {
  @override
  void log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();

    // ignore: avoid_print
    print('[$timestamp] [$levelStr] $message');

    if (error != null) {
      // ignore: avoid_print
      print('Error: $error');
    }

    if (stackTrace != null) {
      // ignore: avoid_print
      print('Stack trace:\n$stackTrace');
    }
  }
}

/// Manages logging for storage operations.
///
/// The StorageLogger provides configurable logging with support for
/// different log levels and custom logger implementations.
///
/// Example:
/// ```dart
/// final logger = StorageLogger(
///   minLevel: LogLevel.info,
///   customLogger: MyCustomLogger(),
/// );
///
/// logger.info('Database initialized');
/// logger.error('Query failed', error, stackTrace);
/// ```
class StorageLogger {
  /// Creates a storage logger.
  StorageLogger({
    this.minLevel = LogLevel.info,
    CustomLogger? customLogger,
  }) : _customLogger = customLogger ?? ConsoleLogger();

  /// Minimum log level to output.
  final LogLevel minLevel;

  final CustomLogger _customLogger;

  /// Logs a debug message.
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Logs an info message.
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Logs a warning message.
  void warning(String message, [Object? error]) {
    _log(LogLevel.warning, message, error);
  }

  /// Logs an error message.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Logs a query execution.
  void logQuery(String sql, int executionTimeMs, {int? resultCount}) {
    if (_shouldLog(LogLevel.debug)) {
      final message = 'Query executed in ${executionTimeMs}ms: $sql';
      final details =
          resultCount != null ? ' (returned $resultCount rows)' : '';
      debug(message + details);
    }
  }

  /// Logs a performance warning.
  void logPerformance(String operation, int timeMs, {int? threshold}) {
    final effectiveThreshold = threshold ?? 100;
    if (timeMs > effectiveThreshold) {
      warning(
        'Slow operation: $operation took ${timeMs}ms (threshold: ${effectiveThreshold}ms)',
      );
    }
  }

  /// Logs a cache operation.
  void logCache(String operation, String key, {bool hit = false}) {
    if (_shouldLog(LogLevel.debug)) {
      final status = hit ? 'HIT' : 'MISS';
      debug('Cache $status: $operation for key "$key"');
    }
  }

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_shouldLog(level)) {
      _customLogger.log(level, message, error, stackTrace);
    }
  }

  bool _shouldLog(LogLevel level) {
    return level.index >= minLevel.index;
  }
}
