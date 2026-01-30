import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_storage_cache/src/config/storage_config.dart';
import 'package:local_storage_cache/src/managers/event_manager.dart';
import 'package:local_storage_cache/src/managers/performance_metrics_manager.dart';
import 'package:local_storage_cache/src/managers/storage_logger.dart';
import 'package:local_storage_cache/src/models/storage_event.dart';
import 'package:local_storage_cache/src/models/storage_stats.dart';
import 'package:local_storage_cache/src/query_builder.dart';
import 'package:local_storage_cache/src/schema/index_schema.dart';
import 'package:local_storage_cache/src/schema/primary_key_config.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Main entry point for the storage engine.
///
/// Provides a unified interface for data storage with advanced features like
/// encryption, caching, multi-space architecture, and more.
///
/// Example:
/// ```dart
/// final storage = StorageEngine(
///   config: StorageConfig(
///     encryption: EncryptionConfig(enabled: true),
///   ),
///   schemas: [
///     TableSchema(
///       name: 'users',
///       fields: [
///         FieldSchema(name: 'username', type: DataType.text),
///       ],
///     ),
///   ],
/// );
///
/// await storage.initialize();
/// await storage.insert('users', {'username': 'john'});
/// ```
class StorageEngine {
  /// Creates a storage engine with the given configuration and schemas.
  StorageEngine({
    StorageConfig? config,
    this.schemas,
  }) : config = config ?? StorageConfig.defaultConfig();

  /// Storage configuration.
  final StorageConfig config;

  /// Table schemas.
  final List<TableSchema>? schemas;

  /// Whether the storage engine is initialized.
  bool _initialized = false;

  /// Current space name.
  String _currentSpace = 'default';

  /// Platform interface for native operations.
  LocalStorageCachePlatform? _platform;

  /// Database path.
  String? _databasePath;

  /// Event manager for monitoring storage events.
  final EventManager _eventManager = EventManager();

  /// Performance metrics manager.
  final PerformanceMetricsManager _metricsManager = PerformanceMetricsManager();

  /// Storage logger.
  late final StorageLogger _logger;

  /// Gets the event manager for subscribing to storage events.
  EventManager get eventManager => _eventManager;

  /// Gets the performance metrics manager.
  PerformanceMetricsManager get metricsManager => _metricsManager;

  /// Initializes the storage engine.
  ///
  /// Must be called before any other operations.
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize logger
    _logger = StorageLogger(
      minLevel: config.logging.level,
    );

    _logger.info('Initializing storage engine...');

    // Get platform instance
    _platform = LocalStorageCachePlatform.instance;

    // Determine database path
    _databasePath = await _getDatabasePath();
    _logger.debug('Database path: $_databasePath');

    // Initialize platform storage
    final startTime = DateTime.now();
    await _platform!.initialize(_databasePath!, config.toMap());
    final initTime = DateTime.now().difference(startTime).inMilliseconds;
    _logger.info('Platform storage initialized in ${initTime}ms');

    // Setup encryption if enabled
    if (config.encryption.enabled) {
      _logger.info('Setting up encryption...');
      await _setupEncryption();
    }

    // Create tables from schemas
    if (schemas != null && schemas!.isNotEmpty) {
      _logger.info('Creating ${schemas!.length} tables from schemas...');
      await _createTables();
    }

    _initialized = true;
    _logger.info('Storage engine initialized successfully');

