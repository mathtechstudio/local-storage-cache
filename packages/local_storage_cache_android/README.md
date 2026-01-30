# local_storage_cache_android

This is the platform-specific implementation of Android `local_storage_cache` plugin.

## Features

- SQLite-based storage with SQLCipher encryption
- Android Keystore integration for secure key storage
- Biometric authentication support (fingerprint, face unlock)
- Database backup and restore functionality
- Full support for all local_storage_cache features

## Requirements

- Android SDK 21 (Lollipop) or higher
- AndroidX libraries

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on Android.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The Android implementation will be used automatically when running on Android devices.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Permissions

The plugin requires the following permissions (automatically added):

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

## Platform-Specific Notes

### Biometric Authentication

Android supports various biometric authentication methods including fingerprint, face unlock, and iris scanning. The availability depends on the device hardware and Android version.

### Secure Storage

This implementation uses Android Keystore for secure key storage, providing hardware-backed encryption on supported devices.

## License

MIT License - see LICENSE file for details.
