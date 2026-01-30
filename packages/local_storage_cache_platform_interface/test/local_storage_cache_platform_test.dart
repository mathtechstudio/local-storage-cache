// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLocalStorageCachePlatform extends LocalStorageCachePlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<void> initialize(String databasePath, Map<String, dynamic> config) {
    return Future.value();
  }

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  Future<dynamic> insert(
    String tableName,
    Map<String, dynamic> data,
    String space,
  ) {
    return Future.value(1);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    return Future.value(<Map<String, dynamic>>[]);
  }

  @override
  Future<int> update(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    return Future.value(1);
  }

  @override
  Future<int> delete(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    return Future.value(1);
  }

  @override
  Future<void> executeBatch(
    List<BatchOperation> operations,
    String space,
  ) {
    return Future.value();
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function() action,
    String space,
  ) {
    return action();
  }

  @override
  Future<String> encrypt(String data, String algorithm) {
    return Future.value('encrypted_$data');
  }

  @override
  Future<String> decrypt(String encryptedData, String algorithm) {
    return Future.value('decrypted_$encryptedData');
  }

  @override
  Future<void> setEncryptionKey(String key) {
    return Future.value();
  }

  @override
  Future<void> saveSecureKey(String key, String value) {
    return Future.value();
  }

  @override
  Future<String?> getSecureKey(String key) {
    return Future.value('secure_value');
  }

  @override
  Future<void> deleteSecureKey(String key) {
    return Future.value();
  }

  @override
  Future<bool> isBiometricAvailable() {
    return Future.value(true);
  }

  @override
  Future<bool> authenticateWithBiometric(String reason) {
    return Future.value(true);
  }

  @override
  Future<void> exportDatabase(String sourcePath, String destinationPath) {
    return Future.value();
  }

  @override
  Future<void> importDatabase(String sourcePath, String destinationPath) {
    return Future.value();
  }

  @override
  Future<void> vacuum() {
    return Future.value();
  }

  @override
  Future<Map<String, dynamic>> getStorageInfo() {
    return Future.value(<String, dynamic>{
      'recordCount': 0,
      'tableCount': 0,
      'storageSize': 0,
    });
  }
}

