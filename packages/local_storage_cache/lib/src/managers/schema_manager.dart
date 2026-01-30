import 'dart:async';
import 'dart:convert';

import 'package:local_storage_cache/src/enums/data_type.dart';
import 'package:local_storage_cache/src/models/migration_operation.dart';
import 'package:local_storage_cache/src/models/migration_status.dart';
import 'package:local_storage_cache/src/models/schema_change.dart';
import 'package:local_storage_cache/src/schema/field_schema.dart';
import 'package:local_storage_cache/src/schema/foreign_key_schema.dart';
import 'package:local_storage_cache/src/schema/index_schema.dart';
import 'package:local_storage_cache/src/schema/primary_key_config.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';

/// Callback for migration progress updates.
typedef MigrationProgressCallback = void Function(MigrationStatus status);

/// Manages database schema creation, versioning, and migrations.
class SchemaManager {
  /// Creates a schema manager with the specified database executor.
  SchemaManager({
    required this.executeRawQuery,
    required this.executeRawInsert,
    required this.executeRawUpdate,
    required this.executeRawDelete,
  });

  /// Function to execute raw SQL queries.
  final Future<List<Map<String, dynamic>>> Function(
    String sql, [
    List<dynamic>? arguments,
  ]) executeRawQuery;

  /// Function to execute raw SQL inserts.
  final Future<int> Function(String sql, [List<dynamic>? arguments])
      executeRawInsert;

  /// Function to execute raw SQL updates.
  final Future<int> Function(String sql, [List<dynamic>? arguments])
      executeRawUpdate;

  /// Function to execute raw SQL deletes.
  final Future<int> Function(String sql, [List<dynamic>? arguments])
      executeRawDelete;

  static const String _schemaVersionTable = '_schema_versions';
  static const String _migrationHistoryTable = '_migration_history';

  final Map<String, TableSchema> _registeredSchemas = {};
  final List<MigrationProgressCallback> _progressCallbacks = [];

