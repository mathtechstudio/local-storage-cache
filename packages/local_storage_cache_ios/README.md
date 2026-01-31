# local_storage_cache_ios

This is the platform-specific implementation of iOS `local_storage_cache` plugin.

## Features

- SQLite-based storage with SQLCipher encryption
- Keychain integration for secure key storage
- Touch ID / Face ID authentication support
- Database backup and restore functionality
- Full support for all local_storage_cache features

## Requirements

- iOS 12.0 or higher
- Xcode 14.0 or higher

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on iOS.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The iOS implementation will be used automatically when running on iOS devices.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Permissions

For biometric authentication, add the following to your `Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>We need to use Face ID to authenticate you</string>
```

## Platform-Specific Notes

### Biometric Authentication

iOS supports Touch ID and Face ID. The availability depends on the device model and iOS version.

### Secure Storage

This implementation uses iOS Keychain for secure key storage, providing hardware-backed encryption with Secure Enclave on supported devices.

## License

MIT License - see [LICENSE](LICENSE) file for details.
