# local_storage_cache_platform_interface

Platform interface for the `local_storage_cache` plugin.

This package defines the common interface that all platform implementations must implement. It is not intended to be used directly by end users.

## Overview

This package provides the interface that all platform-specific implementations of `local_storage_cache` must implement. It ensures consistency across all platforms and enables the federated plugin architecture.

## Usage

This package is used internally by:

- `local_storage_cache` - The main plugin package
- `local_storage_cache_android` - Android implementation
- `local_storage_cache_ios` - iOS implementation
- `local_storage_cache_macos` - macOS implementation
- `local_storage_cache_windows` - Windows implementation
- `local_storage_cache_linux` - Linux implementation
- `local_storage_cache_web` - Web implementation

For end-user documentation and usage examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## For Plugin Developers

To implement a new platform:

1. Add this package as a dependency:

```yaml
dependencies:
  local_storage_cache_platform_interface: ^2.0.0
```

2. Extend `LocalStorageCachePlatform`:

```dart
class MyPlatformImplementation extends LocalStorageCachePlatform {
  static void registerWith() {
    LocalStorageCachePlatform.instance = MyPlatformImplementation();
  }
  
  @override
  Future<void> initialize(String databasePath, Map<String, dynamic> config) async {
    // Your implementation
  }
  
  // Implement all other required methods...
}
```

3. Register your implementation in your plugin's main file

## Interface Methods

The platform interface defines methods for:

- Database initialization and management
- CRUD operations (insert, query, update, delete)
- Transaction support
- Batch operations
- Encryption and decryption
- Secure key storage
- Biometric authentication
- Database import/export
- Storage information retrieval

## License

MIT License - see [LICENSE](LICENSE) file for details.
