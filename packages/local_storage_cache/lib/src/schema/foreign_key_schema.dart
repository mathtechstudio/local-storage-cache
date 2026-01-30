/// Foreign key actions.
enum ForeignKeyAction {
  /// No action on update/delete.
  noAction,

  /// Restrict update/delete if referenced.
  restrict,

  /// Set field to null on update/delete.
  setNull,

  /// Set field to default value on update/delete.
  setDefault,

  /// Cascade update/delete to referencing rows.
  cascade,
}

/// Schema definition for a foreign key constraint.
class ForeignKeySchema {
  /// Creates a foreign key schema with the specified configuration.
  const ForeignKeySchema({
    required this.field,
    required this.referenceTable,
    required this.referenceField,
    this.onUpdate = ForeignKeyAction.noAction,
    this.onDelete = ForeignKeyAction.noAction,
  });

  /// The field in this table that references another table.
  final String field;

  /// The table being referenced.
  final String referenceTable;

  /// The field in the referenced table.
  final String referenceField;

  /// Action to take on update.
  final ForeignKeyAction onUpdate;

  /// Action to take on delete.
  final ForeignKeyAction onDelete;

  /// Converts the foreign key schema to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'referenceTable': referenceTable,
      'referenceField': referenceField,
      'onUpdate': onUpdate.name,
      'onDelete': onDelete.name,
    };
  }
}
