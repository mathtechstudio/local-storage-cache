# local_storage_cache

[![Pub Version](https://img.shields.io/pub/v/local_storage_cache.svg)](https://pub.dev/packages/local_storage_cache)
[![Build Status](https://github.com/protheeuz/local-storage-cache/actions/workflows/code-integration.yml/badge.svg)](https://github.com/protheeuz/local-storage-cache/actions/workflows/code-integration.yml)
[![Code Coverage](https://codecov.io/gh/protheeuz/local-storage-cache/graph/badge.svg)](https://codecov.io/gh/protheeuz/local-storage-cache)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A comprehensive Flutter package for local storage and caching with advanced features including encryption, multi-space architecture, automatic schema migration, and high-performance query capabilities. Supports Android, iOS, macOS, Windows, Linux, and Web.

## Features

- **Multi-Platform Support**: Works seamlessly across Android, iOS, macOS, Windows, Linux, and Web
- **Advanced Query System**: SQL-like queries with chaining, nesting, joins, and complex conditions
- **Multi-Space Architecture**: Isolate data for different users or contexts within a single database
- **Strong Encryption**: AES-256-GCM and ChaCha20-Poly1305 with platform-native secure key storage
- **Automatic Schema Migration**: Zero-downtime migrations with intelligent field rename detection
- **High Performance**: Multi-level caching, batch operations, connection pooling, and prepared statements
- **Backup and Restore**: Full and selective backups with compression and encryption support
- **Data Validation**: Field-level validation with custom validators and constraints
- **Monitoring**: Built-in metrics, event streams, and performance tracking
- **Error Recovery**: Automatic retry with exponential backoff and corruption recovery

## Installation

Add the dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## Platform Requirements

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| Android  | API 21 (5.0+)  | Requires SQLite 3.8.0+ |
| iOS      | 12.0+          | Uses SQLite.swift |
| macOS    | 10.14+         | Uses SQLite.swift |
| Windows  | 10+            | Requires Visual C++ Runtime |
| Linux    | Ubuntu 18.04+  | Requires libsqlite3 |
| Web      | Modern browsers | Uses IndexedDB |

## Usage

### Import the Package

```dart
import 'package:local_storage_cache/local_storage_cache.dart';
```

### Define Your Schema

```dart
final userSchema = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(
      name: 'id',
      type: DataType.integer,
      nullable: false,
    ),
    FieldSchema(
      name: 'username',
      type: DataType.text,
      nullable: false,
      unique: true,
    ),
    FieldSchema(
      name: 'email',
      type: DataType.text,
      nullable: false,
    ),
    FieldSchema(
      name: 'created_at',
      type: DataType.datetime,
      nullable: false,
    ),
  ],
  primaryKey: PrimaryKeyConfig(
    fields: ['id'],
    autoIncrement: true,
  ),
  indexes: [
    IndexSchema(
      name: 'idx_username',
      fields: ['username'],
    ),
  ],
);
```

### Initialize Storage

```dart
// Basic initialization
final storage = StorageEngine(
  config: StorageConfig(
    databaseName: 'my_app.db',
  ),
  schemas: [userSchema],
);

await storage.initialize();

// With encryption enabled
final storage = StorageEngine(
  config: StorageConfig(
    databaseName: 'my_app.db',
    encryption: EncryptionConfig(
      enabled: true,
      algorithm: EncryptionAlgorithm.aes256GCM,
      useSecureStorage: true,
    ),
  ),
  schemas: [userSchema],
);

await storage.initialize();
```

### Basic Operations

#### Insert Data

```dart
final userId = await storage.insert('users', {
  'username': 'john_doe',
  'email': 'john@example.com',
  'created_at': DateTime.now().toIso8601String(),
});
```

#### Query Data

```dart
// Simple query
final users = await storage.query('users')
  .where('username', '=', 'john_doe')
  .get();

// Complex query with multiple conditions
final activeUsers = await storage.query('users')
  .where('status', '=', 'active')
  .where('created_at', '>', DateTime.now().subtract(Duration(days: 30)))
  .orderBy('username', ascending: true)
  .limit(10)
  .get();

// Query with joins
final postsWithAuthors = await storage.query('posts')
  .join('users', 'posts.user_id', '=', 'users.id')
  .select(['posts.*', 'users.username'])
  .get();
```

#### Update Data

```dart
await storage.update(
  'users',
  {'email': 'newemail@example.com'},
  where: 'id = ?',
  whereArgs: [userId],
);
```

#### Delete Data

```dart
await storage.delete(
  'users',
  where: 'id = ?',
  whereArgs: [userId],
);
```

### Advanced Features

#### Multi-Space Architecture

Isolate data for different users or contexts:

```dart
// Create a space for a specific user
await storage.createSpace('user_123');

// Switch to that space
await storage.switchSpace('user_123');

// All operations now work within this space
await storage.insert('notes', {
  'title': 'My Note',
  'content': 'Note content',
});

// Switch back to global space
await storage.switchSpace(null);
```

#### Batch Operations

```dart
final users = [
  {'username': 'user1', 'email': 'user1@example.com'},
  {'username': 'user2', 'email': 'user2@example.com'},
  {'username': 'user3', 'email': 'user3@example.com'},
];

await storage.batchInsert('users', users);
```

#### Transactions

```dart
await storage.transaction((txn) async {
  final userId = await txn.insert('users', {
    'username': 'john_doe',
    'email': 'john@example.com',
  });
  
  await txn.insert('profiles', {
    'user_id': userId,
    'bio': 'Software developer',
  });
});
```

#### Caching

```dart
// Enable query caching
final users = await storage.query('users')
  .where('status', '=', 'active')
  .useQueryCache(Duration(minutes: 5))
  .get();

// Warm cache for frequently accessed data
await storage.warmCache('users', [
  {'username': 'john_doe'},
  {'username': 'jane_doe'},
]);

// Clear cache
await storage.clearCache();
```

#### Backup and Restore

```dart
// Create a backup
await storage.backup(BackupConfig(
  path: '/path/to/backup.db',
  compress: true,
  encrypt: true,
));

// Restore from backup
await storage.restore(RestoreConfig(
  path: '/path/to/backup.db',
  decrypt: true,
));
```

#### Data Validation

```dart
final schema = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(
      name: 'email',
      type: DataType.text,
      nullable: false,
      validators: [
        (value) {
          if (!value.contains('@')) {
            return 'Invalid email format';
          }
          return null;
        },
      ],
    ),
    FieldSchema(
      name: 'age',
      type: DataType.integer,
      nullable: false,
      validators: [
        (value) {
          if (value < 18) {
            return 'Must be 18 or older';
          }
          return null;
        },
      ],
    ),
  ],
);
```

#### Event Monitoring

```dart
// Listen to storage events
storage.eventStream.listen((event) {
  print('Event: ${event.type} on ${event.tableName}');
});

// Get performance metrics
final metrics = await storage.getMetrics();
print('Total queries: ${metrics.totalQueries}');
print('Average query time: ${metrics.averageQueryTime}ms');
```

## Configuration

### Storage Configuration

```dart
final config = StorageConfig(
  databaseName: 'my_app.db',
  databasePath: '/custom/path',
  version: 1,
  encryption: EncryptionConfig(
    enabled: true,
    algorithm: EncryptionAlgorithm.aes256GCM,
    useSecureStorage: true,
  ),
  cache: CacheConfig(
    enabled: true,
    maxMemorySize: 10 * 1024 * 1024, // 10 MB
    maxDiskSize: 50 * 1024 * 1024,   // 50 MB
    defaultTTL: Duration(hours: 1),
  ),
  performance: PerformanceConfig(
    enableConnectionPool: true,
    maxConnections: 5,
    enablePreparedStatements: true,
    enableQueryOptimization: true,
  ),
  logging: LogConfig(
    enabled: true,
    level: LogLevel.info,
    logToFile: false,
  ),
);
```

### Encryption Configuration

```dart
// AES-256-GCM (recommended)
final encryptionConfig = EncryptionConfig(
  enabled: true,
  algorithm: EncryptionAlgorithm.aes256GCM,
  useSecureStorage: true,
);

// ChaCha20-Poly1305
final encryptionConfig = EncryptionConfig(
  enabled: true,
  algorithm: EncryptionAlgorithm.chacha20Poly1305,
  useSecureStorage: true,
);

// Custom key (not recommended for production)
final encryptionConfig = EncryptionConfig(
  enabled: true,
  algorithm: EncryptionAlgorithm.aes256GCM,
  customKey: 'your-custom-key',
);
```

### Cache Configuration

```dart
final cacheConfig = CacheConfig(
  enabled: true,
  maxMemorySize: 10 * 1024 * 1024,  // 10 MB
  maxDiskSize: 50 * 1024 * 1024,    // 50 MB
  defaultTTL: Duration(hours: 1),
  evictionPolicy: EvictionPolicy.lru,
  enableQueryCache: true,
  queryCacheTTL: Duration(minutes: 5),
);
```

## Platform-Specific Configuration

### Android

No additional configuration required. The package uses SQLite through the Android NDK.

#### Disabling Auto Backup

To prevent issues with encryption keys, disable Android auto backup by adding the following to your `android/app/src/main/AndroidManifest.xml`:

```xml
<application
  android:allowBackup="false"
  ...>
</application>
```

### iOS and macOS

Add Keychain Sharing capability to your runner. Add the following to both `ios/Runner/DebugProfile.entitlements` and `ios/Runner/Release.entitlements` for iOS, or `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements` for macOS:

```xml
<key>keychain-access-groups</key>
<array/>
```

If using App Groups, add the App Group name:

```xml
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)your-app-group</string>
</array>
```

### Windows

Requires Visual C++ Runtime. The package uses SQLite through the Windows SDK.

### Linux

Requires `libsqlite3-0` to run the application. Install it using:

```bash
sudo apt-get install libsqlite3-0
```

For development, you also need `libsqlite3-dev`:

```bash
sudo apt-get install libsqlite3-dev
```

### Web

The package uses IndexedDB for storage on web platforms. Encryption is supported through WebCrypto API.

**Important**: The package only works on HTTPS or localhost environments for security reasons.

## Schema Migration

The package supports automatic schema migration with zero downtime:

```dart
// Version 1 schema
final userSchemaV1 = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(name: 'id', type: DataType.integer),
    FieldSchema(name: 'name', type: DataType.text),
  ],
);

// Version 2 schema with new field
final userSchemaV2 = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(name: 'id', type: DataType.integer),
    FieldSchema(name: 'name', type: DataType.text),
    FieldSchema(name: 'email', type: DataType.text), // New field
  ],
);

// Initialize with migration
final storage = StorageEngine(
  config: StorageConfig(
    databaseName: 'my_app.db',
    version: 2, // Increment version
  ),
  schemas: [userSchemaV2],
  onMigrate: (oldVersion, newVersion) async {
    if (oldVersion < 2) {
      // Custom migration logic if needed
      await storage.execute(
        'UPDATE users SET email = name || "@example.com"',
      );
    }
  },
);

await storage.initialize();
```

## Performance Optimization

### Connection Pooling

```dart
final config = StorageConfig(
  performance: PerformanceConfig(
    enableConnectionPool: true,
    maxConnections: 5,
    connectionTimeout: Duration(seconds: 30),
  ),
);
```

### Prepared Statements

```dart
final config = StorageConfig(
  performance: PerformanceConfig(
    enablePreparedStatements: true,
    preparedStatementCacheSize: 100,
  ),
);
```

### Query Optimization

```dart
final config = StorageConfig(
  performance: PerformanceConfig(
    enableQueryOptimization: true,
    analyzeQueries: true,
  ),
);
```

### Batch Operations

Use batch operations for multiple inserts, updates, or deletes:

```dart
// Instead of this
for (final user in users) {
  await storage.insert('users', user);
}

// Do this
await storage.batchInsert('users', users);
```

## Error Handling

The package provides comprehensive error handling with specific exception types:

```dart
try {
  await storage.insert('users', {'username': 'john_doe'});
} on StorageException catch (e) {
  switch (e.code) {
    case ErrorCode.databaseNotInitialized:
      print('Database not initialized');
      break;
    case ErrorCode.encryptionFailed:
      print('Encryption failed: ${e.message}');
      break;
    case ErrorCode.validationFailed:
      print('Validation failed: ${e.details}');
      break;
    default:
      print('Storage error: ${e.message}');
  }
}
```

## Testing

The package includes comprehensive test utilities:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/local_storage_cache.dart';

void main() {
  late StorageEngine storage;

  setUp(() async {
    storage = StorageEngine(
      config: StorageConfig(
        databaseName: ':memory:', // In-memory database for testing
      ),
      schemas: [userSchema],
    );
    await storage.initialize();
  });

  tearDown(() async {
    await storage.close();
  });

  test('insert and query user', () async {
    final userId = await storage.insert('users', {
      'username': 'test_user',
      'email': 'test@example.com',
    });

    final users = await storage.query('users')
      .where('id', '=', userId)
      .get();

    expect(users.length, 1);
    expect(users.first['username'], 'test_user');
  });
}
```

## Examples

Complete working examples are available in the [example](example) directory:

- [Basic Usage](example/lib/screens/home_screen.dart)
- [Advanced Queries](example/lib/screens/advanced_queries_screen.dart)
- [Encryption](example/lib/screens/encryption_screen.dart)
- [Multi-Space](example/lib/screens/multi_space_screen.dart)
- [Backup and Restore](example/lib/screens/backup_restore_screen.dart)

## API Reference

For a complete list of available methods and configuration options, refer to the [API documentation](https://pub.dev/documentation/local_storage_cache/latest/).

## Contributing

Contributions are welcome. To set up your development environment:

1. Clone the repository:

   ```bash
   git clone https://github.com/protheeuz/local-storage-cache.git
   cd local-storage-cache
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Activate Melos:

   ```bash
   dart pub global activate melos
   ```

4. Bootstrap the workspace:

   ```bash
   melos bootstrap
   ```

5. Run tests:

   ```bash
   melos test
   ```

Please read the [contributing guidelines](CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

- Report issues on [GitHub Issues](https://github.com/protheeuz/local-storage-cache/issues)
- Ask questions on [GitHub Discussions](https://github.com/protheeuz/local-storage-cache/discussions)
- View the [changelog](CHANGELOG.md) for version history

## Acknowledgments

This package uses SQLite for local storage and implements platform-specific secure storage mechanisms for encryption key management.
