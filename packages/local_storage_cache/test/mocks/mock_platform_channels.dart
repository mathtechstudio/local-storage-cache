import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up mock platform channels for testing.
///
/// This mocks the platform channels used by path_provider and sqflite
/// so tests can run without actual platform implementations.
void setupMockPlatformChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        // Return a mock path for testing
        return '/tmp/test_storage';
      }
      return null;
    },
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('local_storage_cache'),
    (MethodCall methodCall) async {
      final args = methodCall.arguments as Map<dynamic, dynamic>?;

      switch (methodCall.method) {
        case 'initialize':
          return null;
        case 'close':
          return null;
        case 'insert':
          // Store the inserted data
          final data = Map<String, dynamic>.from(args!['data'] as Map);
          final id = _mockInsertId++;
          data['id'] = id;

          if (_inTransaction) {
            _transactionBuffer.add(data);
          } else {
            _mockDatabase.add(data);
          }
          return id;
        case 'query':
          // Return mock query results based on SQL
          final sql = args!['sql'] as String;
          final arguments = (args['arguments'] as List?) ?? [];

          // Handle CREATE TABLE
          if (sql.toUpperCase().startsWith('CREATE TABLE')) {
            return [];
          }

          // Handle INSERT OR REPLACE
          if (sql.toUpperCase().startsWith('INSERT OR REPLACE')) {
            final valuesMatch =
                RegExp(r'VALUES\s*\((.*?)\)', caseSensitive: false)
                    .firstMatch(sql);
            if (valuesMatch != null) {
              final tableMatch =
                  RegExp(r'INTO\s+([\w_]+)', caseSensitive: false)
                      .firstMatch(sql);
              if (tableMatch != null) {
                final tableName = tableMatch.group(1)!;
                final columnsMatch =
                    RegExp(r'\((.*?)\)\s+VALUES', caseSensitive: false)
                        .firstMatch(sql);

                if (columnsMatch != null) {
                  final columns = columnsMatch
                      .group(1)!
                      .split(',')
                      .map((c) => c.trim())
                      .toList();
                  final data = <String, dynamic>{};
                  for (var i = 0;
                      i < columns.length && i < arguments.length;
                      i++) {
                    data[columns[i]] = arguments[i];
                  }

                  // For key-value tables, replace existing key
                  if (tableName.endsWith('__kv') || tableName == '_global_kv') {
                    final key = data['key'];
                    if (key != null) {
                      _mockKeyValueStore['$tableName:$key'] = data;
                    }
                  } else {
                    _mockDatabase.add(data);
                  }
                }
              }
              return [];
            }
          }

          // Handle SELECT from key-value tables
          if (sql.toUpperCase().contains('FROM') &&
              (sql.contains('__kv') || sql.contains('_global_kv'))) {
            final tableMatch = RegExp(r'FROM\s+([\w_]+)', caseSensitive: false)
                .firstMatch(sql);
            final whereMatch =
                RegExp(r'WHERE\s+key\s*=\s*\?', caseSensitive: false)
                    .firstMatch(sql);
            if (tableMatch != null &&
                whereMatch != null &&
                arguments.isNotEmpty) {
              final tableName = tableMatch.group(1)!;
              final key = arguments[0];
              final record = _mockKeyValueStore['$tableName:$key'];
              return record != null ? [record] : [];
            }
            return [];
          }

          // Handle COUNT queries
          if (sql.toUpperCase().contains('COUNT(*)')) {
            final filtered = _filterRecords(sql, arguments);
            return [
              {'count': filtered.length},
            ];
          }

          // Filter records based on WHERE clause
          var filtered = _filterRecords(sql, arguments);

          // Handle ORDER BY
          filtered = _applyOrderBy(sql, filtered);

          // Handle LIMIT and OFFSET
          filtered = _applyLimitOffset(sql, filtered);

          return filtered.map(Map<String, dynamic>.from).toList();
        case 'update':
          // Handle update with or without WHERE clause
          final sql = args!['sql'] as String;
          final arguments = (args['arguments'] as List?) ?? [];

          // Extract SET values (first N arguments) and WHERE arguments (remaining)
          final setMatch =
              RegExp(r'SET\s+(.+?)(?:\s+WHERE|$)', caseSensitive: false)
                  .firstMatch(sql);
          if (setMatch != null) {
            final setClause = setMatch.group(1) ?? '';
            final setFieldCount = ','.allMatches(setClause).length + 1;

            final setValues = arguments.take(setFieldCount).toList();
            final whereArguments = arguments.skip(setFieldCount).toList();

            // Get fields to update
            final fields = setClause
                .split(',')
                .map((s) => s.trim().split('=')[0].trim())
                .toList();

            // Filter records (all if no WHERE clause)
            final filtered = sql.toUpperCase().contains('WHERE')
                ? _filterRecords(sql, whereArguments)
                : _mockDatabase;

            var updated = 0;
            for (final record in filtered) {
              for (var i = 0; i < fields.length && i < setValues.length; i++) {
                record[fields[i]] = setValues[i];
              }
              updated++;
            }
            return updated;
          }
          return 0;
        case 'delete':
          // Handle delete with WHERE clause
          final sql = args!['sql'] as String;
          final arguments = (args['arguments'] as List?) ?? [];

          // Handle DELETE from key-value tables
          if (sql.contains('__kv') || sql.contains('_global_kv')) {
            final tableMatch = RegExp(r'FROM\s+([\w_]+)', caseSensitive: false)
                .firstMatch(sql);
            final whereMatch =
                RegExp(r'WHERE\s+key\s*=\s*\?', caseSensitive: false)
                    .firstMatch(sql);
            if (tableMatch != null &&
                whereMatch != null &&
                arguments.isNotEmpty) {
              final tableName = tableMatch.group(1)!;
              final key = arguments[0];
              _mockKeyValueStore.remove('$tableName:$key');
              return 1;
            }
            return 0;
          }

          if (sql.toUpperCase().contains('WHERE')) {
            // Filter and delete matching records
            final toDelete = _filterRecords(sql, arguments);
            final deleted = toDelete.length;
            for (final record in toDelete) {
              _mockDatabase.remove(record);
            }
            return deleted;
          } else {
            // Delete all
            final deleted = _mockDatabase.length;
            _mockDatabase.clear();
            return deleted;
          }
        case 'executeBatch':
          // Handle batch operations
          final operations = args!['operations'] as List;
          for (final op in operations) {
            final operation = op as Map;
            final type = operation['type'] as String;

            if (type == 'insert') {
              final data = Map<String, dynamic>.from(operation['data'] as Map);
              final id = _mockInsertId++;
              data['id'] = id;
              _mockDatabase.add(data);
            } else if (type == 'update') {
              final data = Map<String, dynamic>.from(operation['data'] as Map);
              // For batch update, we expect the data to contain the ID or WHERE condition
              // Update all matching records
              for (final record in _mockDatabase) {
                if (data.containsKey('id') && record['id'] == data['id']) {
                  record.addAll(data);
                } else if (data.containsKey('username') &&
                    record['username'] == data['username']) {
                  record.addAll(data);
                }
              }
            } else if (type == 'delete') {
              final sql = operation['sql'] as String?;
              final arguments = (operation['arguments'] as List?) ?? [];

              if (sql != null) {
                // Use SQL-based deletion
                final toDelete = _filterRecords(sql, arguments);
                for (final record in toDelete) {
                  _mockDatabase.remove(record);
                }
              }
            }
          }
          return null;
        case 'transaction':
          final action = args?['action'] as String?;

          if (action == 'begin') {
            _inTransaction = true;
            _transactionBuffer = [];
          } else if (action == 'commit') {
            if (_inTransaction) {
              _mockDatabase.addAll(_transactionBuffer);
              _transactionBuffer = [];
              _inTransaction = false;
            }
          } else if (action == 'rollback') {
            if (_inTransaction) {
              _transactionBuffer = [];
              _inTransaction = false;
            }
          }
          return null;
        case 'beginTransaction':
          _inTransaction = true;
          _transactionBuffer = [];
          return null;
        case 'commitTransaction':
          if (_inTransaction) {
            _mockDatabase.addAll(_transactionBuffer);
            _transactionBuffer = [];
            _inTransaction = false;
          }
          return null;
        case 'rollbackTransaction':
          if (_inTransaction) {
            _transactionBuffer = [];
            _inTransaction = false;
          }
          return null;
        case 'vacuum':
          return null;
        case 'getStorageInfo':
          return {
            'recordCount': _mockDatabase.length,
            'tableCount': 1,
            'storageSize': 1024,
          };
        case 'setEncryptionKey':
          return null;
        case 'saveSecureKey':
          _mockSecureStorage[args!['key'] as String] = args['value'] as String;
          return null;
        case 'getSecureKey':
          return _mockSecureStorage[args!['key'] as String];
        case 'deleteSecureKey':
          _mockSecureStorage.remove(args!['key'] as String);
          return null;
        case 'isBiometricAvailable':
          return false;
        case 'authenticateWithBiometric':
          return true;
        case 'encrypt':
          // Simple mock encryption: base64 encode with algorithm prefix
          final data = args!['data'] as String;
          final algorithm = args['algorithm'] as String;
          final encoded = base64.encode(utf8.encode(data));
          return 'ENC:$algorithm:$encoded';
        case 'decrypt':
          // Simple mock decryption: remove prefix and base64 decode
          final encryptedData = args!['encryptedData'] as String;
          if (encryptedData.startsWith('ENC:')) {
            final parts = encryptedData.split(':');
            if (parts.length >= 3) {
              final encoded = parts.sublist(2).join(':');
              final decoded = base64.decode(encoded);
              return utf8.decode(decoded);
            }
          }
          return encryptedData;
        default:
          return null;
      }
    },
  );
}

