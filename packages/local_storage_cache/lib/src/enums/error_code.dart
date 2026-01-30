// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

/// Error codes for storage exceptions.
enum ErrorCode {
  // Database errors (1xxx)
  /// Database initialization failed.
  databaseInitFailed('DB_INIT_FAILED', 1001),

  /// Database is locked by another process.
  databaseLocked('DB_LOCKED', 1002),

  /// Database file is corrupted.
  databaseCorrupted('DB_CORRUPTED', 1003),

  /// Database query failed.
  queryFailed('QUERY_FAILED', 1004),

  /// Database transaction failed.
  transactionFailed('TRANSACTION_FAILED', 1005),

  /// Database connection failed.
  connectionFailed('CONNECTION_FAILED', 1006),

  // Encryption errors (2xxx)
  /// Encryption key is invalid.
  invalidEncryptionKey('INVALID_KEY', 2001),

  /// Encryption operation failed.
  encryptionFailed('ENCRYPTION_FAILED', 2002),

  /// Decryption operation failed.
  decryptionFailed('DECRYPTION_FAILED', 2003),

  /// Biometric authentication failed.
  biometricAuthFailed('BIOMETRIC_AUTH_FAILED', 2004),

  /// Key storage failed.
  keyStorageFailed('KEY_STORAGE_FAILED', 2005),

  // Validation errors (3xxx)
  /// Field validation failed.
  validationFailed('VALIDATION_FAILED', 3001),

  /// Required field is missing.
  requiredFieldMissing('REQUIRED_FIELD_MISSING', 3002),

  /// Field value is invalid.
  invalidFieldValue('INVALID_FIELD_VALUE', 3003),

  /// Unique constraint violated.
  uniqueConstraintViolated('UNIQUE_CONSTRAINT_VIOLATED', 3004),

  /// Foreign key constraint violated.
  foreignKeyViolated('FOREIGN_KEY_VIOLATED', 3005),

  // Migration errors (4xxx)
  /// Migration failed.
  migrationFailed('MIGRATION_FAILED', 4001),

  /// Schema version mismatch.
  schemaVersionMismatch('SCHEMA_VERSION_MISMATCH', 4002),

  /// Migration rollback failed.
  rollbackFailed('ROLLBACK_FAILED', 4003),

  // Space errors (5xxx)
  /// Space not found.
  spaceNotFound('SPACE_NOT_FOUND', 5001),

  /// Space already exists.
  spaceAlreadyExists('SPACE_ALREADY_EXISTS', 5002),

  /// Space operation failed.
  spaceOperationFailed('SPACE_OPERATION_FAILED', 5003),

  // Storage errors (6xxx)
  /// Disk is full.
  diskFull('DISK_FULL', 6001),

  /// Permission denied.
  permissionDenied('PERMISSION_DENIED', 6002),

  /// File not found.
  fileNotFound('FILE_NOT_FOUND', 6003),

  /// Storage not initialized.
  notInitialized('NOT_INITIALIZED', 6004),

  /// Backup operation failed.
  backupFailed('BACKUP_FAILED', 6005),

  /// Restore operation failed.
  restoreFailed('RESTORE_FAILED', 6006),

  // Cache errors (7xxx)
  /// Cache operation failed.
  cacheOperationFailed('CACHE_OPERATION_FAILED', 7001),

  /// Cache is full.
  cacheFull('CACHE_FULL', 7002),

  // Query errors (8xxx)
  /// Invalid query syntax.
  invalidQuerySyntax('INVALID_QUERY_SYNTAX', 8001),

  /// Query timeout.
  queryTimeout('QUERY_TIMEOUT', 8002),

  /// Too many results.
  tooManyResults('TOO_MANY_RESULTS', 8003);

  const ErrorCode(this.code, this.numericCode);

  /// String representation of the error code.
  final String code;

  /// Numeric representation of the error code.
  final int numericCode;

  @override
  String toString() => code;
}
