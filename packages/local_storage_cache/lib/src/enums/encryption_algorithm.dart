/// Supported encryption algorithms.
enum EncryptionAlgorithm {
  /// AES-256-GCM (Galois/Counter Mode) - Recommended
  ///
  /// Provides authenticated encryption with associated data (AEAD).
  /// Fast and secure, widely supported.
  aes256GCM,

  /// ChaCha20-Poly1305
  ///
  /// Modern AEAD cipher, excellent for mobile devices.
  /// Better performance than AES on devices without hardware acceleration.
  chacha20Poly1305,

  /// AES-256-CBC (Cipher Block Chaining)
  ///
  /// Legacy mode, provided for compatibility.
  /// Consider using AES-256-GCM instead.
  aes256CBC,
}

/// Extension methods for [EncryptionAlgorithm].
extension EncryptionAlgorithmExtension on EncryptionAlgorithm {
  /// Returns the algorithm name as a string.
  String get name {
    switch (this) {
      case EncryptionAlgorithm.aes256GCM:
        return 'AES-256-GCM';
      case EncryptionAlgorithm.chacha20Poly1305:
        return 'ChaCha20-Poly1305';
      case EncryptionAlgorithm.aes256CBC:
        return 'AES-256-CBC';
    }
  }

  /// Returns whether this algorithm provides authenticated encryption.
  bool get isAuthenticated {
    return this == EncryptionAlgorithm.aes256GCM ||
        this == EncryptionAlgorithm.chacha20Poly1305;
  }
}
