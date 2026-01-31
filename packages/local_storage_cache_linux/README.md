# local_storage_cache_linux

This is the platform-specific implementation of Linux `local_storage_cache` plugin.

## Features

- SQLite-based storage with SQLCipher encryption
- Secret Service API integration for secure key storage
- Database backup and restore functionality
- Full support for all local_storage_cache features

## Requirements

- Linux with Secret Service API support (GNOME Keyring, KWallet, etc.)
- GCC 7.0 or higher (for building)

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on Linux.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The Linux implementation will be used automatically when running on Linux.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Dependencies

The plugin uses:

- SQLite3 for database operations
- libsecret for secure key storage

Install required system libraries:

```bash
sudo apt-get install libsqlite3-dev libsecret-1-dev
```

## Platform-Specific Notes

### Secure Storage

This implementation uses the Secret Service API (libsecret) for secure key storage, which integrates with GNOME Keyring, KWallet, or other compatible keyrings.

### Biometric Authentication

Biometric authentication is not currently supported on Linux. This feature may be added in future versions.

## License

MIT License - see [LICENSE](LICENSE) file for details.
