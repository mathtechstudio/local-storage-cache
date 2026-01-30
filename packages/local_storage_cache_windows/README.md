# local_storage_cache_windows

Windows implementation of the local_storage_cache plugin.

## Features

- SQLite-based storage with SQLCipher encryption
- Windows Credential Manager integration for secure key storage
- Database backup and restore functionality
- Full support for all local_storage_cache features

## Requirements

- Windows 10 or higher
- Visual Studio 2019 or higher (for building)

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on Windows.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The Windows implementation will be used automatically when running on Windows.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Dependencies

The plugin uses:

- SQLite3 for database operations
- Windows Credential Manager API for secure storage

## Platform-Specific Notes

### Secure Storage

This implementation uses Windows Credential Manager for secure key storage, providing system-level encryption and user-specific credential isolation.

### Biometric Authentication

Biometric authentication is not currently supported on Windows. This feature may be added in future versions with Windows Hello integration.

## License

MIT License - see LICENSE file for details.
