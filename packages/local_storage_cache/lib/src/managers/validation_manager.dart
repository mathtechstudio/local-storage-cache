import 'dart:async';

import 'package:local_storage_cache/src/enums/data_type.dart';
import 'package:local_storage_cache/src/models/validation_error.dart';
import 'package:local_storage_cache/src/models/validation_result.dart';
import 'package:local_storage_cache/src/schema/field_schema.dart';
import 'package:local_storage_cache/src/schema/foreign_key_schema.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';

/// Manages data validation based on table schemas.
class ValidationManager {
  /// Creates a validation manager with the specified database executor.
  ValidationManager({
    required this.executeRawQuery,
  });

  /// Function to execute raw SQL queries.
  final Future<List<Map<String, dynamic>>> Function(
    String sql, [
    List<dynamic>? arguments,
  ]) executeRawQuery;

  final Map<String, TableSchema> _schemas = {};

  /// Registers a table schema for validation.
  void registerSchema(TableSchema schema) {
    _schemas[schema.name] = schema;
  }

  /// Registers multiple table schemas.
  void registerSchemas(List<TableSchema> schemas) {
    for (final schema in schemas) {
      registerSchema(schema);
    }
  }

  /// Validates data against a table schema.
  Future<ValidationResult> validate(
    String tableName,
    Map<String, dynamic> data, {
    bool isUpdate = false,
    dynamic existingId,
  }) async {
    final schema = _schemas[tableName];
    if (schema == null) {
      return ValidationResult.singleError(
        ValidationError(
          field: tableName,
          message: 'No schema registered for table "$tableName"',
          type: ValidationType.custom,
        ),
      );
    }

    final errors = <ValidationError>[];

    // Validate each field
    for (final field in schema.fields) {
      final value = data[field.name];

      // Check required fields (nullable = false)
      if (!field.nullable && value == null && !isUpdate) {
        errors.add(
          ValidationError(
            field: field.name,
            message: 'Field "${field.name}" is required',
            type: ValidationType.required,
          ),
        );
        continue;
      }

      // Skip validation if value is null and field is nullable
      if (value == null && field.nullable) {
        continue;
      }

      // Type validation
      final typeError = _validateType(field, value);
      if (typeError != null) {
        errors.add(typeError);
        continue;
      }

      // Length validation (for text fields)
      if (field.type == DataType.text && value is String) {
        final lengthError = _validateLength(field, value);
        if (lengthError != null) {
          errors.add(lengthError);
        }
      }

      // Pattern validation (for text fields)
      if (field.pattern != null && value is String) {
        final patternError = _validatePattern(field, value);
        if (patternError != null) {
          errors.add(patternError);
        }
      }

      // Unique constraint validation
      if (field.unique && value != null) {
        final uniqueError = await _validateUnique(
          tableName,
          field,
          value,
          existingId: existingId,
        );
        if (uniqueError != null) {
          errors.add(uniqueError);
        }
      }

      // Custom validator
      if (field.validator != null && value != null) {
        final customError = await _validateCustom(field, value);
        if (customError != null) {
          errors.add(customError);
        }
      }
    }

    // Foreign key validation
    for (final fk in schema.foreignKeys) {
      final value = data[fk.field];
      if (value != null) {
        final fkError = await _validateForeignKey(fk, value);
        if (fkError != null) {
          errors.add(fkError);
        }
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validates a batch of data records.
  Future<List<ValidationResult>> validateBatch(
    String tableName,
    List<Map<String, dynamic>> dataList,
  ) async {
    final results = <ValidationResult>[];

    for (final data in dataList) {
      final result = await validate(tableName, data);
      results.add(result);
    }

    return results;
  }

  /// Validates field type.
  ValidationError? _validateType(FieldSchema field, dynamic value) {
    if (value == null) return null;

    var isValid = false;

    switch (field.type) {
      case DataType.integer:
        isValid = value is int;
      case DataType.real:
        isValid = value is double || value is num;
      case DataType.text:
        isValid = value is String;
      case DataType.blob:
        isValid = value is List<int>;
      case DataType.boolean:
        isValid = value is bool;
      case DataType.datetime:
        isValid = value is DateTime || value is String;
      case DataType.json:
        isValid = value is Map || value is List || value is String;
      case DataType.vector:
        isValid = value is List;
    }

    if (!isValid) {
      return ValidationError(
        field: field.name,
        message:
            'Field "${field.name}" must be of type ${field.type.name}, got ${value.runtimeType}',
        type: ValidationType.type,
      );
    }

    return null;
  }

  /// Validates field length.
  ValidationError? _validateLength(FieldSchema field, String value) {
    if (field.minLength != null && value.length < field.minLength!) {
      return ValidationError(
        field: field.name,
        message:
            'Field "${field.name}" must be at least ${field.minLength} characters',
        type: ValidationType.length,
      );
    }

    if (field.maxLength != null && value.length > field.maxLength!) {
      return ValidationError(
        field: field.name,
        message:
            'Field "${field.name}" must be at most ${field.maxLength} characters',
        type: ValidationType.length,
      );
    }

    return null;
  }

  /// Validates field pattern.
  ValidationError? _validatePattern(FieldSchema field, String value) {
    if (field.pattern == null) return null;

    final regex = RegExp(field.pattern!);
    if (!regex.hasMatch(value)) {
      return ValidationError(
        field: field.name,
        message: 'Field "${field.name}" does not match required pattern',
        type: ValidationType.pattern,
      );
    }

    return null;
  }

  /// Validates unique constraint.
  Future<ValidationError?> _validateUnique(
    String tableName,
    FieldSchema field,
    dynamic value, {
    dynamic existingId,
  }) async {
    try {
      var sql =
          'SELECT COUNT(*) as count FROM $tableName WHERE ${field.name} = ?';
      final args = [value];

      // Exclude current record if updating
      if (existingId != null) {
        sql += ' AND id != ?';
        args.add(existingId);
      }

      final results = await executeRawQuery(sql, args);

      if (results.isNotEmpty) {
        final count = results.first['count'] as int? ?? 0;
        if (count > 0) {
          return ValidationError(
            field: field.name,
            message: 'Field "${field.name}" must be unique',
            type: ValidationType.unique,
          );
        }
      }
    } catch (_) {
      // If query fails, skip unique validation
    }

    return null;
  }

  /// Validates foreign key constraint.
  Future<ValidationError?> _validateForeignKey(
    ForeignKeySchema fk,
    dynamic value,
  ) async {
    try {
      final sql =
          'SELECT COUNT(*) as count FROM ${fk.referenceTable} WHERE ${fk.referenceField} = ?';
      final results = await executeRawQuery(sql, [value]);

      if (results.isNotEmpty) {
        final count = results.first['count'] as int? ?? 0;
        if (count == 0) {
          return ValidationError(
            field: fk.field,
            message:
                'Foreign key constraint failed: referenced record does not exist',
            type: ValidationType.foreignKey,
          );
        }
      }
    } catch (_) {
      // If query fails, skip foreign key validation
    }

    return null;
  }

  /// Validates using custom validator.
  Future<ValidationError?> _validateCustom(
    FieldSchema field,
    dynamic value,
  ) async {
    if (field.validator == null) return null;

    try {
      final isValid = await field.validator!(value);
      if (!isValid) {
        return ValidationError(
          field: field.name,
          message: 'Field "${field.name}" failed custom validation',
          type: ValidationType.custom,
        );
      }
    } catch (e) {
      return ValidationError(
        field: field.name,
        message: 'Custom validation error: $e',
        type: ValidationType.custom,
      );
    }

    return null;
  }

  /// Gets the schema for a table.
  TableSchema? getSchema(String tableName) {
    return _schemas[tableName];
  }

  /// Checks if a schema is registered.
  bool hasSchema(String tableName) {
    return _schemas.containsKey(tableName);
  }

  /// Unregisters a schema.
  void unregisterSchema(String tableName) {
    _schemas.remove(tableName);
  }

  /// Clears all registered schemas.
  void clearSchemas() {
    _schemas.clear();
  }

  /// Gets all registered table names.
  List<String> getRegisteredTables() {
    return _schemas.keys.toList();
  }
}
