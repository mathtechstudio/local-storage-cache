import 'dart:async';

import 'package:local_storage_cache/src/models/storage_stats.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';

/// Manages multi-space architecture for data isolation.
///
/// Spaces provide logical separation of data within a single database,
/// allowing different contexts (users, tenants, sessions) to have isolated
/// storage while sharing the same physical database.
class SpaceManager {
  /// Creates a space manager with the specified database executor.
  SpaceManager({
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

  static const String _spacesTable = '_spaces';
  static const String _globalTablesTable = '_global_tables';
  static const String _defaultSpace = 'default';

  String _currentSpace = _defaultSpace;
  final Set<String> _globalTables = {};
  final _lock = _SpaceLock();

  /// Gets the current active space.
  String get currentSpace => _currentSpace;

  /// Gets all registered global tables.
  Set<String> get globalTables => Set.unmodifiable(_globalTables);

  /// Initializes the space manager by creating metadata tables.
  Future<void> initialize() async {
    await _lock.synchronized(() async {
      // Create spaces tracking table
      await executeRawQuery('''
        CREATE TABLE IF NOT EXISTS $_spacesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          created_at TEXT NOT NULL,
          metadata TEXT
        )
      ''');

      // Create global tables registry
      await executeRawQuery('''
        CREATE TABLE IF NOT EXISTS $_globalTablesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL UNIQUE,
          registered_at TEXT NOT NULL
        )
      ''');

      // Ensure default space exists
      await _ensureSpaceExists(_defaultSpace);
    });
  }

  /// Creates a new space.
  ///
  /// Throws [StateError] if the space already exists.
  Future<void> createSpace(
    String spaceName, {
    Map<String, dynamic>? metadata,
  }) async {
    await _lock.synchronized(() async {
      _validateSpaceName(spaceName);

      final existing = await executeRawQuery(
        'SELECT id FROM $_spacesTable WHERE name = ?',
        [spaceName],
      );

      if (existing.isNotEmpty) {
        throw StateError('Space "$spaceName" already exists');
      }

      final now = DateTime.now().toIso8601String();
      final metadataJson = metadata != null ? _encodeMetadata(metadata) : null;

      await executeRawInsert(
        'INSERT INTO $_spacesTable (name, created_at, metadata) VALUES (?, ?, ?)',
        [spaceName, now, metadataJson],
      );
    });
  }

  /// Deletes a space and all its data.
  ///
  /// Throws [StateError] if trying to delete the default space or current space.
  Future<void> deleteSpace(String spaceName) async {
    await _lock.synchronized(() async {
      _validateSpaceName(spaceName);

      if (spaceName == _defaultSpace) {
        throw StateError('Cannot delete the default space');
      }

      if (spaceName == _currentSpace) {
        throw StateError('Cannot delete the current active space');
      }

      // Get all tables in the database
      final tables = await _getAllTableNames();

      // Drop all space-specific tables
      for (final table in tables) {
        if (table.startsWith('${spaceName}_') && !_isMetadataTable(table)) {
          await executeRawQuery('DROP TABLE IF EXISTS $table');
        }
      }

      // Remove space from registry
      await executeRawDelete(
        'DELETE FROM $_spacesTable WHERE name = ?',
        [spaceName],
      );
    });
  }

  /// Switches to a different space.
  ///
  /// Creates the space if it doesn't exist.
  Future<void> switchSpace(String spaceName) async {
    await _lock.synchronized(() async {
      _validateSpaceName(spaceName);
      await _ensureSpaceExists(spaceName);
      _currentSpace = spaceName;
    });
  }

  /// Registers a table as global (accessible from all spaces).
  Future<void> registerGlobalTable(String tableName) async {
    await _lock.synchronized(() async {
      if (_globalTables.contains(tableName)) {
        return;
      }

      final existing = await executeRawQuery(
        'SELECT id FROM $_globalTablesTable WHERE table_name = ?',
        [tableName],
      );

      if (existing.isEmpty) {
        final now = DateTime.now().toIso8601String();
        await executeRawInsert(
          'INSERT INTO $_globalTablesTable (table_name, registered_at) VALUES (?, ?)',
          [tableName, now],
        );
      }

      _globalTables.add(tableName);
    });
  }

  /// Unregisters a global table.
  Future<void> unregisterGlobalTable(String tableName) async {
    await _lock.synchronized(() async {
      await executeRawDelete(
        'DELETE FROM $_globalTablesTable WHERE table_name = ?',
        [tableName],
      );

      _globalTables.remove(tableName);
    });
  }

  /// Checks if a table is registered as global.
  bool isGlobalTable(String tableName) {
    return _globalTables.contains(tableName);
  }

  /// Gets the prefixed table name for the current space.
  ///
  /// Global tables are not prefixed.
  String getPrefixedTableName(String tableName) {
    if (_globalTables.contains(tableName) || _isMetadataTable(tableName)) {
      return tableName;
    }
    return '${_currentSpace}_$tableName';
  }

  /// Gets the unprefixed table name (removes space prefix).
  String getUnprefixedTableName(String prefixedName) {
    if (_globalTables.contains(prefixedName) ||
        _isMetadataTable(prefixedName)) {
      return prefixedName;
    }

    final prefix = '${_currentSpace}_';
    if (prefixedName.startsWith(prefix)) {
      return prefixedName.substring(prefix.length);
    }

    return prefixedName;
  }

  /// Lists all available spaces.
  Future<List<String>> listSpaces() async {
    final results = await executeRawQuery(
      'SELECT name FROM $_spacesTable ORDER BY name',
    );

    return results.map((row) => row['name'] as String).toList();
  }

  /// Gets metadata for a space.
  Future<Map<String, dynamic>?> getSpaceMetadata(String spaceName) async {
    final results = await executeRawQuery(
      'SELECT metadata FROM $_spacesTable WHERE name = ?',
      [spaceName],
    );

    if (results.isEmpty) {
      return null;
    }

    final metadataJson = results.first['metadata'] as String?;
    return metadataJson != null ? _decodeMetadata(metadataJson) : null;
  }

  /// Updates metadata for a space.
  Future<void> updateSpaceMetadata(
    String spaceName,
    Map<String, dynamic> metadata,
  ) async {
    await _lock.synchronized(() async {
      final metadataJson = _encodeMetadata(metadata);

      await executeRawUpdate(
        'UPDATE $_spacesTable SET metadata = ? WHERE name = ?',
        [metadataJson, spaceName],
      );
    });
  }

  /// Gets statistics for a space.
  Future<StorageStats> getSpaceStats(String spaceName) async {
    final tables = await _getSpaceTables(spaceName);
    var totalRecords = 0;
    var totalSize = 0;

    for (final table in tables) {
      try {
        final countResult = await executeRawQuery(
          'SELECT COUNT(*) as count FROM $table',
        );
        if (countResult.isNotEmpty && countResult.first['count'] != null) {
          totalRecords += countResult.first['count'] as int;
        }
      } catch (_) {
        // Table might not exist, skip it
      }

      // Estimate size (simplified - in production would use actual database size)
      totalSize += totalRecords * 100; // Rough estimate
    }

    return StorageStats(
      tableCount: tables.length,
      recordCount: totalRecords,
      storageSize: totalSize,
      spaceCount: 1,
      cacheHitRate: 0,
      averageQueryTime: 0,
    );
  }

  /// Checks if a space exists.
  Future<bool> spaceExists(String spaceName) async {
    final results = await executeRawQuery(
      'SELECT id FROM $_spacesTable WHERE name = ?',
      [spaceName],
    );

    return results.isNotEmpty;
  }

  /// Ensures a space exists, creating it if necessary.
  Future<void> _ensureSpaceExists(String spaceName) async {
    final exists = await spaceExists(spaceName);
    if (!exists) {
      final now = DateTime.now().toIso8601String();
      await executeRawInsert(
        'INSERT INTO $_spacesTable (name, created_at, metadata) VALUES (?, ?, ?)',
        [spaceName, now, null],
      );
    }
  }

  /// Gets all table names for a specific space.
  Future<List<String>> _getSpaceTables(String spaceName) async {
    final allTables = await _getAllTableNames();
    final prefix = '${spaceName}_';

    return allTables
        .where((table) => table.startsWith(prefix) && !_isMetadataTable(table))
        .toList();
  }

  /// Gets all table names in the database.
  Future<List<String>> _getAllTableNames() async {
    final results = await executeRawQuery(
      r"SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE '\_%' ESCAPE '\'",
    );

    return results.map((row) => row['name'] as String).toList();
  }

  /// Checks if a table is a metadata table.
  bool _isMetadataTable(String tableName) {
    return tableName.startsWith('_');
  }

  /// Validates space name.
  void _validateSpaceName(String spaceName) {
    if (spaceName.isEmpty) {
      throw ArgumentError('Space name cannot be empty');
    }

    if (spaceName.contains('_')) {
      throw ArgumentError('Space name cannot contain underscores');
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(spaceName)) {
      throw ArgumentError(
        'Space name can only contain alphanumeric characters',
      );
    }
  }

  /// Encodes metadata to JSON string.
  String _encodeMetadata(Map<String, dynamic> metadata) {
    return metadata.toString(); // Simplified - in production use json.encode
  }

  /// Decodes metadata from JSON string.
  Map<String, dynamic> _decodeMetadata(String json) {
    // Simplified - in production use json.decode
    return {};
  }

  /// Loads global tables from database.
  Future<void> loadGlobalTables() async {
    final results = await executeRawQuery(
      'SELECT table_name FROM $_globalTablesTable',
    );

    _globalTables.clear();
    for (final row in results) {
      _globalTables.add(row['table_name'] as String);
    }
  }

  /// Registers global tables from schemas.
  Future<void> registerGlobalTablesFromSchemas(
    List<TableSchema> schemas,
  ) async {
    for (final schema in schemas) {
      if (schema.isGlobal) {
        await registerGlobalTable(schema.name);
      }
    }
  }
}

/// Simple lock implementation for thread-safety.
class _SpaceLock {
  Completer<void> _current = Completer<void>()..complete();

  /// Executes a function with exclusive access.
  Future<T> synchronized<T>(Future<T> Function() fn) async {
    final previous = _current;
    final completer = Completer<void>();
    _current = completer;

    try {
      await previous.future;
      return await fn();
    } finally {
      completer.complete();
    }
  }
}
