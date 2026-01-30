/// Types of validation errors.
enum ValidationType {
  /// Field is required but missing.
  required,

  /// Field type does not match expected type.
  type,

  /// Field length is invalid.
  length,

  /// Field does not match required pattern.
  pattern,

  /// Field value is not unique.
  unique,

  /// Foreign key constraint violation.
  foreignKey,

  /// Custom validation failed.
  custom,
}

/// Represents a validation error for a field.
class ValidationError {
  /// Creates a validation error with the specified details.
  const ValidationError({
    required this.field,
    required this.message,
    required this.type,
  });

  /// The field that failed validation.
  final String field;

  /// Error message describing the validation failure.
  final String message;

  /// Type of validation that failed.
  final ValidationType type;

  @override
  String toString() => 'ValidationError($field): $message';

  /// Converts the error to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'message': message,
      'type': type.name,
    };
  }
}
