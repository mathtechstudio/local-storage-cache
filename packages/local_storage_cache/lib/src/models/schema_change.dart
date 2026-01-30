/// Type of schema change operation.
enum SchemaChangeType {
  /// Table was added.
  tableAdded,

  /// Table was removed.
  tableRemoved,

  /// Table was renamed.
  tableRenamed,

  /// Field was added to a table.
  fieldAdded,

  /// Field was removed from a table.
  fieldRemoved,

  /// Field was renamed.
  fieldRenamed,

  /// Field type was changed.
  fieldTypeChanged,

  /// Field constraints were modified.
  fieldConstraintChanged,

  /// Index was added.
  indexAdded,

  /// Index was removed.
  indexRemoved,

  /// Foreign key was added.
  foreignKeyAdded,

  /// Foreign key was removed.
  foreignKeyRemoved,
}

/// Represents a detected change in database schema.
class SchemaChange {
  /// Creates a schema change with the specified details.
  const SchemaChange({
    required this.type,
    required this.tableName,
    this.oldTableName,
    this.fieldName,
    this.oldFieldName,
    this.oldValue,
    this.newValue,
    this.details,
  });

  /// Type of schema change.
  final SchemaChangeType type;

  /// Table name affected by the change.
  final String tableName;

  /// Old table name (for table renames).
  final String? oldTableName;

  /// Field name affected by the change.
  final String? fieldName;

  /// Old field name (for field renames).
  final String? oldFieldName;

  /// Old value before the change.
  final dynamic oldValue;

  /// New value after the change.
  final dynamic newValue;

  /// Additional details about the change.
  final Map<String, dynamic>? details;

  /// Whether this change requires data migration.
  bool get requiresDataMigration {
    return type == SchemaChangeType.fieldTypeChanged ||
        type == SchemaChangeType.fieldRenamed ||
        type == SchemaChangeType.tableRenamed;
  }

  /// Whether this change is destructive (data loss possible).
  bool get isDestructive {
    return type == SchemaChangeType.tableRemoved ||
        type == SchemaChangeType.fieldRemoved;
  }

  /// Converts the schema change to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'tableName': tableName,
      if (oldTableName != null) 'oldTableName': oldTableName,
      if (fieldName != null) 'fieldName': fieldName,
      if (oldFieldName != null) 'oldFieldName': oldFieldName,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (details != null) 'details': details,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer('SchemaChange(${type.name}')
      ..write(', table: $tableName');
    if (oldTableName != null) buffer.write(', oldTable: $oldTableName');
    if (fieldName != null) buffer.write(', field: $fieldName');
    if (oldFieldName != null) buffer.write(', oldField: $oldFieldName');
    buffer.write(')');
    return buffer.toString();
  }
}
