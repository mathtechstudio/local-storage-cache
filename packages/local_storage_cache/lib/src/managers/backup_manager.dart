// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:local_storage_cache/src/models/backup_config.dart';
import 'package:local_storage_cache/src/models/restore_config.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Manages backup and restore operations.
///
/// The BackupManager provides comprehensive backup and restore functionality
/// with support for multiple formats, compression, and encryption.
///
/// Example:
/// ```dart
/// final backupManager = BackupManager(platform: platform);
///
/// // Create backup
/// await backupManager.backup(
///   '/path/to/backup.json',
///   config: BackupConfig(
///     format: BackupFormat.json,
///     compression: CompressionType.gzip,
///   ),
/// );
///
/// // Restore from backup
/// await backupManager.restore(
///   '/path/to/backup.json',
///   config: RestoreConfig(
///     conflictResolution: ConflictResolution.replace,
///   ),
/// );
/// ```
class BackupManager {
  /// Creates a backup manager.
  BackupManager({
    required LocalStorageCachePlatform platform,
  }) : _platform = platform;

  final LocalStorageCachePlatform _platform;

  /// Creates a backup.
  Future<void> backup(
    String destinationPath, {
    BackupConfig config = const BackupConfig(),
  }) async {
    config.onProgress?.call(0.0, 'Starting backup...');

    try {
      switch (config.format) {
        case BackupFormat.json:
          await _backupToJson(destinationPath, config);
          break;
        case BackupFormat.sqlite:
          await _backupSqlite(destinationPath, config);
          break;
        case BackupFormat.binary:
          await _backupBinary(destinationPath, config);
          break;
      }

      config.onProgress?.call(1.0, 'Backup completed');
    } catch (e) {
      config.onProgress?.call(0.0, 'Backup failed: $e');
      rethrow;
    }
  }

  /// Restores from a backup.
  Future<void> restore(
    String sourcePath, {
    RestoreConfig config = const RestoreConfig(),
  }) async {
    config.onProgress?.call(0.0, 'Starting restore...');

    try {
      // Detect format from file
      final format = await _detectBackupFormat(sourcePath);

      switch (format) {
        case BackupFormat.json:
          await _restoreFromJson(sourcePath, config);
          break;
        case BackupFormat.sqlite:
          await _restoreSqlite(sourcePath, config);
          break;
        case BackupFormat.binary:
          await _restoreBinary(sourcePath, config);
          break;
      }

      config.onProgress?.call(1.0, 'Restore completed');
    } catch (e) {
      config.onProgress?.call(0.0, 'Restore failed: $e');
      rethrow;
    }
  }

  Future<void> _backupToJson(
    String destinationPath,
    BackupConfig config,
  ) async {
    config.onProgress?.call(0.1, 'Collecting data...');

    // Get all tables and data
    final data = await _collectData(config);

    config.onProgress?.call(0.5, 'Writing backup file...');

    // Convert to JSON
    final jsonData = jsonEncode(data);

    // Write to file
    final file = File(destinationPath);
    await file.writeAsString(jsonData);

    config.onProgress?.call(0.9, 'Finalizing...');

    // Apply compression if needed
    if (config.compression != CompressionType.none) {
      await _compressFile(destinationPath, config.compression);
    }
  }

  Future<void> _backupSqlite(
    String destinationPath,
    BackupConfig config,
  ) async {
    config.onProgress?.call(0.5, 'Copying database file...');

    // Use platform's export functionality
    await _platform.exportDatabase('', destinationPath);

    config.onProgress?.call(0.9, 'Finalizing...');
  }

  Future<void> _backupBinary(
    String destinationPath,
    BackupConfig config,
  ) async {
    // Binary format implementation
    throw UnimplementedError('Binary backup format not yet implemented');
  }

  Future<void> _restoreFromJson(
    String sourcePath,
    RestoreConfig config,
  ) async {
    config.onProgress?.call(0.1, 'Reading backup file...');

    // Read file
    final file = File(sourcePath);
    var content = await file.readAsString();

    // Decompress if needed
    if (sourcePath.endsWith('.gz')) {
      content = await _decompressFile(sourcePath);
    }

    config.onProgress?.call(0.3, 'Parsing data...');

    // Parse JSON
    final data = jsonDecode(content) as Map<String, dynamic>;

    config.onProgress?.call(0.5, 'Restoring data...');

    // Restore data
    await _restoreData(data, config);

    config.onProgress?.call(0.9, 'Finalizing...');
  }

  Future<void> _restoreSqlite(
    String sourcePath,
    RestoreConfig config,
  ) async {
    config.onProgress?.call(0.5, 'Importing database file...');

    // Use platform's import functionality
    await _platform.importDatabase(sourcePath, '');

    config.onProgress?.call(0.9, 'Finalizing...');
  }

