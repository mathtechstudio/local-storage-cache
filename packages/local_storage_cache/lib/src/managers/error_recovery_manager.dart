// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:local_storage_cache/src/enums/error_code.dart';
import 'package:local_storage_cache/src/exceptions/storage_exception.dart';
import 'package:local_storage_cache/src/managers/storage_logger.dart';

/// Configuration for error recovery behavior.
class RecoveryConfig {
  /// Creates a recovery configuration.
  const RecoveryConfig({
    this.maxRetries = 3,
    this.initialDelayMs = 100,
    this.maxDelayMs = 5000,
    this.backoffMultiplier = 2.0,
    this.enableAutoRecovery = true,
    this.backupPath,
  });

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay in milliseconds before first retry.
  final int initialDelayMs;

  /// Maximum delay in milliseconds between retries.
  final int maxDelayMs;

  /// Multiplier for exponential backoff.
  final double backoffMultiplier;

  /// Whether to enable automatic recovery.
  final bool enableAutoRecovery;

  /// Path to backup file for recovery.
  final String? backupPath;
}

/// Manages error recovery and retry logic.
///
/// The ErrorRecoveryManager provides automatic recovery mechanisms for
/// common storage errors including database locks, corruption, and disk issues.
///
/// Example:
/// ```dart
/// final recoveryManager = ErrorRecoveryManager(
///   config: RecoveryConfig(maxRetries: 5),
///   logger: logger,
/// );
///
/// // Execute with automatic retry
/// final result = await recoveryManager.executeWithRetry(() async {
///   return await storage.query('SELECT * FROM users');
/// });
/// ```
class ErrorRecoveryManager {
  /// Creates an error recovery manager.
  ErrorRecoveryManager({
    RecoveryConfig? config,
    StorageLogger? logger,
  })  : config = config ?? const RecoveryConfig(),
        _logger = logger;

  /// Recovery configuration.
  final RecoveryConfig config;

  final StorageLogger? _logger;

