import 'package:local_storage_cache/src/models/validation_error.dart';

/// Result of a validation operation.
class ValidationResult {
  /// Creates a validation result with the specified status and errors.
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  /// Creates a successful validation result.
  factory ValidationResult.success() {
    return const ValidationResult(isValid: true, errors: []);
  }

  /// Creates a failed validation result with errors.
  factory ValidationResult.failure(List<ValidationError> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }

  /// Creates a failed validation result with a single error.
  factory ValidationResult.singleError(ValidationError error) {
    return ValidationResult(isValid: false, errors: [error]);
  }

  /// Whether the validation passed.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<ValidationError> errors;

  @override
  String toString() {
    if (isValid) return 'ValidationResult: Valid';
    return 'ValidationResult: Invalid (${errors.length} errors)';
  }

  /// Converts the result to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'errors': errors.map((e) => e.toMap()).toList(),
    };
  }
}
