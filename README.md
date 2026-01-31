# local_storage_cache

[![Pub Version](https://img.shields.io/pub/v/local_storage_cache.svg)](https://pub.dev/packages/local_storage_cache)
[![Build Status](https://github.com/mathtechstudio/local-storage-cache/actions/workflows/code-integration.yml/badge.svg)](https://github.com/mathtechstudio/local-storage-cache/actions/workflows/code-integration.yml)
[![Code Coverage](https://codecov.io/gh/mathtechstudio/local-storage-cache/graph/badge.svg)](https://codecov.io/gh/mathtechstudio/local-storage-cache)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-informational)

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
  local_storage_cache: ^2.0.1 # Check pub.dev for the latest version
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:local_storage_cache/local_storage_cache.dart';

// Define your schema
final userSchema = TableSchema(
  name: 'users',
  fields: [
    FieldSchema(name: 'username', type: DataType.text, nullable: false, unique: true),
    FieldSchema(name: 'email', type: DataType.text, nullable: false),
    FieldSchema(name: 'created_at', type: DataType.datetime, nullable: false),
  ],
  primaryKeyConfig: const PrimaryKeyConfig(
    name: 'id',
    type: PrimaryKeyType.autoIncrement,
  ),
  indexes: [IndexSchema(name: 'idx_username', fields: ['username'])],
);

// Initialize storage
final storage = StorageEngine(
  config: StorageConfig(
    databaseName: 'my_app.db',
    encryption: EncryptionConfig(enabled: true),
  ),
  schemas: [userSchema],
);

await storage.initialize();

// Insert data
final userId = await storage.insert('users', {
  'username': 'john_doe',
  'email': 'john@example.com',
  'created_at': DateTime.now().toIso8601String(),
});

// Query data
final users = await storage.query('users')
  .where('username', '=', 'john_doe')
  .get();

// Update data
await storage.update(
  'users',
  {'email': 'newemail@example.com'},
  where: 'id = ?',
  whereArgs: [userId],
);

// Delete data
await storage.delete('users', where: 'id = ?', whereArgs: [userId]);
```

## Platform Requirements

| Platform | Minimum Version | Notes                       |
| -------- | --------------- | --------------------------- |
| Android  | API 21 (5.0+)   | Requires SQLite 3.8.0+      |
| iOS      | 12.0+           | Uses SQLite.swift           |
| macOS    | 10.14+          | Uses SQLite.swift           |
| Windows  | 10+             | Requires Visual C++ Runtime |
| Linux    | Ubuntu 18.04+   | Requires libsqlite3         |
| Web      | Modern browsers | Uses IndexedDB              |

## Advanced Features

### Multi-Space Architecture

Isolate data for different users or contexts:

```dart
await storage.createSpace('user_123');
await storage.switchSpace('user_123');

// All operations now work within this space
await storage.insert('notes', {
  'title': 'My Note',
  'content': 'Note content',
});
```

### Encryption

```dart
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
```

### Batch Operations

```dart
final users = [
  {'username': 'user1', 'email': 'user1@example.com'},
  {'username': 'user2', 'email': 'user2@example.com'},
  {'username': 'user3', 'email': 'user3@example.com'},
];

await storage.batchInsert('users', users);
```

### Transactions

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

### Backup and Restore

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

## Package Structure

This repository is organized as a monorepo using Melos:

- `packages/local_storage_cache` - Main package with core functionality
- `packages/local_storage_cache_platform_interface` - Platform interface definitions
- `packages/local_storage_cache_android` - Android implementation
- `packages/local_storage_cache_ios` - iOS implementation
- `packages/local_storage_cache_macos` - macOS implementation
- `packages/local_storage_cache_windows` - Windows implementation
- `packages/local_storage_cache_linux` - Linux implementation
- `packages/local_storage_cache_web` - Web implementation

## Documentation

- [Main Package Documentation](packages/local_storage_cache/README.md)
- [API Reference](https://pub.dev/documentation/local_storage_cache/latest/)
- [Examples](packages/local_storage_cache/example)
- [Changelog](CHANGELOG.md)

## Examples

Complete working examples are available in the [example](packages/local_storage_cache/example) directory:

- Basic Usage
- Advanced Queries
- Encryption
- Multi-Space Architecture
- Backup and Restore

## Contributing

Contributions are welcome. To set up your development environment:

1. Clone the repository:

   ```bash
   git clone https://github.com/mathtechstudio/local-storage-cache.git
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

6. Run static analysis:

   ```bash
   melos analyze
   ```

7. Format code:

   ```bash
   melos format
   ```

Please read the [contributing guidelines](CONTRIBUTING.md) before submitting pull requests.

## Development Commands

This project uses Melos for managing the monorepo:

```bash
# Bootstrap all packages
melos bootstrap

# Run tests for all packages
melos test

# Run static analysis
melos analyze

# Format all code
melos format

# Clean all packages
melos clean

# Publish packages (maintainers only)
melos publish
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Support

- Report issues on [GitHub Issues](https://github.com/mathtechstudio/local-storage-cache/issues)
- View the [CHANGELOG](CHANGELOG.md) for version history

## Acknowledgments

This package uses SQLite for local storage and implements platform-specific secure storage mechanisms for encryption key management.
