import 'package:local_storage_cache/src/enums/data_type.dart';

/// Type definition for field validators.
typedef FieldValidator = Future<bool> Function(dynamic value);

/// Configuration for vector fields.
class VectorFieldConfig {
  /// Creates a vector field configuration with the specified dimensions and precision.
  const VectorFieldConfig({
    required this.dimensions,
    this.precision = VectorPrecision.float32,
  });

  /// Number of dimensions in the vector.
  final int dimensions;

  /// Precision of vector values.
  final VectorPrecision precision;
}

/// Vector precision types.
enum VectorPrecision {
  /// 16-bit floating point precision.
  float16,

  /// 32-bit floating point precision.
  float32,

  /// 64-bit floating point precision.
  float64,
}

/// Schema definition for a table field.
class FieldSchema {
  /// Creates a field schema with the specified configuration.
  const FieldSchema({
    required this.name,
    required this.type,
    this.fieldId,
    this.nullable = true,
    this.unique = false,
    this.defaultValue,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.validator,
    this.encrypted = false,
    this.vectorConfig,
  });

  /// Creates a text field schema.
  factory FieldSchema.text({
    required String name,
    String? fieldId,
    bool nullable = true,
    bool unique = false,
    String? defaultValue,
    int? minLength,
    int? maxLength,
    String? pattern,
    bool encrypted = false,
  }) {
    return FieldSchema(
      name: name,
      fieldId: fieldId,
      type: DataType.text,
      nullable: nullable,
      unique: unique,
      defaultValue: defaultValue,
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
      encrypted: encrypted,
    );
  }

  /// Creates an integer field schema.
  factory FieldSchema.integer({
    required String name,
    String? fieldId,
    bool nullable = true,
    bool unique = false,
    int? defaultValue,
  }) {
    return FieldSchema(
      name: name,
      fieldId: fieldId,
      type: DataType.integer,
      nullable: nullable,
      unique: unique,
      defaultValue: defaultValue,
    );
  }

  /// Creates a boolean field schema.
  factory FieldSchema.boolean({
    required String name,
    String? fieldId,
    bool nullable = true,
    bool? defaultValue,
  }) {
    return FieldSchema(
      name: name,
      fieldId: fieldId,
      type: DataType.boolean,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Creates a datetime field schema.
  factory FieldSchema.datetime({
    required String name,
    String? fieldId,
    bool nullable = true,
    DateTime? defaultValue,
  }) {
    return FieldSchema(
      name: name,
      fieldId: fieldId,
      type: DataType.datetime,
      nullable: nullable,
      defaultValue: defaultValue,
    );
  }

  /// Field name.
  final String name;

  /// Unique field identifier for rename detection.
  final String? fieldId;

  /// Data type of the field.
  final DataType type;

  /// Whether the field can be null.
  final bool nullable;

  /// Whether the field must be unique.
  final bool unique;

  /// Default value for the field.
  final dynamic defaultValue;

  /// Minimum length (for text fields).
  final int? minLength;

  /// Maximum length (for text fields).
  final int? maxLength;

  /// Regex pattern for validation (for text fields).
  final String? pattern;

  /// Custom validator function.
  final FieldValidator? validator;

  /// Whether this field should be encrypted.
  final bool encrypted;

  /// Vector field configuration (for vector type).
  final VectorFieldConfig? vectorConfig;

  /// Converts the field schema to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (fieldId != null) 'fieldId': fieldId,
      'type': type.name,
      'nullable': nullable,
      'unique': unique,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (minLength != null) 'minLength': minLength,
      if (maxLength != null) 'maxLength': maxLength,
      if (pattern != null) 'pattern': pattern,
      'encrypted': encrypted,
      if (vectorConfig != null)
        'vectorConfig': {
          'dimensions': vectorConfig!.dimensions,
          'precision': vectorConfig!.precision.name,
        },
    };
  }
}
