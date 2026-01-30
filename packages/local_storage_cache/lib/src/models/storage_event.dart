// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

/// Base class for all storage events.
abstract class StorageEvent {
  /// Creates a storage event.
  const StorageEvent({
    required this.timestamp,
    required this.type,
  });

  /// When the event occurred.
  final DateTime timestamp;

  /// Type of event.
  final StorageEventType type;
}

/// Types of storage events.
enum StorageEventType {
  /// Storage engine initialized.
  initialized,

  /// Data was inserted.
  dataInserted,

  /// Data was updated.
  dataUpdated,

  /// Data was deleted.
  dataDeleted,

  /// Cache entry expired.
  cacheExpired,

  /// Cache was cleared.
  cacheCleared,

  /// Query was executed.
  queryExecuted,

  /// Error occurred.
  error,

  /// Backup started.
  backupStarted,

  /// Backup completed.
  backupCompleted,

  /// Restore started.
  restoreStarted,

  /// Restore completed.
  restoreCompleted,
}

/// Event emitted when data changes.
class DataChangeEvent extends StorageEvent {
  /// Creates a data change event.
  const DataChangeEvent({
    required super.timestamp,
    required super.type,
    required this.tableName,
    required this.space,
    this.recordId,
    this.data,
  });

  /// Table that was modified.
  final String tableName;

  /// Space where the change occurred.
  final String space;

  /// ID of the affected record (if applicable).
  final dynamic recordId;

  /// Data that was changed (if applicable).
  final Map<String, dynamic>? data;
}

/// Event emitted when cache operations occur.
class CacheEvent extends StorageEvent {
  /// Creates a cache event.
  const CacheEvent({
    required super.timestamp,
    required super.type,
    required this.key,
    this.reason,
  });

  /// Cache key.
  final String key;

  /// Reason for the event (e.g., "TTL expired", "Manual clear").
  final String? reason;
}

/// Event emitted when queries are executed.
class QueryEvent extends StorageEvent {
  /// Creates a query event.
  const QueryEvent({
    required super.timestamp,
    required this.sql,
    required this.executionTimeMs,
    this.resultCount,
    this.error,
  }) : super(type: StorageEventType.queryExecuted);

  /// SQL query that was executed.
  final String sql;

  /// Execution time in milliseconds.
  final int executionTimeMs;

  /// Number of results returned.
  final int? resultCount;

  /// Error if query failed.
  final String? error;
}

/// Event emitted when errors occur.
class ErrorEvent extends StorageEvent {
  /// Creates an error event.
  const ErrorEvent({
    required super.timestamp,
    required this.error,
    required this.stackTrace,
    this.context,
  }) : super(type: StorageEventType.error);

  /// The error that occurred.
  final Object error;

  /// Stack trace.
  final StackTrace stackTrace;

  /// Additional context about the error.
  final Map<String, dynamic>? context;
}

/// Event emitted for backup/restore operations.
class BackupRestoreEvent extends StorageEvent {
  /// Creates a backup/restore event.
  const BackupRestoreEvent({
    required super.timestamp,
    required super.type,
    required this.filePath,
    this.success = true,
    this.error,
  });

  /// Path to the backup/restore file.
  final String filePath;

  /// Whether the operation was successful.
  final bool success;

  /// Error message if operation failed.
  final String? error;
}