void main() {
  group('LocalStorageCachePlatform', () {
    late LocalStorageCachePlatform platform;

    setUp(() {
      platform = MockLocalStorageCachePlatform();
      LocalStorageCachePlatform.instance = platform;
    });

    test('instance should be MockLocalStorageCachePlatform', () {
      expect(
        LocalStorageCachePlatform.instance,
        isA<MockLocalStorageCachePlatform>(),
      );
    });

    group('Database Operations', () {
      test('initialize should complete without error', () async {
        await expectLater(
          platform.initialize('/path/to/db', <String, dynamic>{}),
          completes,
        );
      });

      test('close should complete without error', () async {
        await expectLater(platform.close(), completes);
      });
    });

    group('CRUD Operations', () {
      test('insert should return ID', () async {
        final id = await platform.insert(
          'users',
          <String, dynamic>{'username': 'test'},
          'default',
        );
        expect(id, equals(1));
      });

      test('query should return list of records', () async {
        final results = await platform.query(
          'SELECT * FROM users',
          <dynamic>[],
          'default',
        );
        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results, isEmpty);
      });

      test('update should return affected rows count', () async {
        final count = await platform.update(
          'UPDATE users SET username = ?',
          <dynamic>['new_name'],
          'default',
        );
        expect(count, equals(1));
      });

      test('delete should return deleted rows count', () async {
        final count = await platform.delete(
          'DELETE FROM users WHERE id = ?',
          <dynamic>[1],
          'default',
        );
        expect(count, equals(1));
      });
    });

    group('Batch Operations', () {
      test('executeBatch should complete without error', () async {
        final operations = <BatchOperation>[
          const BatchOperation(
            type: 'insert',
            tableName: 'users',
            data: <String, dynamic>{'username': 'test'},
          ),
        ];

        await expectLater(
          platform.executeBatch(operations, 'default'),
          completes,
        );
      });
    });

    group('Transaction', () {
      test('transaction should execute action', () async {
        final result = await platform.transaction<int>(
          () async => 42,
          'default',
        );
        expect(result, equals(42));
      });
    });

    group('Encryption', () {
      test('encrypt should return encrypted data', () async {
        final encrypted = await platform.encrypt('data', 'aes256');
        expect(encrypted, equals('encrypted_data'));
      });

      test('decrypt should return decrypted data', () async {
        final decrypted = await platform.decrypt('encrypted', 'aes256');
        expect(decrypted, equals('decrypted_encrypted'));
      });

      test('setEncryptionKey should complete without error', () async {
        await expectLater(
          platform.setEncryptionKey('key'),
          completes,
        );
      });
    });

    group('Secure Storage', () {
      test('saveSecureKey should complete without error', () async {
        await expectLater(
          platform.saveSecureKey('key', 'value'),
          completes,
        );
      });

      test('getSecureKey should return value', () async {
        final value = await platform.getSecureKey('key');
        expect(value, equals('secure_value'));
      });

      test('deleteSecureKey should complete without error', () async {
        await expectLater(
          platform.deleteSecureKey('key'),
          completes,
        );
      });
    });

    group('Biometric Authentication', () {
      test('isBiometricAvailable should return bool', () async {
        final available = await platform.isBiometricAvailable();
        expect(available, isTrue);
      });

      test('authenticateWithBiometric should return bool', () async {
        final authenticated = await platform.authenticateWithBiometric(
          'Authenticate to access data',
        );
        expect(authenticated, isTrue);
      });
    });

    group('File Operations', () {
      test('exportDatabase should complete without error', () async {
        await expectLater(
          platform.exportDatabase('/source', '/destination'),
          completes,
        );
      });

      test('importDatabase should complete without error', () async {
        await expectLater(
          platform.importDatabase('/source', '/destination'),
          completes,
        );
      });
    });

    group('Platform Optimizations', () {
      test('vacuum should complete without error', () async {
        await expectLater(platform.vacuum(), completes);
      });

      test('getStorageInfo should return storage information', () async {
        final info = await platform.getStorageInfo();
        expect(info, isA<Map<String, dynamic>>());
        expect(info, containsPair('recordCount', 0));
        expect(info, containsPair('tableCount', 0));
        expect(info, containsPair('storageSize', 0));
      });
    });

    group('Unimplemented Methods', () {
      late UnimplementedPlatform unimplementedPlatform;

      setUp(() {
        unimplementedPlatform = UnimplementedPlatform();
      });

      test('initialize should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.initialize('/path', <String, dynamic>{}),
          throwsUnimplementedError,
        );
      });

      test('close should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.close(),
          throwsUnimplementedError,
        );
      });

      test('insert should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.insert(
            'table',
            <String, dynamic>{},
            'space',
          ),
          throwsUnimplementedError,
        );
      });

      test('query should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.query('sql', <dynamic>[], 'space'),
          throwsUnimplementedError,
        );
      });

      test('update should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.update('sql', <dynamic>[], 'space'),
          throwsUnimplementedError,
        );
      });

      test('delete should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.delete('sql', <dynamic>[], 'space'),
          throwsUnimplementedError,
        );
      });

      test('executeBatch should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.executeBatch(<BatchOperation>[], 'space'),
          throwsUnimplementedError,
        );
      });

      test('transaction should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.transaction<void>(
            () async {},
            'space',
          ),
          throwsUnimplementedError,
        );
      });

      test('encrypt should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.encrypt('data', 'algorithm'),
          throwsUnimplementedError,
        );
      });

      test('decrypt should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.decrypt('data', 'algorithm'),
          throwsUnimplementedError,
        );
      });

      test('setEncryptionKey should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.setEncryptionKey('key'),
          throwsUnimplementedError,
        );
      });

      test('saveSecureKey should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.saveSecureKey('key', 'value'),
          throwsUnimplementedError,
        );
      });

      test('getSecureKey should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.getSecureKey('key'),
          throwsUnimplementedError,
        );
      });

      test('deleteSecureKey should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.deleteSecureKey('key'),
          throwsUnimplementedError,
        );
      });

      test('isBiometricAvailable should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.isBiometricAvailable(),
          throwsUnimplementedError,
        );
      });

      test('authenticateWithBiometric should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.authenticateWithBiometric('reason'),
          throwsUnimplementedError,
        );
      });

      test('exportDatabase should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.exportDatabase('source', 'dest'),
          throwsUnimplementedError,
        );
      });

      test('importDatabase should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.importDatabase('source', 'dest'),
          throwsUnimplementedError,
        );
      });

      test('vacuum should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.vacuum(),
          throwsUnimplementedError,
        );
      });

      test('getStorageInfo should throw UnimplementedError', () {
        expect(
          () => unimplementedPlatform.getStorageInfo(),
          throwsUnimplementedError,
        );
      });
    });
  });
}

class UnimplementedPlatform extends LocalStorageCachePlatform {
  // All methods will throw UnimplementedError by default
}