/// Resets mock data between tests.
void resetMockData() {
  _mockInsertId = 1;
  _mockDatabase = [];
  _mockSecureStorage = {};
  _mockKeyValueStore = {};
  _inTransaction = false;
  _transactionBuffer = [];
}

/// Sets mock query results for the next query.
void setMockQueryResults(List<Map<String, dynamic>> results) {
  _mockDatabase = List<Map<String, dynamic>>.from(results);
}

/// Gets the current mock insert ID.
int getMockInsertId() => _mockInsertId - 1;

/// Gets the mock database for inspection.
List<Map<String, dynamic>> getMockDatabase() => _mockDatabase;

/// Adds a record to mock database.
void addMockRecord(Map<String, dynamic> record) {
  _mockDatabase.add(record);
}

/// Sets a key-value pair in mock storage.
void setMockKeyValue(String key, dynamic value) {
  _mockKeyValueStore[key] = value;
}

/// Gets a key-value pair from mock storage.
dynamic getMockKeyValue(String key) {
  return _mockKeyValueStore[key];
}

// Private state
int _mockInsertId = 1;
List<Map<String, dynamic>> _mockDatabase = [];
Map<String, String> _mockSecureStorage = {};
Map<String, dynamic> _mockKeyValueStore = {};
bool _inTransaction = false;
List<Map<String, dynamic>> _transactionBuffer = [];

