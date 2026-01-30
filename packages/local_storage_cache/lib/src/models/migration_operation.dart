/// Type of migration operation.
enum MigrationOperationType {
  /// Create a new table.
  createTable,

  /// Drop an existing table.
  dropTable,

  /// Rename a table.
  renameTable,

  /// Add a column to a table.
  addColumn,

  /// Drop a column from a table.
  dropColumn,

  /// Rename a column.
  renameColumn,

  /// Modify column type or constraints.
  modifyColumn,

  /// Create an index.
  createIndex,

  /// Drop an index.
  dropIndex,

  /// Add a foreign key constraint.
  addForeignKey,

  /// Drop a foreign key constraint.
  dropForeignKey,

  /// Execute custom SQL.
  customSql,

  /// Copy data between tables/columns.
  copyData,
}

/// Represents a single migration operation to be executed.
class MigrationOperation {
  /// Creates a migration operation with the specified details.
  const MigrationOperation({
    required this.type,
    required this.sql,
    this.tableName,
    this.columnName,
    this.oldName,
    this.newName,
    this.description,
    this.reversible = true,
    this.reverseSql,
  });

  /// Creates a CREATE TABLE operation.
  factory MigrationOperation.createTable({
    required String tableName,
    required String sql,
    String? reverseSql,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.createTable,
      sql: sql,
      tableName: tableName,
      description: 'Create table $tableName',
      reverseSql: reverseSql ?? 'DROP TABLE IF EXISTS $tableName',
    );
  }

  /// Creates a DROP TABLE operation.
  factory MigrationOperation.dropTable({
    required String tableName,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.dropTable,
      sql: 'DROP TABLE IF EXISTS $tableName',
      tableName: tableName,
      description: 'Drop table $tableName',
      reversible: false,
    );
  }

  /// Creates a RENAME TABLE operation.
  factory MigrationOperation.renameTable({
    required String oldName,
    required String newName,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.renameTable,
      sql: 'ALTER TABLE $oldName RENAME TO $newName',
      tableName: newName,
      oldName: oldName,
      newName: newName,
      description: 'Rename table $oldName to $newName',
      reverseSql: 'ALTER TABLE $newName RENAME TO $oldName',
    );
  }

  /// Creates an ADD COLUMN operation.
  factory MigrationOperation.addColumn({
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.addColumn,
      sql: 'ALTER TABLE $tableName ADD COLUMN $columnDefinition',
      tableName: tableName,
      columnName: columnName,
      description: 'Add column $columnName to $tableName',
      reverseSql: 'ALTER TABLE $tableName DROP COLUMN $columnName',
    );
  }

  /// Creates a RENAME COLUMN operation.
  factory MigrationOperation.renameColumn({
    required String tableName,
    required String oldName,
    required String newName,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.renameColumn,
      sql: 'ALTER TABLE $tableName RENAME COLUMN $oldName TO $newName',
      tableName: tableName,
      columnName: newName,
      oldName: oldName,
      newName: newName,
      description: 'Rename column $oldName to $newName in $tableName',
      reverseSql: 'ALTER TABLE $tableName RENAME COLUMN $newName TO $oldName',
    );
  }

  /// Creates a CREATE INDEX operation.
  factory MigrationOperation.createIndex({
    required String indexName,
    required String tableName,
    required List<String> columns,
    bool unique = false,
  }) {
    final uniqueKeyword = unique ? 'UNIQUE ' : '';
    final columnList = columns.join(', ');
    return MigrationOperation(
      type: MigrationOperationType.createIndex,
      sql:
          'CREATE ${uniqueKeyword}INDEX $indexName ON $tableName ($columnList)',
      tableName: tableName,
      description: 'Create index $indexName on $tableName',
      reverseSql: 'DROP INDEX IF EXISTS $indexName',
    );
  }

  /// Creates a DROP INDEX operation.
  factory MigrationOperation.dropIndex({
    required String indexName,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.dropIndex,
      sql: 'DROP INDEX IF EXISTS $indexName',
      description: 'Drop index $indexName',
      reversible: false,
    );
  }

  /// Creates a custom SQL operation.
  factory MigrationOperation.customSql({
    required String sql,
    String? description,
    String? reverseSql,
  }) {
    return MigrationOperation(
      type: MigrationOperationType.customSql,
      sql: sql,
      description: description ?? 'Execute custom SQL',
      reversible: reverseSql != null,
      reverseSql: reverseSql,
    );
  }

  /// Type of migration operation.
  final MigrationOperationType type;

  /// SQL statement to execute.
  final String sql;

  /// Table name affected by the operation.
  final String? tableName;

  /// Column name affected by the operation.
  final String? columnName;

  /// Old name (for rename operations).
  final String? oldName;

  /// New name (for rename operations).
  final String? newName;

  /// Human-readable description of the operation.
  final String? description;

  /// Whether this operation can be reversed.
  final bool reversible;

  /// SQL statement to reverse this operation.
  final String? reverseSql;

  /// Converts the operation to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'sql': sql,
      if (tableName != null) 'tableName': tableName,
      if (columnName != null) 'columnName': columnName,
      if (oldName != null) 'oldName': oldName,
      if (newName != null) 'newName': newName,
      if (description != null) 'description': description,
      'reversible': reversible,
      if (reverseSql != null) 'reverseSql': reverseSql,
    };
  }

  @override
  String toString() {
    return description ?? 'MigrationOperation(${type.name})';
  }
}
