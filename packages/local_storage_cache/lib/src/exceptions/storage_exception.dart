/// Base exception for all storage-related errors.
abstract class StorageException implements Exception {
  /// Creates a storage exception with the specified message and optional details.
  const StorageException(this.message, {this.code, this.details});

  /// The error message describing what went wrong.
  final String message;

  /// Optional error code for categorizing the error.
  final String? code;

  /// Optional additional details about the error.
  final dynamic details;

  @override
  String toString() =>
      'StorageException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown for database-related errors.
class DatabaseException extends StorageException {
  /// Creates a database exception with the specified message and optional details.
  const DatabaseException(super.message, {super.code, super.details});

  @override
  String toString() =>
      'DatabaseException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown for encryption-related errors.
class EncryptionException extends StorageException {
  /// Creates an encryption exception with the specified message and optional details.
  const EncryptionException(super.message, {super.code, super.details});

  @override
  String toString() =>
      'EncryptionException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown for validation errors.
class ValidationException extends StorageException {
  /// Creates a validation exception with the specified message and list of errors.
  const ValidationException(super.message, this.errors, {super.code})
      : super(details: errors);

  /// List of validation errors that occurred.
  final List<dynamic> errors;

  @override
  String toString() =>
      'ValidationException: $message (${errors.length} errors)';
}

/// Exception thrown for migration errors.
class MigrationException extends StorageException {
  /// Creates a migration exception with the specified message and optional details.
  const MigrationException(super.message, {super.code, super.details});

  @override
  String toString() =>
      'MigrationException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown for space-related errors.
class SpaceException extends StorageException {
  /// Creates a space exception with the specified message and optional details.
  const SpaceException(super.message, {super.code, super.details});

  @override
  String toString() =>
      'SpaceException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown for query-related errors.
class QueryException extends StorageException {
  /// Creates a query exception with the specified message and optional details.
  const QueryException(super.message, {super.code, super.details});

  @override
  String toString() =>
      'QueryException: $message${code != null ? ' (code: $code)' : ''}';
}
