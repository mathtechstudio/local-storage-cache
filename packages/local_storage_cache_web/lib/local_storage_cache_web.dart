/// Web implementation of the local_storage_cache plugin.
library local_storage_cache_web;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';
import 'package:web/web.dart' as web;

/// Web implementation of [LocalStorageCachePlatform].
class LocalStorageCacheWeb extends LocalStorageCachePlatform {
  web.IDBDatabase? _database;
  String? _databaseName;

  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith(Registrar registrar) {
    LocalStorageCachePlatform.instance = LocalStorageCacheWeb();
  }

  @override
  Future<void> initialize(
    String databasePath,
    Map<String, dynamic> config,
  ) async {
    _databaseName =
        (config['databaseName'] as String?) ?? 'local_storage_cache';
    final version = (config['version'] as int?) ?? 1;

    final completer = Completer<web.IDBDatabase>();

    final request = web.window.indexedDB.open(_databaseName!, version);

    request
      ..onupgradeneeded = (web.IDBVersionChangeEvent event) {
        final db = (request.result as JSObject?) as web.IDBDatabase?;
        if (db == null) return;

        // Create default object store if it doesn't exist
        final storeNames = db.objectStoreNames;
        var hasDefault = false;
        for (var i = 0; i < storeNames.length; i++) {
          if (storeNames.item(i) == 'default') {
            hasDefault = true;
            break;
          }
        }

        if (!hasDefault) {
          db.createObjectStore(
            'default',
            web.IDBObjectStoreParameters(
              keyPath: 'id'.toJS,
              autoIncrement: true,
            ),
          );
        }
      }.toJS
      ..onsuccess = (web.Event event) {
        completer.complete((request.result as JSObject?) as web.IDBDatabase?);
      }.toJS
      ..onerror = (web.Event event) {
        completer.completeError(Exception('Failed to open database'));
      }.toJS;

    _database = await completer.future;
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  @override
  Future<dynamic> insert(
    String tableName,
    Map<String, dynamic> data,
    String space,
  ) async {
    if (_database == null) throw Exception('Database not initialized');

    final storeName = _getStoreName(tableName, space);
    await _ensureObjectStore(storeName);

    final transaction = _database!.transaction(storeName.toJS, 'readwrite');
    final store = transaction.objectStore(storeName);

    final completer = Completer<JSAny?>();
    final request = store.add(data.jsify());

    request
      ..onsuccess = (web.Event event) {
        completer.complete(request.result);
      }.toJS
      ..onerror = (web.Event event) {
        completer.completeError(Exception('Insert failed'));
      }.toJS;

    return completer.future;
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql,
    List<dynamic> arguments,
    String space,
  ) async {
    if (_database == null) throw Exception('Database not initialized');

    // Parse simple SQL queries for IndexedDB
    final tableName = _extractTableName(sql);
    final storeName = _getStoreName(tableName, space);

    try {
      await _ensureObjectStore(storeName);

      final transaction = _database!.transaction(storeName.toJS, 'readonly');
      final store = transaction.objectStore(storeName);

      final results = <Map<String, dynamic>>[];
      final completer = Completer<List<Map<String, dynamic>>>();

      final request = store.openCursor();

      request
        ..onsuccess = (web.Event event) {
          final cursor =
              (request.result as JSObject?) as web.IDBCursorWithValue?;
          if (cursor != null) {
            final value = (cursor as JSObject)['value'];
            if (value != null) {
              final dartValue = (value).dartify();
              if (dartValue is Map) {
                results.add(Map<String, dynamic>.from(dartValue));
              }
            }
            (cursor as JSObject).callMethod('continue'.toJS);
          } else {
            completer.complete(results);
          }
        }.toJS
        ..onerror = (web.Event event) {
          completer.completeError(Exception('Query failed'));
        }.toJS;

      return await completer.future;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> update(String sql, List<dynamic> arguments, String space) async {
    return 0; // Simplified
  }

  @override
  Future<int> delete(String sql, List<dynamic> arguments, String space) async {
    return 0; // Simplified
  }

  @override
  Future<void> executeBatch(
    List<BatchOperation> operations,
    String space,
  ) async {
    for (final operation in operations) {
      if (operation.type == 'insert' && operation.data != null) {
        await insert(operation.tableName, operation.data!, space);
      }
    }
  }

  @override
  Future<T> transaction<T>(Future<T> Function() action, String space) async {
    return action();
  }

  @override
  Future<String> encrypt(String data, String algorithm) async {
    return base64Encode(utf8.encode(data)); // Simplified
  }

  @override
  Future<String> decrypt(String encryptedData, String algorithm) async {
    return utf8.decode(base64Decode(encryptedData)); // Simplified
  }

  @override
  Future<void> setEncryptionKey(String key) async {}

  @override
  Future<void> saveSecureKey(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  @override
  Future<String?> getSecureKey(String key) async {
    return web.window.localStorage.getItem(key);
  }

  @override
  Future<void> deleteSecureKey(String key) async {
    web.window.localStorage.removeItem(key);
  }

  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<bool> authenticateWithBiometric(String reason) async => false;

  @override
  Future<void> exportDatabase(String sourcePath, String destinationPath) async {
    if (_database == null) throw Exception('Database not initialized');

    final data = <String, dynamic>{};
    final storeNames = _database!.objectStoreNames;

    for (var i = 0; i < storeNames.length; i++) {
      final storeName = storeNames.item(i);
      if (storeName == null) continue;

      final transaction = _database!.transaction(storeName.toJS, 'readonly');
      final store = transaction.objectStore(storeName);

      final results = <Map<String, dynamic>>[];
      final completer = Completer<void>();

      final request = store.openCursor();

      request
        ..onsuccess = (web.Event event) {
          final cursor =
              (request.result as JSObject?) as web.IDBCursorWithValue?;
          if (cursor != null) {
            final value = (cursor as JSObject)['value'];
            if (value != null) {
              final dartValue = (value).dartify();
              if (dartValue is Map) {
                results.add(Map<String, dynamic>.from(dartValue));
              }
            }
            (cursor as JSObject).callMethod('continue'.toJS);
          } else {
            completer.complete();
          }
        }.toJS
        ..onerror = (web.Event event) {
          completer.completeError(Exception('Export failed'));
        }.toJS;

      await completer.future;
      data[storeName] = results;
    }

    final jsonString = jsonEncode(data);
    final blob = web.Blob(
      [jsonString.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);

    web.HTMLAnchorElement()
      ..href = url
      ..download = 'database_export.json'
      ..click();

    web.URL.revokeObjectURL(url);
  }

  @override
  Future<void> importDatabase(String sourcePath, String destinationPath) async {
    throw UnimplementedError('Import not implemented for web');
  }

  @override
  Future<void> vacuum() async {}

  @override
  Future<Map<String, dynamic>> getStorageInfo() async {
    if (_database == null) throw Exception('Database not initialized');

    return {
      'databaseName': _databaseName,
      'version': _database!.version,
      'objectStores': _database!.objectStoreNames.length,
    };
  }

  Future<void> _ensureObjectStore(String storeName) async {
    final storeNames = _database!.objectStoreNames;
    var hasStore = false;
    for (var i = 0; i < storeNames.length; i++) {
      if (storeNames.item(i) == storeName) {
        hasStore = true;
        break;
      }
    }

    if (hasStore) {
      return;
    }

    final currentVersion = _database!.version;
    _database!.close();

    final completer = Completer<web.IDBDatabase>();
    final request =
        web.window.indexedDB.open(_databaseName!, currentVersion + 1);

    request
      ..onupgradeneeded = (web.IDBVersionChangeEvent event) {
        final db = (request.result as JSObject?) as web.IDBDatabase?;
        if (db == null) return;

        final storeNames = db.objectStoreNames;
        var hasStore = false;
        for (var i = 0; i < storeNames.length; i++) {
          if (storeNames.item(i) == storeName) {
            hasStore = true;
            break;
          }
        }

        if (!hasStore) {
          db.createObjectStore(
            storeName,
            web.IDBObjectStoreParameters(
              keyPath: 'id'.toJS,
              autoIncrement: true,
            ),
          );
        }
      }.toJS
      ..onsuccess = (web.Event event) {
        completer.complete((request.result as JSObject?) as web.IDBDatabase?);
      }.toJS
      ..onerror = (web.Event event) {
        completer.completeError(Exception('Failed to create object store'));
      }.toJS;

    _database = await completer.future;
  }

  String _getStoreName(String tableName, String space) {
    return '${space}_$tableName';
  }

  String _extractTableName(String sql) {
    final match = RegExp(r'FROM\s+(\w+)', caseSensitive: false).firstMatch(sql);
    return match?.group(1) ?? 'default';
  }
}