  /// Initializes the schema manager by creating metadata tables.
  Future<void> initialize() async {
    // Create schema version tracking table
    await executeRawQuery('''
      CREATE TABLE IF NOT EXISTS $_schemaVersionTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL UNIQUE,
        version INTEGER NOT NULL DEFAULT 1,
        schema_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create migration history table
    await executeRawQuery('''
      CREATE TABLE IF NOT EXISTS $_migrationHistoryTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL UNIQUE,
        table_name TEXT NOT NULL,
        from_version INTEGER,
        to_version INTEGER NOT NULL,
        operations TEXT NOT NULL,
        state TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        error_message TEXT
      )
    ''');
  }

  /// Registers a table schema for management.
  void registerSchema(TableSchema schema) {
    _registeredSchemas[schema.name] = schema;
  }

  /// Registers multiple table schemas.
  void registerSchemas(List<TableSchema> schemas) {
    for (final schema in schemas) {
      registerSchema(schema);
    }
  }

  /// Adds a migration progress callback.
  void addProgressCallback(MigrationProgressCallback callback) {
    _progressCallbacks.add(callback);
  }

  /// Removes a migration progress callback.
  void removeProgressCallback(MigrationProgressCallback callback) {
    _progressCallbacks.remove(callback);
  }

  /// Notifies all progress callbacks.
  void _notifyProgress(MigrationStatus status) {
    for (final callback in _progressCallbacks) {
      callback(status);
    }
  }

  /// Creates a table from a schema definition.
  Future<void> createTable(TableSchema schema) async {
    final sql = _generateCreateTableSql(schema);
    await executeRawQuery(sql);

    // Create indexes
    for (final index in schema.indexes) {
      await _createIndex(schema.name, index);
    }

    // Track schema version
    await _saveSchemaVersion(schema);
  }

  /// Generates CREATE TABLE SQL from schema.
  String _generateCreateTableSql(TableSchema schema) {
    final buffer = StringBuffer('CREATE TABLE IF NOT EXISTS ${schema.name} (');

    // Primary key
    final pk = schema.primaryKeyConfig;
    buffer.write('${pk.name} ');
    if (pk.type == PrimaryKeyType.autoIncrement) {
      buffer.write('INTEGER PRIMARY KEY AUTOINCREMENT');
    } else {
      buffer.write('TEXT PRIMARY KEY');
    }

    // Fields
    for (final field in schema.fields) {
      buffer
        ..write(', ')
        ..write(_generateFieldSql(field));
    }

    // Foreign keys
    for (final fk in schema.foreignKeys) {
      buffer
        ..write(', ')
        ..write(_generateForeignKeySql(fk));
    }

    buffer.write(')');
    return buffer.toString();
  }

  /// Generates field definition SQL.
  String _generateFieldSql(FieldSchema field) {
    final buffer = StringBuffer('${field.name} ${_dataTypeToSql(field.type)}');

    if (!field.nullable) {
      buffer.write(' NOT NULL');
    }

    if (field.unique) {
      buffer.write(' UNIQUE');
    }

    if (field.defaultValue != null) {
      buffer.write(' DEFAULT ${_formatDefaultValue(field.defaultValue)}');
    }

    return buffer.toString();
  }

  /// Generates foreign key constraint SQL.
  String _generateForeignKeySql(ForeignKeySchema fk) {
    final buffer = StringBuffer(
      'FOREIGN KEY (${fk.field}) REFERENCES ${fk.referenceTable}(${fk.referenceField})',
    );

    if (fk.onUpdate != ForeignKeyAction.noAction) {
      buffer.write(' ON UPDATE ${_foreignKeyActionToSql(fk.onUpdate)}');
    }

    if (fk.onDelete != ForeignKeyAction.noAction) {
      buffer.write(' ON DELETE ${_foreignKeyActionToSql(fk.onDelete)}');
    }

    return buffer.toString();
  }

  /// Converts DataType to SQL type string.
  String _dataTypeToSql(DataType type) {
    switch (type) {
      case DataType.integer:
        return 'INTEGER';
      case DataType.real:
        return 'REAL';
      case DataType.text:
        return 'TEXT';
      case DataType.blob:
        return 'BLOB';
      case DataType.boolean:
        return 'INTEGER'; // SQLite stores booleans as integers
      case DataType.datetime:
        return 'TEXT'; // SQLite stores dates as text
      case DataType.json:
        return 'TEXT';
      case DataType.vector:
        return 'BLOB';
    }
  }

  /// Converts ForeignKeyAction to SQL string.
  String _foreignKeyActionToSql(ForeignKeyAction action) {
    switch (action) {
      case ForeignKeyAction.noAction:
        return 'NO ACTION';
      case ForeignKeyAction.restrict:
        return 'RESTRICT';
      case ForeignKeyAction.setNull:
        return 'SET NULL';
      case ForeignKeyAction.setDefault:
        return 'SET DEFAULT';
      case ForeignKeyAction.cascade:
        return 'CASCADE';
    }
  }

  /// Formats default value for SQL.
  String _formatDefaultValue(dynamic value) {
    if (value is String) {
      return "'$value'";
    } else if (value is bool) {
      return value ? '1' : '0';
    } else if (value is DateTime) {
      return "'${value.toIso8601String()}'";
    }
    return value.toString();
  }

  /// Creates an index for a table.
  Future<void> _createIndex(String tableName, IndexSchema index) async {
    final indexName =
        index.name ?? '${tableName}_${index.fields.join('_')}_idx';
    final uniqueKeyword = index.unique ? 'UNIQUE ' : '';
    final columnList = index.fields.join(', ');

    final sql =
        'CREATE ${uniqueKeyword}INDEX IF NOT EXISTS $indexName ON $tableName ($columnList)';
    await executeRawQuery(sql);
  }

  /// Gets the current schema version for a table.
  Future<int> getSchemaVersion(String tableName) async {
    final results = await executeRawQuery(
      'SELECT version FROM $_schemaVersionTable WHERE table_name = ?',
      [tableName],
    );

    if (results.isEmpty) {
      return 0;
    }

    return results.first['version'] as int;
  }

  /// Saves the schema version for a table.
  Future<void> _saveSchemaVersion(TableSchema schema) async {
    final now = DateTime.now().toIso8601String();
    final schemaHash = _calculateSchemaHash(schema);

    final existing = await executeRawQuery(
      'SELECT id FROM $_schemaVersionTable WHERE table_name = ?',
      [schema.name],
    );

    if (existing.isEmpty) {
      await executeRawInsert(
        'INSERT INTO $_schemaVersionTable (table_name, version, schema_hash, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
        [schema.name, 1, schemaHash, now, now],
      );
    } else {
      await executeRawUpdate(
        'UPDATE $_schemaVersionTable SET version = version + 1, schema_hash = ?, updated_at = ? WHERE table_name = ?',
        [schemaHash, now, schema.name],
      );
    }
  }

  /// Calculates a hash of the schema for change detection.
  String _calculateSchemaHash(TableSchema schema) {
    final schemaMap = schema.toMap();
    return schemaMap.toString().hashCode.toString();
  }

  /// Detects changes between old and new schema.
  Future<List<SchemaChange>> detectSchemaChanges(
    TableSchema oldSchema,
    TableSchema newSchema,
  ) async {
    final changes = <SchemaChange>[];

    // Check for table rename
    if (oldSchema.tableId != null &&
        newSchema.tableId != null &&
        oldSchema.tableId == newSchema.tableId &&
        oldSchema.name != newSchema.name) {
      changes.add(
        SchemaChange(
          type: SchemaChangeType.tableRenamed,
          tableName: newSchema.name,
          oldTableName: oldSchema.name,
        ),
      );
    }

    // Check for field changes
    final oldFields = {for (final f in oldSchema.fields) f.name: f};
    final newFields = {for (final f in newSchema.fields) f.name: f};

    // Detect field additions
    for (final newField in newSchema.fields) {
      if (!oldFields.containsKey(newField.name)) {
        // Check if it's a rename
        final renamedFrom = _detectFieldRename(oldSchema, newField);
        if (renamedFrom != null) {
          changes.add(
            SchemaChange(
              type: SchemaChangeType.fieldRenamed,
              tableName: newSchema.name,
              fieldName: newField.name,
              oldFieldName: renamedFrom.name,
            ),
          );
        } else {
          changes.add(
            SchemaChange(
              type: SchemaChangeType.fieldAdded,
              tableName: newSchema.name,
              fieldName: newField.name,
              newValue: newField.toMap(),
            ),
          );
        }
      }
    }

    // Detect field removals and modifications
    for (final oldField in oldSchema.fields) {
      final newField = newFields[oldField.name];

      if (newField == null) {
        // Check if it was renamed
        final wasRenamed = newSchema.fields.any(
          (f) =>
              f.fieldId != null &&
              oldField.fieldId != null &&
              f.fieldId == oldField.fieldId,
        );

        if (!wasRenamed) {
          changes.add(
            SchemaChange(
              type: SchemaChangeType.fieldRemoved,
              tableName: newSchema.name,
              fieldName: oldField.name,
              oldValue: oldField.toMap(),
            ),
          );
        }
      } else {
        // Check for type changes
        if (oldField.type != newField.type) {
          changes.add(
            SchemaChange(
              type: SchemaChangeType.fieldTypeChanged,
              tableName: newSchema.name,
              fieldName: newField.name,
              oldValue: oldField.type.name,
              newValue: newField.type.name,
            ),
          );
        }

        // Check for constraint changes
        if (oldField.nullable != newField.nullable ||
            oldField.unique != newField.unique) {
          changes.add(
            SchemaChange(
              type: SchemaChangeType.fieldConstraintChanged,
              tableName: newSchema.name,
              fieldName: newField.name,
              oldValue: {
                'nullable': oldField.nullable,
                'unique': oldField.unique,
              },
              newValue: {
                'nullable': newField.nullable,
                'unique': newField.unique,
              },
            ),
          );
        }
      }
    }

    // Check for index changes
    final oldIndexes = oldSchema.indexes.map((i) => i.fields.join(',')).toSet();
    final newIndexes = newSchema.indexes.map((i) => i.fields.join(',')).toSet();

    for (final indexFields in newIndexes.difference(oldIndexes)) {
      changes.add(
        SchemaChange(
          type: SchemaChangeType.indexAdded,
          tableName: newSchema.name,
          details: {'fields': indexFields},
        ),
      );
    }

    for (final indexFields in oldIndexes.difference(newIndexes)) {
      changes.add(
        SchemaChange(
          type: SchemaChangeType.indexRemoved,
          tableName: newSchema.name,
          details: {'fields': indexFields},
        ),
      );
    }

    return changes;
  }

  /// Detects if a field is a rename of an old field using fieldId.
  FieldSchema? _detectFieldRename(TableSchema oldSchema, FieldSchema newField) {
    if (newField.fieldId == null) return null;

    for (final oldField in oldSchema.fields) {
      if (oldField.fieldId == newField.fieldId &&
          oldField.name != newField.name) {
        return oldField;
      }
    }

    return null;
  }

  /// Generates migration operations from schema changes.
  Future<List<MigrationOperation>> generateMigration(
    List<SchemaChange> changes,
  ) async {
    final operations = <MigrationOperation>[];

    for (final change in changes) {
      switch (change.type) {
        case SchemaChangeType.tableAdded:
          final schema = _registeredSchemas[change.tableName];
          if (schema != null) {
            operations.add(
              MigrationOperation.createTable(
                tableName: change.tableName,
                sql: _generateCreateTableSql(schema),
              ),
            );
          }

        case SchemaChangeType.tableRemoved:
          operations.add(
            MigrationOperation.dropTable(
              tableName: change.tableName,
            ),
          );

        case SchemaChangeType.tableRenamed:
          if (change.oldTableName != null) {
            operations.add(
              MigrationOperation.renameTable(
                oldName: change.oldTableName!,
                newName: change.tableName,
              ),
            );
          }

        case SchemaChangeType.fieldAdded:
          if (change.fieldName != null && change.newValue != null) {
            final fieldMap = change.newValue as Map<String, dynamic>;
            final fieldDef = _generateFieldDefinitionFromMap(
              change.fieldName!,
              fieldMap,
            );
            operations.add(
              MigrationOperation.addColumn(
                tableName: change.tableName,
                columnName: change.fieldName!,
                columnDefinition: fieldDef,
              ),
            );
          }

        case SchemaChangeType.fieldRenamed:
          if (change.oldFieldName != null && change.fieldName != null) {
            operations.add(
              MigrationOperation.renameColumn(
                tableName: change.tableName,
                oldName: change.oldFieldName!,
                newName: change.fieldName!,
              ),
            );
          }

        case SchemaChangeType.fieldRemoved:
          // SQLite doesn't support DROP COLUMN directly
          // Need to use table recreation strategy
          operations.add(
            MigrationOperation.customSql(
              sql:
                  '-- Field ${change.fieldName} removed from ${change.tableName} (requires table recreation)',
              description:
                  'Remove field ${change.fieldName} from ${change.tableName}',
            ),
          );

        case SchemaChangeType.fieldTypeChanged:
        case SchemaChangeType.fieldConstraintChanged:
          // SQLite doesn't support ALTER COLUMN
          // Need to use table recreation strategy
          operations.add(
            MigrationOperation.customSql(
              sql:
                  '-- Field ${change.fieldName} modified in ${change.tableName} (requires table recreation)',
              description:
                  'Modify field ${change.fieldName} in ${change.tableName}',
            ),
          );

        case SchemaChangeType.indexAdded:
          final fields = (change.details?['fields'] as String).split(',');
          final indexName = '${change.tableName}_${fields.join('_')}_idx';
          operations.add(
            MigrationOperation.createIndex(
              indexName: indexName,
              tableName: change.tableName,
              columns: fields,
            ),
          );

        case SchemaChangeType.indexRemoved:
          final fields = (change.details?['fields'] as String).split(',');
          final indexName = '${change.tableName}_${fields.join('_')}_idx';
          operations.add(
            MigrationOperation.dropIndex(
              indexName: indexName,
            ),
          );

        case SchemaChangeType.foreignKeyAdded:
        case SchemaChangeType.foreignKeyRemoved:
          // Foreign key changes require table recreation in SQLite
          operations.add(
            MigrationOperation.customSql(
              sql:
                  '-- Foreign key change in ${change.tableName} (requires table recreation)',
              description: 'Modify foreign keys in ${change.tableName}',
            ),
          );
      }
    }

    return operations;
  }

  /// Generates field definition from map.
  String _generateFieldDefinitionFromMap(
    String fieldName,
    Map<String, dynamic> fieldMap,
  ) {
    final buffer = StringBuffer('$fieldName ');

    final typeName = fieldMap['type'] as String;
    final dataType = DataType.values.firstWhere((t) => t.name == typeName);
    buffer.write(_dataTypeToSql(dataType));

    if (fieldMap['nullable'] == false) {
      buffer.write(' NOT NULL');
    }

    if (fieldMap['unique'] == true) {
      buffer.write(' UNIQUE');
    }

    if (fieldMap['defaultValue'] != null) {
      buffer.write(' DEFAULT ${_formatDefaultValue(fieldMap['defaultValue'])}');
    }

    return buffer.toString();
  }

  /// Executes a migration with progress tracking.
  Future<void> executeMigration(
    String tableName,
    List<MigrationOperation> operations, {
    String? taskId,
  }) async {
    final migrationTaskId =
        taskId ?? 'migration_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    // Create initial status
    var status = MigrationStatus(
      taskId: migrationTaskId,
      tableName: tableName,
      state: MigrationState.inProgress,
      progressPercentage: 0,
      startedAt: startTime,
    );

    _notifyProgress(status);

    // Save migration start to history
    await _saveMigrationHistory(status, operations);

    try {
      // Execute operations
      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];

        // Execute the SQL
        await executeRawQuery(operation.sql);

        // Update progress
        final progress = ((i + 1) / operations.length) * 100;
        status = MigrationStatus(
          taskId: migrationTaskId,
          tableName: tableName,
          state: MigrationState.inProgress,
          progressPercentage: progress,
          startedAt: startTime,
        );

        _notifyProgress(status);
      }

      // Mark as completed
      status = MigrationStatus(
        taskId: migrationTaskId,
        tableName: tableName,
        state: MigrationState.completed,
        progressPercentage: 100,
        startedAt: startTime,
        completedAt: DateTime.now(),
      );

      _notifyProgress(status);

      // Update migration history
      await _updateMigrationHistory(status);
    } catch (e) {
      // Mark as failed
      status = MigrationStatus(
        taskId: migrationTaskId,
        tableName: tableName,
        state: MigrationState.failed,
        progressPercentage: 0,
        startedAt: startTime,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );

      _notifyProgress(status);

      // Update migration history
      await _updateMigrationHistory(status);

      rethrow;
    }
  }

  /// Saves migration to history.
  Future<void> _saveMigrationHistory(
    MigrationStatus status,
    List<MigrationOperation> operations,
  ) async {
    final operationsJson =
        jsonEncode(operations.map((op) => op.toMap()).toList());

    await executeRawInsert(
      'INSERT INTO $_migrationHistoryTable (task_id, table_name, to_version, operations, state, started_at) VALUES (?, ?, ?, ?, ?, ?)',
      [
        status.taskId,
        status.tableName,
        await getSchemaVersion(status.tableName) + 1,
        operationsJson,
        status.state.name,
        status.startedAt?.toIso8601String(),
      ],
    );
  }

  /// Updates migration history.
  Future<void> _updateMigrationHistory(MigrationStatus status) async {
    await executeRawUpdate(
      'UPDATE $_migrationHistoryTable SET state = ?, completed_at = ?, error_message = ? WHERE task_id = ?',
      [
        status.state.name,
        status.completedAt?.toIso8601String(),
        status.errorMessage,
        status.taskId,
      ],
    );
  }

  /// Rolls back a migration.
  Future<void> rollbackMigration(String taskId) async {
    // Get migration history
    final results = await executeRawQuery(
      'SELECT operations FROM $_migrationHistoryTable WHERE task_id = ?',
      [taskId],
    );

    if (results.isEmpty) {
      throw Exception('Migration task $taskId not found');
    }

    // Parse operations (simplified - in production would need proper JSON parsing)
    // Execute reverse operations
    // This is a simplified implementation
    throw UnimplementedError('Rollback not yet fully implemented');
  }

  /// Performs zero-downtime migration using shadow table strategy.
  Future<void> migrateWithZeroDowntime(
    TableSchema oldSchema,
    TableSchema newSchema,
  ) async {
    final tempTableName = '${newSchema.name}_temp';

    // Create temporary table with new schema
    final tempSchema = TableSchema(
      name: tempTableName,
      fields: newSchema.fields,
      primaryKeyConfig: newSchema.primaryKeyConfig,
      indexes: newSchema.indexes,
      foreignKeys: newSchema.foreignKeys,
    );

    await createTable(tempSchema);

    // Copy data from old table to temp table
    final commonFields = _getCommonFields(oldSchema, newSchema);
    if (commonFields.isNotEmpty) {
      final fieldList = commonFields.join(', ');
      await executeRawQuery(
        'INSERT INTO $tempTableName ($fieldList) SELECT $fieldList FROM ${oldSchema.name}',
      );
    }

    // Drop old table
    await executeRawQuery('DROP TABLE IF EXISTS ${oldSchema.name}');

    // Rename temp table to original name
    await executeRawQuery(
      'ALTER TABLE $tempTableName RENAME TO ${newSchema.name}',
    );

    // Update schema version
    await _saveSchemaVersion(newSchema);
  }

  /// Gets common fields between two schemas.
  List<String> _getCommonFields(TableSchema oldSchema, TableSchema newSchema) {
    final oldFieldNames = oldSchema.fields.map((f) => f.name).toSet();
    final newFieldNames = newSchema.fields.map((f) => f.name).toSet();

    return oldFieldNames.intersection(newFieldNames).toList();
  }

  /// Gets migration history for a table.
  Future<List<MigrationStatus>> getMigrationHistory(String tableName) async {
    final results = await executeRawQuery(
      'SELECT * FROM $_migrationHistoryTable WHERE table_name = ? ORDER BY id DESC',
      [tableName],
    );

    return results.map((row) {
      return MigrationStatus(
        taskId: row['task_id'] as String,
        tableName: row['table_name'] as String,
        state: MigrationState.values.firstWhere(
          (s) => s.name == row['state'],
          orElse: () => MigrationState.pending,
        ),
        progressPercentage: 100,
        startedAt: row['started_at'] != null
            ? DateTime.parse(row['started_at'] as String)
            : null,
        completedAt: row['completed_at'] != null
            ? DateTime.parse(row['completed_at'] as String)
            : null,
        errorMessage: row['error_message'] as String?,
      );
    }).toList();
  }

  /// Checks if a table exists in the database.
  Future<bool> tableExists(String tableName) async {
    final results = await executeRawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );

    return results.isNotEmpty;
  }

  /// Gets all table names in the database.
  Future<List<String>> getAllTableNames() async {
    final results = await executeRawQuery(
      r"SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '\_%' ESCAPE '\'",
    );

    return results.map((row) => row['name'] as String).toList();
  }
}
