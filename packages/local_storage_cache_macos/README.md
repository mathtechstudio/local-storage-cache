# local_storage_cache_macos

This is the platform-specific implementation of macOS `local_storage_cache` plugin.

## Features

- SQLite-based storage with SQLCipher encryption
- Keychain integration for secure key storage
- Touch ID authentication support
- Database backup and restore functionality
- Full support for all local_storage_cache features

## Requirements

- macOS 10.14 or higher
- Xcode 14.0 or higher

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on macOS.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The macOS implementation will be used automatically when running on macOS.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Entitlements

For Keychain access, ensure your app has the Keychain Sharing entitlement enabled in Xcode.

## Platform-Specific Notes

### Biometric Authentication

macOS supports Touch ID on supported Mac models. The availability depends on the hardware.

### Secure Storage

This implementation uses macOS Keychain for secure key storage, providing system-level encryption.

## License

MIT License - see [LICENSE](LICENSE) file for details.
