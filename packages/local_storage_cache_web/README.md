# local_storage_cache_web

This is the platform-specific implementation of Web `local_storage_cache` plugin.

## Features

- IndexedDB-based storage using modern package:web
- LocalStorage for secure key storage
- Modern JS interop with dart:js_interop
- Database export functionality
- Full support for all local_storage_cache features

## Requirements

- Modern web browser with IndexedDB support
- Dart SDK 3.6.0 or higher

## Usage

This package is automatically included when you add `local_storage_cache` to your Flutter project's dependencies and run on Web.

```yaml
dependencies:
  local_storage_cache: ^2.0.0
```

No additional setup is required. The Web implementation will be used automatically when running on web browsers.

For complete usage documentation, API reference, and examples, please refer to the main [local_storage_cache](https://pub.dev/packages/local_storage_cache) package documentation.

## Browser Compatibility

The plugin works on all modern browsers that support:

- IndexedDB API
- LocalStorage API

Tested on:

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Platform-Specific Notes

### Storage Implementation

This implementation uses IndexedDB for structured data storage and LocalStorage for simple key-value pairs. IndexedDB provides better performance and larger storage capacity compared to LocalStorage.

### Modern Web APIs

The implementation uses `package:web` with `dart:js_interop`, following Flutter's modern web interop guidelines and ensuring compatibility with WebAssembly compilation.

## Limitations

- Biometric authentication is not available on web
- Database import is not supported (export only)
- Storage limits depend on browser implementation (typically 50MB+ for IndexedDB)
- Encryption is simplified compared to native platforms

## License

MIT License - see [LICENSE](LICENSE) file for details.