  Future<void> _restoreBinary(
    String sourcePath,
    RestoreConfig config,
  ) async {
    // Binary format implementation
    throw UnimplementedError('Binary restore format not yet implemented');
  }

  Future<Map<String, dynamic>> _collectData(BackupConfig config) async {
    final result = <String, dynamic>{
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'tables': <String, dynamic>{},
      'spaces': <String, dynamic>{},
    };

    // Get all tables
    final tablesQuery = '''
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name NOT LIKE 'sqlite_%'
    ''';
    final tables = await _platform.query(tablesQuery, [], '');

    var progress = 0.2;
    final progressStep = 0.6 / tables.length;

    for (final table in tables) {
      final tableName = table['name'] as String;

      // Skip if selective backup and table not included
      if (config.includeTables != null &&
          !config.includeTables!.contains(tableName)) {
        continue;
      }

      // Skip if table is excluded
      if (config.excludeTables != null &&
          config.excludeTables!.contains(tableName)) {
        continue;
      }

      // Get table data
      final dataQuery = 'SELECT * FROM $tableName';
      final tableData = await _platform.query(dataQuery, [], '');

      result['tables'][tableName] = tableData;

      progress += progressStep;
      config.onProgress?.call(progress, 'Backing up table: $tableName');
    }

    return result;
  }

  Future<void> _restoreData(
    Map<String, dynamic> data,
    RestoreConfig config,
  ) async {
    final tables = data['tables'] as Map<String, dynamic>? ?? {};

    var progress = 0.5;
    final progressStep = 0.4 / tables.length;

    for (final entry in tables.entries) {
      final tableName = entry.key;
      final tableData = entry.value as List<dynamic>;

      // Skip if selective restore and table not included
      if (config.includeTables != null &&
          !config.includeTables!.contains(tableName)) {
        continue;
      }

      // Skip if table is excluded
      if (config.excludeTables != null &&
          config.excludeTables!.contains(tableName)) {
        continue;
      }

      config.onProgress?.call(progress, 'Restoring table: $tableName');

      // Restore each record
      for (final record in tableData) {
        final recordMap = record as Map<String, dynamic>;
        await _restoreRecord(tableName, recordMap, config);
      }

      progress += progressStep;
    }
  }

  Future<void> _restoreRecord(
    String tableName,
    Map<String, dynamic> record,
    RestoreConfig config,
  ) async {
    // Check if record exists (assuming 'id' as primary key)
    final id = record['id'];
    if (id != null) {
      final existingQuery = 'SELECT id FROM $tableName WHERE id = ? LIMIT 1';
      final existing = await _platform.query(existingQuery, [id], '');

      if (existing.isNotEmpty) {
        // Record exists, handle conflict
        switch (config.conflictResolution) {
          case ConflictResolution.skip:
            return; // Skip this record
          case ConflictResolution.replace:
            // Delete existing and insert new
            await _platform.delete(
                'DELETE FROM $tableName WHERE id = ?', [id], '');
            break;
          case ConflictResolution.fail:
            throw StateError(
                'Conflict: Record with id $id already exists in $tableName');
          case ConflictResolution.merge:
            // Update existing with new values
            final fields = record.keys
                .where((k) => k != 'id')
                .map((k) => '$k = ?')
                .join(', ');
            final values = record.entries
                .where((e) => e.key != 'id')
                .map((e) => e.value)
                .toList()
              ..add(id);
            await _platform.update(
                'UPDATE $tableName SET $fields WHERE id = ?', values, '');
            return;
        }
      }
    }

    // Insert the record
    await _platform.insert(tableName, record, '');
  }

  Future<BackupFormat> _detectBackupFormat(String path) async {
    if (path.endsWith('.json') || path.endsWith('.json.gz')) {
      return BackupFormat.json;
    } else if (path.endsWith('.db') || path.endsWith('.sqlite')) {
      return BackupFormat.sqlite;
    } else {
      return BackupFormat.binary;
    }
  }

  Future<void> _compressFile(String path, CompressionType type) async {
    if (type == CompressionType.none) return;

    final file = File(path);
    final bytes = await file.readAsBytes();

    List<int> compressed;
    switch (type) {
      case CompressionType.gzip:
        compressed = gzip.encode(bytes);
        break;
      case CompressionType.zlib:
        compressed = zlib.encode(bytes);
        break;
      case CompressionType.none:
        return;
    }

    // Write compressed file with .gz extension
    final compressedFile = File('$path.gz');
    await compressedFile.writeAsBytes(compressed);

    // Delete original file
    await file.delete();
  }

  Future<String> _decompressFile(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    List<int> decompressed;
    if (path.endsWith('.gz')) {
      decompressed = gzip.decode(bytes);
    } else {
      // Try zlib
      try {
        decompressed = zlib.decode(bytes);
      } catch (e) {
        // Not compressed, return as is
        return utf8.decode(bytes);
      }
    }

    return utf8.decode(decompressed);
  }
}
