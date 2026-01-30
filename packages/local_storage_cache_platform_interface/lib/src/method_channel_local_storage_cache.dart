import 'package:flutter/services.dart';
import 'package:local_storage_cache_platform_interface/src/local_storage_cache_platform.dart';
import 'package:local_storage_cache_platform_interface/src/models/batch_operation.dart';

/// An implementation of [LocalStorageCachePlatform] that uses method channels.
class MethodChannelLocalStorageCache extends LocalStorageCachePlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _channel = const MethodChannel('local_storage_cache');

  @override
  Future<void> initialize(
    String databasePath,
    Map<String, dynamic> config,
  ) async {
    await _channel.invokeMethod<void>('initialize', {
      'databasePath': databasePath,
      'config': config,
    });
  }

  @override
  Future<void> close() async {
    await _channel.invokeMethod<void>('close');
  }

  @override
  Future<dynamic> insert(
    String tableName,
    Map<String, dynamic> data,
    String space,
  ) async {
    return _channel.invokeMethod('insert', {
      'tableName': tableName,
      'data': data,
      'space': space,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql,
    List<dynamic> arguments,
    String space,
  ) async {
    final result = await _channel.invokeMethod<List<dynamic>>('query', {
      'sql': sql,
      'arguments': arguments,
      'space': space,
    });
    if (result == null) return [];
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<int> update(
    String sql,
    List<dynamic> arguments,
    String space,
  ) async {
    final result = await _channel.invokeMethod<int>('update', {
      'sql': sql,
      'arguments': arguments,
      'space': space,
    });
    return result ?? 0;
  }

  @override
  Future<int> delete(
    String sql,
    List<dynamic> arguments,
    String space,
  ) async {
    final result = await _channel.invokeMethod<int>('delete', {
      'sql': sql,
      'arguments': arguments,
      'space': space,
    });
    return result ?? 0;
  }

  @override
  Future<void> executeBatch(
    List<BatchOperation> operations,
    String space,
  ) async {
    await _channel.invokeMethod<void>('executeBatch', {
      'operations': operations.map((op) => op.toMap()).toList(),
      'space': space,
    });
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() action,
    String space,
  ) async {
    // Note: Transaction handling is complex with method channels
    // This is a simplified implementation
    await _channel.invokeMethod<void>('beginTransaction', {'space': space});
    try {
      final result = await action();
      await _channel.invokeMethod<void>('commitTransaction', {'space': space});
      return result;
    } catch (e) {
      await _channel
          .invokeMethod<void>('rollbackTransaction', {'space': space});
      rethrow;
    }
  }

  @override
  Future<String> encrypt(String data, String algorithm) async {
    final result = await _channel.invokeMethod<String>('encrypt', {
      'data': data,
      'algorithm': algorithm,
    });
    return result ?? '';
  }

  @override
  Future<String> decrypt(String encryptedData, String algorithm) async {
    final result = await _channel.invokeMethod<String>('decrypt', {
      'encryptedData': encryptedData,
      'algorithm': algorithm,
    });
    return result ?? '';
  }

  @override
  Future<void> setEncryptionKey(String key) async {
    await _channel.invokeMethod<void>('setEncryptionKey', {'key': key});
  }

  @override
  Future<void> saveSecureKey(String key, String value) async {
    await _channel.invokeMethod<void>('saveSecureKey', {
      'key': key,
      'value': value,
    });
  }

  @override
  Future<String?> getSecureKey(String key) async {
    return _channel.invokeMethod<String>('getSecureKey', {'key': key});
  }

  @override
  Future<void> deleteSecureKey(String key) async {
    await _channel.invokeMethod<void>('deleteSecureKey', {'key': key});
  }

  @override
  Future<bool> isBiometricAvailable() async {
    final result = await _channel.invokeMethod<bool>('isBiometricAvailable');
    return result ?? false;
  }

  @override
  Future<bool> authenticateWithBiometric(String reason) async {
    final result =
        await _channel.invokeMethod<bool>('authenticateWithBiometric', {
      'reason': reason,
    });
    return result ?? false;
  }

  @override
  Future<void> exportDatabase(String sourcePath, String destinationPath) async {
    await _channel.invokeMethod<void>('exportDatabase', {
      'sourcePath': sourcePath,
      'destinationPath': destinationPath,
    });
  }

  @override
  Future<void> importDatabase(String sourcePath, String destinationPath) async {
    await _channel.invokeMethod<void>('importDatabase', {
      'sourcePath': sourcePath,
      'destinationPath': destinationPath,
    });
  }

  @override
  Future<void> vacuum() async {
    await _channel.invokeMethod<void>('vacuum');
  }

  @override
  Future<Map<String, dynamic>> getStorageInfo() async {
    final result =
        await _channel.invokeMethod<Map<dynamic, dynamic>>('getStorageInfo');
    if (result == null) return {};
    return Map<String, dynamic>.from(result);
  }
}
