import 'package:local_storage_cache/src/enums/encryption_algorithm.dart';

/// Configuration for encryption features.
class EncryptionConfig {
  /// Creates an encryption configuration.
  const EncryptionConfig({
    this.enabled = false,
    this.algorithm = EncryptionAlgorithm.aes256GCM,
    this.customKey,
    this.useSecureStorage = true,
    this.encryptedFields = const [],
    this.requireBiometric = false,
  });

  /// Creates a default encryption configuration (disabled).
  factory EncryptionConfig.disabled() {
    return const EncryptionConfig();
  }

  /// Creates a secure encryption configuration with recommended settings.
  factory EncryptionConfig.secure({
    String? customKey,
    bool requireBiometric = false,
  }) {
    return EncryptionConfig(
      enabled: true,
      customKey: customKey,
      requireBiometric: requireBiometric,
    );
  }

  /// Creates a configuration from a map.
  factory EncryptionConfig.fromMap(Map<String, dynamic> map) {
    return EncryptionConfig(
      enabled: map['enabled'] as bool? ?? false,
      algorithm: _parseAlgorithm(map['algorithm'] as String?),
      customKey: map['customKey'] as String?,
      useSecureStorage: map['useSecureStorage'] as bool? ?? true,
      encryptedFields: (map['encryptedFields'] as List?)?.cast<String>() ?? [],
      requireBiometric: map['requireBiometric'] as bool? ?? false,
    );
  }

  /// Whether encryption is enabled.
  final bool enabled;

  /// The encryption algorithm to use.
  final EncryptionAlgorithm algorithm;

  /// Custom encryption key. If null, a key will be generated.
  final String? customKey;

  /// Whether to use platform-specific secure storage for keys.
  final bool useSecureStorage;

  /// List of field names that should be encrypted.
  /// If empty, no field-level encryption is applied.
  final List<String> encryptedFields;

  /// Whether to require biometric authentication for decryption.
  final bool requireBiometric;

  /// Converts this configuration to a map.
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'algorithm': algorithm.name,
      'customKey': customKey,
      'useSecureStorage': useSecureStorage,
      'encryptedFields': encryptedFields,
      'requireBiometric': requireBiometric,
    };
  }

  static EncryptionAlgorithm _parseAlgorithm(String? value) {
    switch (value) {
      case 'ChaCha20-Poly1305':
        return EncryptionAlgorithm.chacha20Poly1305;
      case 'AES-256-CBC':
        return EncryptionAlgorithm.aes256CBC;
      default:
        return EncryptionAlgorithm.aes256GCM;
    }
  }

  /// Creates a copy of this configuration with the given fields replaced.
  EncryptionConfig copyWith({
    bool? enabled,
    EncryptionAlgorithm? algorithm,
    String? customKey,
    bool? useSecureStorage,
    List<String>? encryptedFields,
    bool? requireBiometric,
  }) {
    return EncryptionConfig(
      enabled: enabled ?? this.enabled,
      algorithm: algorithm ?? this.algorithm,
      customKey: customKey ?? this.customKey,
      useSecureStorage: useSecureStorage ?? this.useSecureStorage,
      encryptedFields: encryptedFields ?? this.encryptedFields,
      requireBiometric: requireBiometric ?? this.requireBiometric,
    );
  }
}
