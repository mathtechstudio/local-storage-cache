# Security Best Practices

This guide provides security recommendations and best practices for using the Local Storage Cache package.

## Table of Contents

1. [Security Overview](#security-overview)
2. [Encryption](#encryption)
3. [Key Management](#key-management)
4. [Data Protection](#data-protection)
5. [Access Control](#access-control)
6. [Secure Coding Practices](#secure-coding-practices)
7. [Platform-Specific Security](#platform-specific-security)
8. [Compliance](#compliance)
9. [Security Checklist](#security-checklist)

## Security Overview

### Security Layers

The package provides multiple security layers:

1. **Encryption at Rest**: AES-256-GCM or ChaCha20-Poly1305
2. **Secure Key Storage**: Platform-native keychains/keystores
3. **Biometric Authentication**: Face ID, Touch ID, fingerprint
4. **Data Validation**: Input validation and sanitization
5. **Access Control**: Multi-space isolation

### Threat Model

Consider these threats when implementing security:

- Unauthorized physical access to device
- Malware or compromised applications
- Data extraction from backups
- Memory dumps
- Network interception (if syncing)
- Social engineering attacks

## Encryption

### Enable Encryption

Always enable encryption for sensitive data:

```dart
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: EncryptionAlgorithm.aes256GCM,
    ),
  ),
);
```

### Choose Strong Algorithms

Use industry-standard encryption algorithms:

```dart
// Recommended: AES-256-GCM (widely supported, hardware accelerated)
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: EncryptionAlgorithm.aes256GCM,
    ),
  ),
);

// Alternative: ChaCha20-Poly1305 (faster on mobile without AES hardware)
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: EncryptionAlgorithm.chacha20Poly1305,
    ),
  ),
);
```

### Field-Level Encryption

Encrypt only sensitive fields for better performance:

```dart
final schema = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(name: 'id', type: DataType.integer),
    FieldSchema(name: 'username', type: DataType.text), // Not encrypted
    FieldSchema(
      name: 'ssn',
      type: DataType.text,
      encrypted: true, // Encrypted
    ),
    FieldSchema(
      name: 'credit_card',
      type: DataType.text,
      encrypted: true, // Encrypted
    ),
  ],
);
```

### Avoid Weak Encryption

Do not use weak or custom encryption:

```dart
// Bad: No encryption
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(enabled: false),
  ),
);

// Bad: Custom weak encryption
// Never implement your own encryption algorithm
```

## Key Management

### Use Secure Key Storage

Store encryption keys in platform-native secure storage:

```dart
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true, // Keys stored in Keychain/Keystore
    ),
  ),
);
```

### Never Hardcode Keys

Do not hardcode encryption keys in your code:

```dart
// Bad: Hardcoded key
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      customKey: 'my-secret-key-123', // Never do this
    ),
  ),
);

// Good: Generate and store securely
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true,
    ),
  ),
);
```

### Key Rotation

Implement regular key rotation:

```dart
// Rotate encryption key periodically
Future<void> rotateEncryptionKey() async {
  final encryptionManager = storage.encryptionManager;
  await encryptionManager.rotateKey();
}

// Schedule rotation
Timer.periodic(const Duration(days: 90), (_) {
  rotateEncryptionKey();
});
```

### Key Derivation

**WARNING**: Never implement your own key derivation function. Always use established, secure KDF libraries.

For deriving encryption keys from user passwords, you MUST use a proper Key Derivation Function (KDF) such as:

- **PBKDF2** (Password-Based Key Derivation Function 2)
- **Argon2** (recommended for new applications)
- **scrypt**

A single round of hashing (SHA-256, MD5, etc.) is **cryptographically insecure** and vulnerable to brute-force and dictionary attacks.

#### Recommended Approach

Use a reputable cryptography library that implements secure KDFs:

```dart
// Example using the 'cryptography' package
import 'package:cryptography/cryptography.dart';

Future<String> deriveKeyFromPassword(String password, List<int> salt) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000, // Minimum recommended iterations
    bits: 256, // 256-bit key for AES-256
  );

  final secretKey = await pbkdf2.deriveKey(
    secretKey: SecretKey(utf8.encode(password)),
    nonce: salt,
  );

  final keyBytes = await secretKey.extractBytes();
  return base64Url.encode(keyBytes);
}

// Generate a cryptographically secure salt
List<int> generateSalt() {
  final random = Random.secure();
  return List<int>.generate(16, (_) => random.nextInt(256));
}

// Usage
final salt = generateSalt();
final derivedKey = await deriveKeyFromPassword(userPassword, salt);

final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      customKey: derivedKey,
    ),
  ),
);
```

#### Important Notes

- **Iterations**: Use at least 100,000 iterations for PBKDF2 (2023 OWASP recommendation)
- **Salt**: Always use a unique, random salt for each password
- **Salt Storage**: Store the salt alongside the encrypted data (it doesn't need to be secret)
- **Salt Length**: Use at least 16 bytes (128 bits) for the salt
- **Never reuse salts**: Each password derivation should use a unique salt

#### Add Dependency

Add the `cryptography` package to your `pubspec.yaml`:

```yaml
dependencies:
  cryptography: ^2.5.0
```

### Protect Keys in Memory

Minimize key exposure in memory:

```dart
// Clear sensitive data after use
String? encryptionKey;

try {
  encryptionKey = await getEncryptionKey();
  // Use key
} finally {
  encryptionKey = null; // Clear from memory
}
```

## Data Protection

### Validate Input

Always validate data before storage:

```dart
final schema = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(
      name: 'email',
      type: DataType.text,
      nullable: false,
      pattern: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$', // Email validation
    ),
    FieldSchema(
      name: 'age',
      type: DataType.integer,
      minValue: 0,
      maxValue: 150,
    ),
  ],
);
```

### Sanitize Data

Sanitize user input to prevent injection:

```dart
String sanitizeInput(String input) {
  // Remove potentially dangerous characters
  return input.replaceAll(RegExp(r'[^\w\s@.-]'), '');
}

final sanitizedEmail = sanitizeInput(userInput);
await storage.insert('users', {'email': sanitizedEmail});
```

### Use Parameterized Queries

Always use parameterized queries to prevent SQL injection:

```dart
// Good: Parameterized query
final users = await storage.query('users')
  .where('email', '=', userEmail)
  .get();

// Bad: String concatenation
// Never do this:
// final users = await storage.rawQuery("SELECT * FROM users WHERE email = '$userEmail'");
```

### Secure Backups

Encrypt backups:

```dart
await storage.backup(
  BackupConfig(
    path: '/path/to/backup.json',
    encrypt: true, // Always encrypt backups
    compression: CompressionType.gzip,
  ),
);
```

### Data Retention

Implement data retention policies:

```dart
// Delete old data
Future<void> cleanupOldData() async {
  final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
  
  await storage.delete(
    'logs',
    where: 'created_at < ?',
    whereArgs: [cutoffDate.toIso8601String()],
  );
}

// Schedule cleanup
Timer.periodic(const Duration(days: 1), (_) {
  cleanupOldData();
});
```

## Access Control

### Biometric Authentication

Require biometric authentication for sensitive operations:

```dart
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      requireBiometric: true, // Require Face ID/Touch ID
    ),
  ),
);
```

### Multi-Space Isolation

Use spaces to isolate user data:

```dart
// Each user gets their own isolated space
Future<void> loginUser(String userId) async {
  await storage.switchSpace('user_$userId');
  // User can only access their own data
}

Future<void> logoutUser() async {
  await storage.switchSpace('default');
  // Return to default space
}
```

### Permission Checks

Implement permission checks before sensitive operations:

```dart
Future<void> deleteUserData(String userId) async {
  // Check if current user has permission
  if (!await hasPermission(userId)) {
    throw UnauthorizedException('No permission to delete user data');
  }
  
  await storage.delete('users', where: 'id = ?', whereArgs: [userId]);
}
```

### Session Management

Implement secure session management:

```dart
class SessionManager {
  DateTime? _sessionStart;
  static const sessionTimeout = Duration(minutes: 30);
  
  bool isSessionValid() {
    if (_sessionStart == null) return false;
    return DateTime.now().difference(_sessionStart!) < sessionTimeout;
  }
  
  void startSession() {
    _sessionStart = DateTime.now();
  }
  
  void endSession() {
    _sessionStart = null;
  }
}
```

## Secure Coding Practices

### Error Handling

Do not expose sensitive information in errors:

```dart
// Bad: Exposes sensitive data
try {
  await storage.insert('users', userData);
} catch (e) {
  print('Error inserting user: $userData'); // Exposes data
}

// Good: Generic error message
try {
  await storage.insert('users', userData);
} catch (e) {
  print('Error inserting user');
  logger.error('Insert failed', error: e); // Log securely
}
```

### Logging

Do not log sensitive data:

```dart
final storage = StorageEngine(
  config: StorageConfig(
    logging: LogConfig(
      level: LogLevel.info,
      logQueries: false, // Disable in production
      redactSensitiveData: true,
    ),
  ),
);
```

### Memory Management

Clear sensitive data from memory:

```dart
// Use try-finally to ensure cleanup
String? sensitiveData;
try {
  sensitiveData = await fetchSensitiveData();
  processSensitiveData(sensitiveData);
} finally {
  sensitiveData = null; // Clear from memory
}
```

### Secure Random Generation

Use cryptographically secure random generation:

```dart
import 'dart:math';
import 'package:crypto/crypto.dart';

String generateSecureToken() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64.encode(values);
}
```

## Platform-Specific Security

### Android

Use Android Keystore:

```dart
// Automatically handled when useSecureStorage is true
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true, // Uses Android Keystore
    ),
  ),
);
```

Configure ProGuard to protect code:

```proguard
# In android/app/proguard-rules.pro
-keep class com.protheeuz.local_storage_cache.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
```

### iOS

Use Keychain Services:

```dart
// Automatically handled when useSecureStorage is true
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true, // Uses iOS Keychain
    ),
  ),
);
```

Configure data protection:

```xml
<!-- In ios/Runner/Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to protect your sensitive data</string>
```

### Web

Use Web Crypto API:

```dart
if (kIsWeb) {
  final storage = StorageEngine(
    config: StorageConfig(
      encryption: EncryptionConfig(
        enabled: true, // Uses Web Crypto API
      ),
    ),
  );
}
```

Implement Content Security Policy:

```html
<!-- In web/index.html -->
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self' 'unsafe-inline'">
```

### Windows

Use Data Protection API (DPAPI):

```dart
// Automatically handled on Windows
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true, // Uses DPAPI
    ),
  ),
);
```

### Linux

Use libsecret:

```dart
// Automatically handled on Linux
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      useSecureStorage: true, // Uses libsecret
    ),
  ),
);
```

## Compliance

### GDPR Compliance

Implement data subject rights:

```dart
// Right to erasure
Future<void> deleteUserData(String userId) async {
  await storage.switchSpace('user_$userId');
  await storage.deleteSpace('user_$userId');
}

// Right to data portability
Future<Map<String, dynamic>> exportUserData(String userId) async {
  await storage.switchSpace('user_$userId');
  
  final userData = <String, dynamic>{};
  final tables = ['users', 'orders', 'preferences'];
  
  for (final table in tables) {
    userData[table] = await storage.query(table).get();
  }
  
  return userData;
}
```

### HIPAA Compliance

For healthcare applications:

```dart
final storage = StorageEngine(
  config: StorageConfig(
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: EncryptionAlgorithm.aes256GCM,
      useSecureStorage: true,
    ),
    logging: LogConfig(
      level: LogLevel.info,
      logQueries: false, // Do not log PHI
      auditTrail: true, // Enable audit trail
    ),
  ),
);
```

### PCI DSS Compliance

For payment card data:

```dart
final schema = TableSchema(
  name: 'payments',
  fields: [
    FieldSchema(
      name: 'card_number',
      type: DataType.text,
      encrypted: true, // Must be encrypted
      masked: true, // Mask in logs
    ),
    FieldSchema(
      name: 'cvv',
      type: DataType.text,
      encrypted: true,
      noStorage: true, // Do not store CVV
    ),
  ],
);
```

## Security Checklist

- [ ] Encryption enabled for sensitive data
- [ ] Strong encryption algorithm selected (AES-256-GCM or ChaCha20-Poly1305)
- [ ] Encryption keys stored in platform-native secure storage
- [ ] No hardcoded encryption keys in code
- [ ] Biometric authentication enabled for sensitive operations
- [ ] Input validation implemented
- [ ] Parameterized queries used (no SQL injection)
- [ ] Backups encrypted
- [ ] Sensitive data not logged
- [ ] Error messages do not expose sensitive information
- [ ] Data retention policies implemented
- [ ] Multi-space isolation used for user data
- [ ] Session management implemented
- [ ] Regular security audits scheduled
- [ ] Compliance requirements met (GDPR, HIPAA, PCI DSS)
- [ ] Platform-specific security features enabled
- [ ] Code obfuscation enabled for production
- [ ] Secure random generation used
- [ ] Memory cleared after handling sensitive data
- [ ] Regular key rotation implemented

## Security Audit

Perform regular security audits:

```dart
Future<SecurityAuditReport> performSecurityAudit() async {
  final report = SecurityAuditReport();
  
  // Check encryption status
  report.encryptionEnabled = storage.config.encryption.enabled;
  
  // Check key storage
  report.secureKeyStorage = storage.config.encryption.useSecureStorage;
  
  // Check for hardcoded keys
  report.hasHardcodedKeys = storage.config.encryption.customKey != null;
  
  // Check logging configuration
  report.logsQueries = storage.config.logging.logQueries;
  
  // Check data retention
  report.hasRetentionPolicy = await checkRetentionPolicy();
  
  return report;
}
```

## Security Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [NIST Cryptographic Standards](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
