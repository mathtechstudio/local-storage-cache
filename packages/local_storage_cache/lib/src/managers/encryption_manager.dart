import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:local_storage_cache/src/config/encryption_config.dart';
import 'package:local_storage_cache/src/enums/encryption_algorithm.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Manages encryption and decryption operations.
///
/// Provides field-level and full-data encryption using various algorithms.
/// Integrates with platform secure storage for key management.
class EncryptionManager {
  /// Creates an encryption manager with the given configuration.
  EncryptionManager(this.config);

  /// Encryption configuration.
  final EncryptionConfig config;

  /// Platform interface for secure storage.
  late final LocalStorageCachePlatform? _platform;

  /// Current encryption key.
  String? _encryptionKey;

  /// Whether the manager is initialized.
  bool _initialized = false;

  /// Initializes the encryption manager.
  Future<void> initialize(LocalStorageCachePlatform platform) async {
    if (_initialized) return;

    _platform = platform;

    if (!config.enabled) {
      _initialized = true;
      return;
    }

    // Load or generate encryption key
    await _loadOrGenerateKey();

    _initialized = true;
  }

  /// Loads existing key or generates a new one.
  Future<void> _loadOrGenerateKey() async {
    // Use custom key if provided
    if (config.customKey != null) {
      _encryptionKey = config.customKey;
      return;
    }

    // Try to load from secure storage
    if (config.useSecureStorage) {
      _encryptionKey = await _platform!.getSecureKey('encryption_key');
    }

    // Generate new key if none exists
    if (_encryptionKey == null) {
      _encryptionKey = _generateKey();

      // Save to secure storage
      if (config.useSecureStorage) {
        await _platform!.saveSecureKey('encryption_key', _encryptionKey!);
      }
    }

    // Set the key in platform
    await _platform!.setEncryptionKey(_encryptionKey!);
  }

  /// Generates a random encryption key.
  String _generateKey() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = timestamp.toString();
    final hash = sha256.convert(utf8.encode(random));
    return base64Url.encode(hash.bytes);
  }

  /// Encrypts plain text.
  ///
  /// Returns the encrypted text as a base64-encoded string.
  Future<String> encrypt(
    String plainText, {
    EncryptionAlgorithm? algorithm,
  }) async {
    _ensureInitialized();

    if (!config.enabled) {
      return plainText;
    }

    final algo = algorithm ?? config.algorithm;

    switch (algo) {
      case EncryptionAlgorithm.aes256GCM:
        return _encryptAES256GCM(plainText);
      case EncryptionAlgorithm.chacha20Poly1305:
        return _encryptChaCha20(plainText);
      case EncryptionAlgorithm.aes256CBC:
        return _encryptAES256CBC(plainText);
    }
  }

  /// Decrypts cipher text.
  ///
  /// Returns the decrypted plain text.
  Future<String> decrypt(
    String cipherText, {
    EncryptionAlgorithm? algorithm,
  }) async {
    _ensureInitialized();

    if (!config.enabled) {
      return cipherText;
    }

    final algo = algorithm ?? config.algorithm;

    switch (algo) {
      case EncryptionAlgorithm.aes256GCM:
        return _decryptAES256GCM(cipherText);
      case EncryptionAlgorithm.chacha20Poly1305:
        return _decryptChaCha20(cipherText);
      case EncryptionAlgorithm.aes256CBC:
        return _decryptAES256CBC(cipherText);
    }
  }

  /// Encrypts bytes.
  Future<Uint8List> encryptBytes(
    Uint8List data, {
    EncryptionAlgorithm? algorithm,
  }) async {
    final plainText = base64.encode(data);
    final encrypted = await encrypt(plainText, algorithm: algorithm);
    return Uint8List.fromList(utf8.encode(encrypted));
  }

  /// Decrypts bytes.
  Future<Uint8List> decryptBytes(
    Uint8List data, {
    EncryptionAlgorithm? algorithm,
  }) async {
    final cipherText = utf8.decode(data);
    final decrypted = await decrypt(cipherText, algorithm: algorithm);
    return base64.decode(decrypted);
  }

  /// Encrypts specific fields in a data map.
  Future<Map<String, dynamic>> encryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToEncrypt,
  ) async {
    _ensureInitialized();

    if (!config.enabled || fieldsToEncrypt.isEmpty) {
      return data;
    }

    final result = Map<String, dynamic>.from(data);

    for (final field in fieldsToEncrypt) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field].toString();
        result[field] = await encrypt(value);
      }
    }

    return result;
  }

  /// Decrypts specific fields in a data map.
  Future<Map<String, dynamic>> decryptFields(
    Map<String, dynamic> data,
    List<String> fieldsToDecrypt,
  ) async {
    _ensureInitialized();

    if (!config.enabled || fieldsToDecrypt.isEmpty) {
      return data;
    }

    final result = Map<String, dynamic>.from(data);

    for (final field in fieldsToDecrypt) {
      if (result.containsKey(field) && result[field] != null) {
        final value = result[field].toString();
        result[field] = await decrypt(value);
      }
    }

    return result;
  }

  /// Sets a new encryption key.
  Future<void> setEncryptionKey(String key) async {
    _ensureInitialized();

    _encryptionKey = key;

    // Save to secure storage
    if (config.useSecureStorage) {
      await _platform!.saveSecureKey('encryption_key', key);
    }

    // Update platform
    await _platform!.setEncryptionKey(key);
  }

  /// Rotates the encryption key.
  ///
  /// This generates a new key and updates the platform.
  /// Note: Existing encrypted data will need to be re-encrypted with the new key.
  Future<String> rotateKey() async {
    _ensureInitialized();

    final newKey = _generateKey();
    await setEncryptionKey(newKey);

    return newKey;
  }

  /// Saves a key securely using platform secure storage.
  Future<void> saveKeySecurely(String keyId, String key) async {
    _ensureInitialized();
    await _platform!.saveSecureKey(keyId, key);
  }

  /// Gets a key from platform secure storage.
  Future<String?> getKeySecurely(String keyId) async {
    _ensureInitialized();
    return _platform!.getSecureKey(keyId);
  }

  // AES-256-GCM encryption implementation
  Future<String> _encryptAES256GCM(String plainText) async {
    // Use platform encryption
    return _platform!.encrypt(plainText, 'AES-256-GCM');
  }

  Future<String> _decryptAES256GCM(String cipherText) async {
    // Use platform decryption
    return _platform!.decrypt(cipherText, 'AES-256-GCM');
  }

  // ChaCha20-Poly1305 encryption implementation
  Future<String> _encryptChaCha20(String plainText) async {
    // Use platform encryption
    return _platform!.encrypt(plainText, 'ChaCha20-Poly1305');
  }

  Future<String> _decryptChaCha20(String cipherText) async {
    // Use platform decryption
    return _platform!.decrypt(cipherText, 'ChaCha20-Poly1305');
  }

  // AES-256-CBC encryption implementation
  Future<String> _encryptAES256CBC(String plainText) async {
    // Use platform encryption
    return _platform!.encrypt(plainText, 'AES-256-CBC');
  }

  Future<String> _decryptAES256CBC(String cipherText) async {
    // Use platform decryption
    return _platform!.decrypt(cipherText, 'AES-256-CBC');
  }

  /// Ensures the manager is initialized.
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('EncryptionManager not initialized');
    }
  }
}