/// Filters records based on SQL WHERE clause.
List<Map<String, dynamic>> _filterRecords(String sql, List<dynamic> arguments) {
  final normalizedSql = sql.toUpperCase();

  // If no WHERE clause, return all records
  if (!normalizedSql.contains('WHERE')) {
    return _mockDatabase;
  }

  // Extract WHERE clause
  final whereMatch = RegExp(
    r'WHERE\s+(.+?)(?:ORDER|GROUP|LIMIT|OFFSET|$)',
    caseSensitive: false,
  ).firstMatch(sql);
  if (whereMatch == null) return _mockDatabase;

  final whereClause = whereMatch.group(1)?.trim() ?? '';

  // Simple WHERE clause parsing for common cases
  return _mockDatabase.where((record) {
    return _evaluateWhereClause(record, whereClause, arguments);
  }).toList();
}

/// Evaluates a WHERE clause against a record.
bool _evaluateWhereClause(
  Map<String, dynamic> record,
  String whereClause,
  List<dynamic> arguments,
) {
  final normalizedWhere = whereClause.toUpperCase();

  // Handle field NOT IN (?, ?, ...) pattern - MUST come before IN check
  if (normalizedWhere.contains(' NOT IN ')) {
    final parts =
        whereClause.split(RegExp(r'\s+NOT\s+IN\s+', caseSensitive: false));
    if (parts.length == 2) {
      final field = parts[0].trim();
      final placeholderCount = '?'.allMatches(parts[1]).length;
      final values = arguments.take(placeholderCount).toList();
      return !values.contains(record[field]);
    }
  }

  // Handle field IN (?, ?, ...) pattern
  if (normalizedWhere.contains(' IN ')) {
    final parts = whereClause.split(RegExp(r'\s+IN\s+', caseSensitive: false));
    if (parts.length == 2) {
      final field = parts[0].trim();
      final placeholderCount = '?'.allMatches(parts[1]).length;
      final values = arguments.take(placeholderCount).toList();
      return values.contains(record[field]);
    }
  }

  // Handle field BETWEEN ? AND ? pattern
  if (normalizedWhere.contains(' BETWEEN ')) {
    final parts =
        whereClause.split(RegExp(r'\s+BETWEEN\s+', caseSensitive: false));
    if (parts.length == 2 && arguments.length >= 2) {
      final field = parts[0].trim();
      final value = record[field];
      final min = arguments[0];
      final max = arguments[1];
      if (value is num && min is num && max is num) {
        return value >= min && value <= max;
      }
    }
  }

  // Handle field LIKE ? pattern
  if (normalizedWhere.contains(' LIKE ')) {
    final parts =
        whereClause.split(RegExp(r'\s+LIKE\s+', caseSensitive: false));
    if (parts.length == 2 && arguments.isNotEmpty) {
      final field = parts[0].trim();
      final pattern = arguments[0] as String;
      final value = record[field]?.toString() ?? '';

      // Convert SQL LIKE pattern to regex
      final regexPattern = pattern.replaceAll('%', '.*').replaceAll('_', '.');

      return RegExp(regexPattern, caseSensitive: false).hasMatch(value);
    }
  }

  // Handle field IS NULL pattern
  if (normalizedWhere.contains(' IS NULL')) {
    final field = whereClause
        .split(RegExp(r'\s+IS\s+NULL', caseSensitive: false))[0]
        .trim();
    return record[field] == null;
  }

  // Handle field IS NOT NULL pattern
  if (normalizedWhere.contains(' IS NOT NULL')) {
    final field = whereClause
        .split(RegExp(r'\s+IS\s+NOT\s+NULL', caseSensitive: false))[0]
        .trim();
    return record[field] != null;
  }

  // Handle simple field = ? pattern
  if (RegExp(r'^\w+\s*=\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('=')[0].trim();
    if (arguments.isNotEmpty) {
      return record[field] == arguments[0];
    }
  }

  // Handle field != ? pattern
  if (RegExp(r'^\w+\s*!=\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('!=')[0].trim();
    if (arguments.isNotEmpty) {
      return record[field] != arguments[0];
    }
  }

  // Handle field > ? pattern
  if (RegExp(r'^\w+\s*>\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('>')[0].trim();
    if (arguments.isNotEmpty) {
      final value = record[field];
      final compareValue = arguments[0];
      if (value is num && compareValue is num) {
        return value > compareValue;
      }
    }
  }

  // Handle field < ? pattern
  if (RegExp(r'^\w+\s*<\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('<')[0].trim();
    if (arguments.isNotEmpty) {
      final value = record[field];
      final compareValue = arguments[0];
      if (value is num && compareValue is num) {
        return value < compareValue;
      }
    }
  }

  // Handle field >= ? pattern
  if (RegExp(r'^\w+\s*>=\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('>=')[0].trim();
    if (arguments.isNotEmpty) {
      final value = record[field];
      final compareValue = arguments[0];
      if (value is num && compareValue is num) {
        return value >= compareValue;
      }
    }
  }

  // Handle field <= ? pattern
  if (RegExp(r'^\w+\s*<=\s*\?$').hasMatch(whereClause.trim())) {
    final field = whereClause.split('<=')[0].trim();
    if (arguments.isNotEmpty) {
      final value = record[field];
      final compareValue = arguments[0];
      if (value is num && compareValue is num) {
        return value <= compareValue;
      }
    }
  }

  // Handle multiple conditions with AND
  if (normalizedWhere.contains(' AND ')) {
    final conditions =
        whereClause.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    var currentArgIndex = 0;

    for (final condition in conditions) {
      // Count placeholders in this condition
      final placeholderCount = '?'.allMatches(condition).length;
      final conditionArgs =
          arguments.skip(currentArgIndex).take(placeholderCount).toList();

      if (!_evaluateWhereClause(record, condition, conditionArgs)) {
        return false;
      }

      currentArgIndex += placeholderCount;
    }
    return true;
  }

  // Handle multiple conditions with OR
  if (normalizedWhere.contains(' OR ')) {
    final conditions =
        whereClause.split(RegExp(r'\s+OR\s+', caseSensitive: false));
    var currentArgIndex = 0;

    for (final condition in conditions) {
      // Count placeholders in this condition
      final placeholderCount = '?'.allMatches(condition).length;
      final conditionArgs =
          arguments.skip(currentArgIndex).take(placeholderCount).toList();

      if (_evaluateWhereClause(record, condition, conditionArgs)) {
        return true;
      }

      currentArgIndex += placeholderCount;
    }
    return false;
  }

  // Default: return true if we can't parse the WHERE clause
  return true;
}

/// Applies ORDER BY clause to results.
List<Map<String, dynamic>> _applyOrderBy(
  String sql,
  List<Map<String, dynamic>> records,
) {
  final orderByMatch =
      RegExp(r'ORDER\s+BY\s+(.+?)(?:LIMIT|OFFSET|$)', caseSensitive: false)
          .firstMatch(sql);
  if (orderByMatch == null) return records;

  final orderByClause = orderByMatch.group(1)?.trim() ?? '';
  final parts = orderByClause.split(',');

  final sorted = List<Map<String, dynamic>>.from(records);

  for (final part in parts.reversed) {
    final trimmed = part.trim();
    final ascending = !trimmed.toUpperCase().endsWith(' DESC');
    final field = trimmed
        .replaceAll(RegExp(r'\s+(ASC|DESC)$', caseSensitive: false), '')
        .trim();

    sorted.sort((a, b) {
      final aValue = a[field];
      final bValue = b[field];

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      int comparison;
      if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return ascending ? comparison : -comparison;
    });
  }

  return sorted;
}

/// Applies LIMIT and OFFSET clauses to results.
List<Map<String, dynamic>> _applyLimitOffset(
  String sql,
  List<Map<String, dynamic>> records,
) {
  var result = records;

  // Handle OFFSET
  final offsetMatch =
      RegExp(r'OFFSET\s+(\d+)', caseSensitive: false).firstMatch(sql);
  if (offsetMatch != null) {
    final offset = int.parse(offsetMatch.group(1)!);
    result = result.skip(offset).toList();
  }

  // Handle LIMIT
  final limitMatch =
      RegExp(r'LIMIT\s+(\d+)', caseSensitive: false).firstMatch(sql);
  if (limitMatch != null) {
    final limit = int.parse(limitMatch.group(1)!);
    result = result.take(limit).toList();
  }

  return result;
}