  /// Executes an operation with automatic retry on failure.
  ///
  /// Uses exponential backoff for retries.
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
  }) async {
    var attempt = 0;
    var delay = config.initialDelayMs;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Check if we should retry
        final canRetry = shouldRetry?.call(e) ?? _shouldRetryError(e);

        if (!canRetry || attempt >= config.maxRetries) {
          _logger?.error(
            'Operation failed after $attempt attempts',
            e,
            e is Error ? e.stackTrace : null,
          );
          rethrow;
        }

        _logger?.warning(
          'Operation failed (attempt $attempt/${config.maxRetries}), retrying in ${delay}ms...',
          e,
        );

        // Wait before retry
        await Future<void>.delayed(Duration(milliseconds: delay));

        // Calculate next delay with exponential backoff
        delay = (delay * config.backoffMultiplier).toInt();
        if (delay > config.maxDelayMs) {
          delay = config.maxDelayMs;
        }
      }
    }
  }

  /// Handles database lock errors.
  Future<T> handleDatabaseLock<T>(
    Future<T> Function() operation,
  ) async {
    return executeWithRetry(
      operation,
      shouldRetry: (error) {
        if (error is DatabaseException) {
          return error.code == ErrorCode.databaseLocked.code;
        }
        return false;
      },
    );
  }

  /// Attempts to recover from database corruption.
  Future<bool> recoverFromCorruption({
    required String databasePath,
    String? backupPath,
  }) async {
    try {
      _logger?.warning('Attempting to recover from database corruption...');

      // Check if backup exists
      final backup = backupPath ?? config.backupPath;
      if (backup == null) {
        _logger?.error('No backup path provided for corruption recovery');
        return false;
      }

      final backupFile = File(backup);
      if (!await backupFile.exists()) {
        _logger?.error('Backup file not found: $backup');
        return false;
      }

      // Delete corrupted database
      final dbFile = File(databasePath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        _logger?.info('Deleted corrupted database file');
      }

      // Restore from backup
      await backupFile.copy(databasePath);
      _logger?.info('Restored database from backup');

      return true;
    } catch (e, stackTrace) {
      _logger?.error('Corruption recovery failed', e, stackTrace);
      return false;
    }
  }

  /// Handles disk full errors.
  Future<bool> handleDiskFull({
    required Future<void> Function() cleanupOperation,
  }) async {
    try {
      _logger?.warning('Disk full detected, attempting cleanup...');

      // Execute cleanup operation
      await cleanupOperation();

      _logger?.info('Cleanup completed successfully');
      return true;
    } catch (e, stackTrace) {
      _logger?.error('Disk cleanup failed', e, stackTrace);
      return false;
    }
  }

  /// Checks if an error should trigger a retry.
  bool _shouldRetryError(Object error) {
    if (error is DatabaseException) {
      // Retry on lock errors
      if (error.code == ErrorCode.databaseLocked.code) {
        return true;
      }
      // Retry on connection errors
      if (error.code == ErrorCode.connectionFailed.code) {
        return true;
      }
      // Retry on transaction failures
      if (error.code == ErrorCode.transactionFailed.code) {
        return true;
      }
    }

    if (error is SocketException) {
      // Retry on network errors
      return true;
    }

    if (error is TimeoutException) {
      // Retry on timeout
      return true;
    }

    // Don't retry by default
    return false;
  }

  /// Attempts to repair a corrupted database.
  Future<bool> repairDatabase({
    required String databasePath,
    required Future<void> Function() integrityCheck,
    required Future<void> Function() vacuumOperation,
  }) async {
    try {
      _logger?.info('Attempting database repair...');

      // Run integrity check
      try {
        await integrityCheck();
        _logger?.info('Integrity check passed');
      } catch (e) {
        _logger?.warning('Integrity check failed, attempting vacuum...');

        // Try vacuum to repair
        await vacuumOperation();
        _logger?.info('Vacuum completed');

        // Check integrity again
        await integrityCheck();
        _logger?.info('Database repaired successfully');
      }

      return true;
    } catch (e, stackTrace) {
      _logger?.error('Database repair failed', e, stackTrace);
      return false;
    }
  }

  /// Creates a recovery point (backup) before risky operations.
  Future<String?> createRecoveryPoint({
    required String databasePath,
    required String recoveryDir,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recoveryPath = '$recoveryDir/recovery_$timestamp.db';

      final dbFile = File(databasePath);
      if (await dbFile.exists()) {
        await dbFile.copy(recoveryPath);
        _logger?.info('Created recovery point: $recoveryPath');
        return recoveryPath;
      }

      return null;
    } catch (e, stackTrace) {
      _logger?.error('Failed to create recovery point', e, stackTrace);
      return null;
    }
  }

  /// Restores from a recovery point.
  Future<bool> restoreFromRecoveryPoint({
    required String databasePath,
    required String recoveryPath,
  }) async {
    try {
      _logger?.info('Restoring from recovery point: $recoveryPath');

      final recoveryFile = File(recoveryPath);
      if (!await recoveryFile.exists()) {
        _logger?.error('Recovery point not found: $recoveryPath');
        return false;
      }

      // Delete current database
      final dbFile = File(databasePath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Restore from recovery point
      await recoveryFile.copy(databasePath);
      _logger?.info('Restored from recovery point successfully');

      return true;
    } catch (e, stackTrace) {
      _logger?.error('Failed to restore from recovery point', e, stackTrace);
      return false;
    }
  }

  /// Handles permission denied errors.
  Future<bool> handlePermissionDenied({
    required String path,
    required Future<void> Function() requestPermission,
  }) async {
    try {
      _logger?.warning('Permission denied for: $path');
      _logger?.info('Requesting permission...');

      await requestPermission();

      _logger?.info('Permission granted');
      return true;
    } catch (e, stackTrace) {
      _logger?.error('Failed to obtain permission', e, stackTrace);
      return false;
    }
  }
}
