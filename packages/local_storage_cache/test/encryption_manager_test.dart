import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/config/encryption_config.dart';
import 'package:local_storage_cache/src/enums/encryption_algorithm.dart';
import 'package:local_storage_cache/src/managers/encryption_manager.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

import 'mocks/mock_platform_channels.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    setupMockPlatformChannels();
    resetMockData();
  });

  group('EncryptionManager - Initialization', () {
    test('should initialize with encryption disabled', () async {
      const config = EncryptionConfig();
      final manager = EncryptionManager(config);
      final platform = LocalStorageCachePlatform.instance;

      await manager.initialize(platform);

      // Should not throw
      expect(manager.config.enabled, isFalse);
    });

    test('should initialize with custom key', () async {
      // ggignore: test-key-not-real
      const config = EncryptionConfig(
        enabled: true,
        customKey: 'test-key-for-unit-tests-only-12345',
      );
      final manager = EncryptionManager(config);
      final platform = LocalStorageCachePlatform.instance;

      await manager.initialize(platform);

      // Should use custom key
      expect(manager.config.customKey,
          equals('test-key-for-unit-tests-only-12345'));
    });

    test('should generate and save key to secure storage', () async {
      const config = EncryptionConfig(
        enabled: true,
      );
      final manager = EncryptionManager(config);
      final platform = LocalStorageCachePlatform.instance;

      await manager.initialize(platform);

      // Key should be saved to secure storage
      final savedKey = await platform.getSecureKey('encryption_key');
      expect(savedKey, isNotNull);
      expect(savedKey, isA<String>());
    });

    test('should load existing key from secure storage', () async {
      final platform = LocalStorageCachePlatform.instance;

      // ggignore: test-key-not-real
      // Save a key first
      await platform.saveSecureKey(
          'encryption_key', 'mock-existing-key-for-testing-123');

      const config = EncryptionConfig(
        enabled: true,
      );
      final manager = EncryptionManager(config);

      await manager.initialize(platform);

      // Should load the existing key
      final loadedKey = await platform.getSecureKey('encryption_key');
      expect(loadedKey, equals('mock-existing-key-for-testing-123'));
    });

    test('should throw StateError when not initialized', () async {
      const config = EncryptionConfig(enabled: true);
      final manager = EncryptionManager(config);

      // Should throw when trying to encrypt without initialization
      expect(
        () => manager.encrypt('test'),
        throwsStateError,
      );
    });
  });

  group('EncryptionManager - Encryption/Decryption', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig(
        enabled: true,
      );
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should encrypt and decrypt text with AES-256-GCM', () async {
      const plainText = 'Hello, World!';

      final encrypted = await manager.encrypt(plainText);
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains('AES-256-GCM'));

      final decrypted = await manager.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should encrypt and decrypt with ChaCha20-Poly1305', () async {
      const plainText = 'Sensitive data';

      final encrypted = await manager.encrypt(
        plainText,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
      );
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains('ChaCha20-Poly1305'));

      final decrypted = await manager.decrypt(
        encrypted,
        algorithm: EncryptionAlgorithm.chacha20Poly1305,
      );
      expect(decrypted, equals(plainText));
    });

    test('should encrypt and decrypt with AES-256-CBC', () async {
      const plainText = 'Legacy encryption';

      final encrypted = await manager.encrypt(
        plainText,
        algorithm: EncryptionAlgorithm.aes256CBC,
      );
      expect(encrypted, isNot(equals(plainText)));
      expect(encrypted, contains('AES-256-CBC'));

      final decrypted = await manager.decrypt(
        encrypted,
        algorithm: EncryptionAlgorithm.aes256CBC,
      );
      expect(decrypted, equals(plainText));
    });

    test('should handle empty string encryption', () async {
      const plainText = '';

      final encrypted = await manager.encrypt(plainText);
      final decrypted = await manager.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle special characters', () async {
      const plainText = r'!@#$%^&*()_+-=[]{}|;:,.<>?/~`';

      final encrypted = await manager.encrypt(plainText);
      final decrypted = await manager.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle unicode characters', () async {
      const plainText = 'Hello 世界 🌍 مرحبا';

      final encrypted = await manager.encrypt(plainText);
      final decrypted = await manager.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });

    test('should handle long text', () async {
      final plainText = 'A' * 10000;

      final encrypted = await manager.encrypt(plainText);
      final decrypted = await manager.decrypt(encrypted);

      expect(decrypted, equals(plainText));
    });
  });

  group('EncryptionManager - Byte Encryption', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig(enabled: true);
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should encrypt and decrypt bytes', () async {
      final data = List<int>.generate(256, (i) => i);
      final bytes = Uint8List.fromList(data);

      final encrypted = await manager.encryptBytes(bytes);
      expect(encrypted, isNot(equals(bytes)));

      final decrypted = await manager.decryptBytes(encrypted);
      expect(decrypted, equals(bytes));
    });

    test('should handle empty byte array', () async {
      final bytes = Uint8List(0);

      final encrypted = await manager.encryptBytes(bytes);
      final decrypted = await manager.decryptBytes(encrypted);

      expect(decrypted, equals(bytes));
    });
  });

  group('EncryptionManager - Field Encryption', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig(enabled: true);
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should encrypt specific fields in data map', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'email': 'john@example.com',
        'password': 'test-password-not-real-123',
        'age': 30,
      };

      final encrypted = await manager.encryptFields(
        data,
        ['password', 'email'],
      );

      expect(encrypted['username'], equals('john_doe'));
      expect(encrypted['age'], equals(30));
      expect(
          encrypted['password'], isNot(equals('test-password-not-real-123')));
      expect(encrypted['email'], isNot(equals('john@example.com')));
    });

    test('should decrypt specific fields in data map', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'email': 'john@example.com',
        'password': 'test-password-not-real-123',
      };

      final encrypted = await manager.encryptFields(
        data,
        ['password', 'email'],
      );

      final decrypted = await manager.decryptFields(
        encrypted,
        ['password', 'email'],
      );

      expect(decrypted['username'], equals('john_doe'));
      expect(decrypted['password'], equals('test-password-not-real-123'));
      expect(decrypted['email'], equals('john@example.com'));
    });

    test('should handle null values in fields', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'email': null,
        'password': 'test-password-not-real-123',
      };

      final encrypted = await manager.encryptFields(
        data,
        ['password', 'email'],
      );

      expect(encrypted['email'], isNull);
      expect(
          encrypted['password'], isNot(equals('test-password-not-real-123')));
    });

    test('should handle missing fields', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'password': 'test-password-not-real-123',
      };

      final encrypted = await manager.encryptFields(
        data,
        ['password', 'email', 'phone'],
      );

      expect(encrypted['username'], equals('john_doe'));
      expect(
          encrypted['password'], isNot(equals('test-password-not-real-123')));
      expect(encrypted.containsKey('email'), isFalse);
      expect(encrypted.containsKey('phone'), isFalse);
    });

    test('should handle empty fields list', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'password': 'test-password-not-real-123',
      };

      final encrypted = await manager.encryptFields(data, []);

      expect(encrypted, equals(data));
    });

    test('should handle non-string field values', () async {
      final data = {
        'username': 'john_doe',
        'age': 30,
        'active': true,
        'score': 95.5,
      };

      final encrypted = await manager.encryptFields(
        data,
        ['age', 'active', 'score'],
      );

      expect(encrypted['username'], equals('john_doe'));
      expect(encrypted['age'], isNot(equals(30)));
      expect(encrypted['active'], isNot(equals(true)));
      expect(encrypted['score'], isNot(equals(95.5)));

      final decrypted = await manager.decryptFields(
        encrypted,
        ['age', 'active', 'score'],
      );

      expect(decrypted['age'], equals('30'));
      expect(decrypted['active'], equals('true'));
      expect(decrypted['score'], equals('95.5'));
    });
  });

  group('EncryptionManager - Key Management', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig(
        enabled: true,
      );
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should set new encryption key', () async {
      // ggignore: test-key-not-real
      const newKey = 'test-new-encryption-key-for-testing-456';

      await manager.setEncryptionKey(newKey);

      final savedKey = await platform.getSecureKey('encryption_key');
      expect(savedKey, equals(newKey));
    });

    test('should rotate encryption key', () async {
      final oldKey = await platform.getSecureKey('encryption_key');

      final newKey = await manager.rotateKey();

      expect(newKey, isNotNull);
      expect(newKey, isNot(equals(oldKey)));

      final savedKey = await platform.getSecureKey('encryption_key');
      expect(savedKey, equals(newKey));
    });

    test('should save custom key securely', () async {
      // ggignore: test-key-not-real
      const keyId = 'custom_key_1';
      const keyValue = 'test-custom-key-value-for-unit-tests';

      await manager.saveKeySecurely(keyId, keyValue);

      final retrieved = await manager.getKeySecurely(keyId);
      expect(retrieved, equals(keyValue));
    });

    test('should retrieve null for non-existent key', () async {
      final retrieved = await manager.getKeySecurely('non_existent_key');
      expect(retrieved, isNull);
    });

    test('should handle multiple custom keys', () async {
      await manager.saveKeySecurely('key1', 'value1');
      await manager.saveKeySecurely('key2', 'value2');
      await manager.saveKeySecurely('key3', 'value3');

      expect(await manager.getKeySecurely('key1'), equals('value1'));
      expect(await manager.getKeySecurely('key2'), equals('value2'));
      expect(await manager.getKeySecurely('key3'), equals('value3'));
    });
  });

  group('EncryptionManager - Disabled Encryption', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig();
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should return plain text when encryption is disabled', () async {
      // ggignore: test-data-not-sensitive
      const plainText = 'Hello, World!';

      final encrypted = await manager.encrypt(plainText);
      expect(encrypted, equals(plainText));

      final decrypted = await manager.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should not encrypt fields when disabled', () async {
      // ggignore: test-password-not-real
      final data = {
        'username': 'john_doe',
        'password': 'test-password-not-real-123',
      };

      final encrypted = await manager.encryptFields(data, ['password']);
      expect(encrypted, equals(data));
    });
  });

  group('EncryptionManager - Algorithm Extension', () {
    test('should return correct algorithm names', () {
      expect(
        EncryptionAlgorithm.aes256GCM.name,
        equals('AES-256-GCM'),
      );
      expect(
        EncryptionAlgorithm.chacha20Poly1305.name,
        equals('ChaCha20-Poly1305'),
      );
      expect(
        EncryptionAlgorithm.aes256CBC.name,
        equals('AES-256-CBC'),
      );
    });

    test('should identify authenticated encryption algorithms', () {
      expect(EncryptionAlgorithm.aes256GCM.isAuthenticated, isTrue);
      expect(EncryptionAlgorithm.chacha20Poly1305.isAuthenticated, isTrue);
      expect(EncryptionAlgorithm.aes256CBC.isAuthenticated, isFalse);
    });
  });

  group('EncryptionManager - Edge Cases', () {
    late EncryptionManager manager;
    late LocalStorageCachePlatform platform;

    setUp(() async {
      platform = LocalStorageCachePlatform.instance;
      const config = EncryptionConfig(enabled: true);
      manager = EncryptionManager(config);
      await manager.initialize(platform);
    });

    test('should handle multiple initializations', () async {
      await manager.initialize(platform);
      await manager.initialize(platform);
      await manager.initialize(platform);

      // Should not throw and should work normally
      const plainText = 'test';
      final encrypted = await manager.encrypt(plainText);
      final decrypted = await manager.decrypt(encrypted);
      expect(decrypted, equals(plainText));
    });

    test('should handle rapid encrypt/decrypt operations', () async {
      final futures = <Future<String>>[];

      for (var i = 0; i < 100; i++) {
        futures.add(manager.encrypt('test$i'));
      }

      final encrypted = await Future.wait(futures);
      expect(encrypted.length, equals(100));

      final decryptFutures = encrypted.map((e) => manager.decrypt(e));
      final decrypted = await Future.wait(decryptFutures);

      for (var i = 0; i < 100; i++) {
        expect(decrypted[i], equals('test$i'));
      }
    });
  });
}
