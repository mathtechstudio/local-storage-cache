import 'package:local_storage_cache/src/schema/field_schema.dart';
import 'package:local_storage_cache/src/schema/foreign_key_schema.dart';
import 'package:local_storage_cache/src/schema/index_schema.dart';
import 'package:local_storage_cache/src/schema/primary_key_config.dart';

/// Schema definition for a database table.
class TableSchema {
  /// Creates a table schema with the specified configuration.
  const TableSchema({
    required this.name,
    required this.fields,
    this.tableId,
    this.isGlobal = false,
    this.primaryKeyConfig = const PrimaryKeyConfig(),
    this.indexes = const [],
    this.foreignKeys = const [],
  });

  /// Table name.
  final String name;

  /// Unique table identifier for rename detection.
  final String? tableId;

  /// Whether this is a global table (accessible from all spaces).
  final bool isGlobal;

  /// Primary key configuration.
  final PrimaryKeyConfig primaryKeyConfig;

  /// List of field schemas.
  final List<FieldSchema> fields;

  /// List of index schemas.
  final List<IndexSchema> indexes;

  /// List of foreign key constraints.
  final List<ForeignKeySchema> foreignKeys;

  /// Gets all field names including the primary key.
  List<String> get allFieldNames {
    return [primaryKeyConfig.name, ...fields.map((f) => f.name)];
  }

  /// Gets a field by name.
  FieldSchema? getField(String name) {
    try {
      return fields.firstWhere((f) => f.name == name);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a field exists.
  bool hasField(String name) {
    return fields.any((f) => f.name == name);
  }

  /// Converts the table schema to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (tableId != null) 'tableId': tableId,
      'isGlobal': isGlobal,
      'primaryKeyConfig': primaryKeyConfig.toMap(),
      'fields': fields.map((f) => f.toMap()).toList(),
      'indexes': indexes.map((i) => i.toMap()).toList(),
      'foreignKeys': foreignKeys.map((fk) => fk.toMap()).toList(),
    };
  }
}