    // Emit initialization event
    _eventManager.emit(
      _InitializedEvent(timestamp: DateTime.now()),
    );
  }

  /// Gets the database path based on configuration and platform.
  Future<String> _getDatabasePath() async {
    if (config.databasePath != null) {
      return config.databasePath!;
    }

    if (kIsWeb) {
      // Web uses IndexedDB, no file path needed
      return config.databaseName;
    }

    // Get platform-specific directory
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, config.databaseName);
  }

  /// Sets up encryption with the platform.
  Future<void> _setupEncryption() async {
    var encryptionKey = config.encryption.customKey;

    // If no custom key, try to load from secure storage
    encryptionKey ??= await _platform!.getSecureKey('db_encryption_key');

    // If still no key, generate and store one
    if (encryptionKey == null) {
      encryptionKey = _generateEncryptionKey();
      await _platform!.saveSecureKey('db_encryption_key', encryptionKey);
    }

    // Set the encryption key
    await _platform!.setEncryptionKey(encryptionKey);

    // Handle biometric authentication if required
    if (config.encryption.requireBiometric) {
      final isAvailable = await _platform!.isBiometricAvailable();
      if (isAvailable) {
        final authenticated = await _platform!.authenticateWithBiometric(
          'Authenticate to access encrypted storage',
        );
        if (!authenticated) {
          throw StateError('Biometric authentication failed');
        }
      }
    }
  }

  /// Generates a random encryption key.
  String _generateEncryptionKey() {
    // Generate a 32-byte (256-bit) key
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.padRight(32, '0').substring(0, 32);
  }

  /// Creates tables from schemas.
  Future<void> _createTables() async {
    for (final schema in schemas!) {
      final sql = _generateCreateTableSQL(schema);
      await _platform!.query(sql, [], _currentSpace);

      // Create indexes
      for (final index in schema.indexes) {
        final indexSql = _generateCreateIndexSQL(schema.name, index);
        await _platform!.query(indexSql, [], _currentSpace);
      }
    }
  }

  /// Generates CREATE TABLE SQL from schema.
  String _generateCreateTableSQL(TableSchema schema) {
    final buffer = StringBuffer()
      ..write('CREATE TABLE IF NOT EXISTS ${_getTableName(schema.name)} (');

    // Primary key
    final pk = schema.primaryKeyConfig;
    buffer.write('${pk.name} ${_getDataTypeSQL(pk.type)}');
    if (pk.type == PrimaryKeyType.autoIncrement) {
      buffer.write(' PRIMARY KEY AUTOINCREMENT');
    } else {
      buffer.write(' PRIMARY KEY');
    }

    // Fields
    for (final field in schema.fields) {
      buffer.write(', ${field.name} ${_getDataTypeSQL(field.type)}');
      if (!field.nullable) {
        buffer.write(' NOT NULL');
      }
      if (field.unique) {
        buffer.write(' UNIQUE');
      }
      if (field.defaultValue != null) {
        buffer.write(' DEFAULT ${_formatDefaultValue(field.defaultValue)}');
      }
    }

    // Foreign keys
    for (final fk in schema.foreignKeys) {
      buffer
        ..write(
          ', FOREIGN KEY (${fk.field}) REFERENCES ${fk.referenceTable}(${fk.referenceField})',
        )
        ..write(' ON DELETE ${_getForeignKeyActionSQL(fk.onDelete)}')
        ..write(' ON UPDATE ${_getForeignKeyActionSQL(fk.onUpdate)}');
    }

    buffer.write(')');
    return buffer.toString();
  }

  /// Gets SQL for foreign key action.
  String _getForeignKeyActionSQL(dynamic action) {
    final actionStr = action.toString().split('.').last;
    switch (actionStr) {
      case 'noAction':
        return 'NO ACTION';
      case 'restrict':
        return 'RESTRICT';
      case 'setNull':
        return 'SET NULL';
      case 'setDefault':
        return 'SET DEFAULT';
      case 'cascade':
        return 'CASCADE';
      default:
        return 'NO ACTION';
    }
  }

  /// Generates CREATE INDEX SQL.
  String _generateCreateIndexSQL(String tableName, IndexSchema index) {
    final indexName =
        index.name ?? '${tableName}_${index.fields.join('_')}_idx';
    final unique = index.unique ? 'UNIQUE ' : '';
    return 'CREATE ${unique}INDEX IF NOT EXISTS $indexName ON ${_getTableName(tableName)} (${index.fields.join(', ')})';
  }

  /// Gets SQL data type from DataType enum.
  String _getDataTypeSQL(dynamic type) {
    final typeStr = type.toString().split('.').last;
    switch (typeStr) {
      case 'integer':
        return 'INTEGER';
      case 'real':
        return 'REAL';
      case 'text':
        return 'TEXT';
      case 'blob':
        return 'BLOB';
      case 'boolean':
        return 'INTEGER'; // SQLite doesn't have boolean
      case 'datetime':
        return 'INTEGER'; // Store as timestamp
      default:
        return 'TEXT';
    }
  }

  /// Formats default value for SQL.
  String _formatDefaultValue(dynamic value) {
    if (value is String) {
      return "'$value'";
    }
    return value.toString();
  }

  /// Gets the full table name with space prefix.
  String _getTableName(String tableName) {
    final schema = schemas?.firstWhere(
      (s) => s.name == tableName,
      orElse: () => TableSchema(name: tableName, fields: []),
    );
    final isGlobal = schema?.isGlobal ?? false;
    if (isGlobal) {
      return tableName; // Global tables don't have space prefix
    }
    return '${_currentSpace}_$tableName';
  }

  /// Creates a query builder for the specified table.
  QueryBuilder query(String tableName) {
    _ensureInitialized();
    return QueryBuilder(tableName, _currentSpace);
  }

  /// Inserts data into the specified table.
  ///
  /// Returns the ID of the inserted record.
  Future<dynamic> insert(String tableName, Map<String, dynamic> data) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);

    final startTime = DateTime.now();
    final id = await _platform!.insert(fullTableName, data, _currentSpace);
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;

    // Log operation
    _logger.debug('Inserted record into $tableName in ${executionTime}ms');

    // Record metrics
    _metricsManager.recordQueryExecution(
      'INSERT INTO $fullTableName',
      executionTime,
    );

    // Emit event
    _eventManager.emit(
      DataChangeEvent(
        type: StorageEventType.dataInserted,
        timestamp: DateTime.now(),
        tableName: tableName,
        space: _currentSpace,
        recordId: id,
        data: data,
      ),
    );

    return id;
  }

  /// Finds a record by its ID.
  Future<Map<String, dynamic>?> findById(String tableName, dynamic id) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);
    final schema = schemas?.firstWhere(
      (s) => s.name == tableName,
      orElse: () => TableSchema(name: tableName, fields: []),
    );
    final pkName = schema?.primaryKeyConfig.name ?? 'id';

    final sql = 'SELECT * FROM $fullTableName WHERE $pkName = ? LIMIT 1';
    final results = await _platform!.query(sql, [id], _currentSpace);

    return results.isNotEmpty ? results.first : null;
  }

  /// Updates data in the specified table.
  ///
  /// Use with query builder for conditional updates.
  Future<int> update(String tableName, Map<String, dynamic> data) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);

    // Build UPDATE SQL
    final fields = data.keys.map((k) => '$k = ?').join(', ');
    final sql = 'UPDATE $fullTableName SET $fields';

    final startTime = DateTime.now();
    final count =
        await _platform!.update(sql, data.values.toList(), _currentSpace);
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;

    // Log operation
    _logger.debug('Updated $count records in $tableName in ${executionTime}ms');

    // Record metrics
    _metricsManager.recordQueryExecution(sql, executionTime);

    // Emit event
    _eventManager.emit(
      DataChangeEvent(
        type: StorageEventType.dataUpdated,
        timestamp: DateTime.now(),
        tableName: tableName,
        space: _currentSpace,
        data: data,
      ),
    );

    return count;
  }

  /// Deletes data from the specified table.
  ///
  /// Use with query builder for conditional deletes.
  Future<int> delete(String tableName) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);
    final sql = 'DELETE FROM $fullTableName';

    final startTime = DateTime.now();
    final count = await _platform!.delete(sql, [], _currentSpace);
    final executionTime = DateTime.now().difference(startTime).inMilliseconds;

    // Log operation
    _logger
        .debug('Deleted $count records from $tableName in ${executionTime}ms');

    // Record metrics
    _metricsManager.recordQueryExecution(sql, executionTime);

    // Emit event
    _eventManager.emit(
      DataChangeEvent(
        type: StorageEventType.dataDeleted,
        timestamp: DateTime.now(),
        tableName: tableName,
        space: _currentSpace,
      ),
    );

    return count;
  }

  /// Executes a function within a transaction.
  Future<T> transaction<T>(Future<T> Function() action) async {
    _ensureInitialized();
    return _platform!.transaction(action, _currentSpace);
  }

  /// Executes a batch of insert operations.
  Future<void> batchInsert(
    String tableName,
    List<Map<String, dynamic>> dataList,
  ) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);

    final operations = dataList
        .map(
          (data) => BatchOperation(
            type: 'insert',
            tableName: fullTableName,
            data: data,
          ),
        )
        .toList();

    await _platform!.executeBatch(operations, _currentSpace);
  }

  /// Executes a batch of update operations.
  Future<void> batchUpdate(
    String tableName,
    List<Map<String, dynamic>> dataList,
  ) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);

    final operations = dataList
        .map(
          (data) => BatchOperation(
            type: 'update',
            tableName: fullTableName,
            data: data,
          ),
        )
        .toList();

    await _platform!.executeBatch(operations, _currentSpace);
  }

  /// Executes a batch of delete operations.
  Future<void> batchDelete(String tableName, List<dynamic> ids) async {
    _ensureInitialized();
    final fullTableName = _getTableName(tableName);
    final schema = schemas?.firstWhere(
      (s) => s.name == tableName,
      orElse: () => TableSchema(name: tableName, fields: []),
    );
    final pkName = schema?.primaryKeyConfig.name ?? 'id';

    final operations = ids
        .map(
          (id) => BatchOperation(
            type: 'delete',
            tableName: fullTableName,
            sql: 'DELETE FROM $fullTableName WHERE $pkName = ?',
            arguments: [id],
          ),
        )
        .toList();

    await _platform!.executeBatch(operations, _currentSpace);
  }

  /// Switches to the specified space.
  Future<void> switchSpace({required String spaceName}) async {
    _ensureInitialized();
    _currentSpace = spaceName;

    // Create tables in new space if schemas are defined
    if (schemas != null && schemas!.isNotEmpty) {
      await _createTables();
    }
  }

  /// Gets the current space name.
  String get currentSpace {
    _ensureInitialized();
    return _currentSpace;
  }

  /// Sets a key-value pair.
  Future<void> setValue(
    String key,
    dynamic value, {
    bool isGlobal = false,
  }) async {
    _ensureInitialized();

    // Create key-value table if it doesn't exist
    final createTableSQL = '''
      CREATE TABLE IF NOT EXISTS ${_getKVTableName(isGlobal)} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''';
    await _platform!.query(createTableSQL, [], _currentSpace);

    // Insert or replace the value
    final valueStr = _serializeValue(value);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sql = '''
      INSERT OR REPLACE INTO ${_getKVTableName(isGlobal)} (key, value, updated_at)
      VALUES (?, ?, ?)
    ''';
    await _platform!.query(sql, [key, valueStr, timestamp], _currentSpace);
  }

  /// Gets a value by key.
  Future<T?> getValue<T>(String key, {bool isGlobal = false}) async {
    _ensureInitialized();

    final sql =
        'SELECT value FROM ${_getKVTableName(isGlobal)} WHERE key = ? LIMIT 1';
    try {
      final results = await _platform!.query(sql, [key], _currentSpace);
      if (results.isEmpty) return null;

      final valueStr = results.first['value'] as String;
      return _deserializeValue<T>(valueStr);
    } catch (e) {
      // Table might not exist yet
      return null;
    }
  }

  /// Deletes a key-value pair.
  Future<void> deleteValue(String key, {bool isGlobal = false}) async {
    _ensureInitialized();
    final sql = 'DELETE FROM ${_getKVTableName(isGlobal)} WHERE key = ?';
    await _platform!.delete(sql, [key], _currentSpace);
  }

  /// Gets the key-value table name.
  String _getKVTableName(bool isGlobal) {
    if (isGlobal) {
      return '_global_kv';
    }
    return '${_currentSpace}__kv';
  }

  /// Serializes a value to string for storage.
  String _serializeValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return 'string:$value';
    if (value is int) return 'int:$value';
    if (value is double) return 'double:$value';
    if (value is bool) return 'bool:$value';
    // For complex types, use JSON
    return 'json:$value';
  }

  /// Deserializes a value from string.
  T? _deserializeValue<T>(String valueStr) {
    if (valueStr == 'null') return null;

    final parts = valueStr.split(':');
    if (parts.length < 2) return valueStr as T;

    final type = parts[0];
    final value = parts.sublist(1).join(':');

    switch (type) {
      case 'string':
        return value as T;
      case 'int':
        return int.parse(value) as T;
      case 'double':
        return double.parse(value) as T;
      case 'bool':
        return (value == 'true') as T;
      case 'json':
        return value as T; // Return as string, caller can parse
      default:
        return valueStr as T;
    }
  }

  /// Gets storage statistics.
  Future<StorageStats> getStats() async {
    _ensureInitialized();
    final info = await _platform!.getStorageInfo();
    return StorageStats(
      storageSize: (info['totalSize'] as int?) ?? 0,
      recordCount: (info['recordCount'] as int?) ?? 0,
      tableCount: (info['tableCount'] as int?) ?? 0,
      spaceCount: 1, // Will be enhanced in Phase 4
      cacheHitRate: 0, // Will be enhanced in Phase 4
      averageQueryTime: 0, // Will be enhanced in Phase 7
    );
  }

  /// Performs a VACUUM operation to reclaim unused space.
  Future<void> vacuum() async {
    _ensureInitialized();
    await _platform!.vacuum();
  }

  /// Exports the database to a file.
  Future<void> exportDatabase(String destinationPath) async {
    _ensureInitialized();
    if (_databasePath == null) {
      throw StateError('Cannot export web database');
    }
    await _platform!.exportDatabase(_databasePath!, destinationPath);
  }

  /// Imports a database from a file.
  Future<void> importDatabase(String sourcePath) async {
    _ensureInitialized();
    if (_databasePath == null) {
      throw StateError('Cannot import to web database');
    }
    await _platform!.importDatabase(sourcePath, _databasePath!);
  }

  /// Closes the storage engine and releases resources.
  Future<void> close() async {
    if (!_initialized) return;

    _logger.info('Closing storage engine...');

    // Close platform connection
    await _platform?.close();

    // Dispose event manager
    _eventManager.dispose();

    // Clear references
    _platform = null;
    _databasePath = null;

    _initialized = false;
    _logger.info('Storage engine closed');
  }

  /// Executes a streaming query for memory-efficient processing of large datasets.
  ///
  /// Returns a stream that yields records one at a time without loading
  /// all data into memory at once.
  ///
  /// Example:
  /// ```dart
  /// await for (final record in storage.streamQuery('large_table')) {
  ///   await processRecord(record);
  /// }
  /// ```
  Stream<Map<String, dynamic>> streamQuery(String tableName) async* {
    _ensureInitialized();
    final queryBuilder = query(tableName);
    yield* queryBuilder.stream();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'StorageEngine not initialized. Call initialize() first.',
      );
    }
  }
}

/// Private event for initialization.
class _InitializedEvent extends StorageEvent {
  const _InitializedEvent({required super.timestamp})
      : super(type: StorageEventType.initialized);
}
