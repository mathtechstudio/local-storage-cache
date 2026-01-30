# Local Storage Cache - Federated Plugin Packages

This directory contains all packages for the local_storage_cache federated plugin.

## Package Structure

### Main Package

- **local_storage_cache/** - The app-facing package that developers will use

### Platform Interface

- **local_storage_cache_platform_interface/** - Defines the interface that platform implementations must follow

### Platform Implementations

- **local_storage_cache_android/** - Android implementation (Kotlin + SQLCipher)
- **local_storage_cache_ios/** - iOS implementation (Swift + Keychain)
- **local_storage_cache_macos/** - macOS implementation (Swift + Keychain)
- **local_storage_cache_windows/** - Windows implementation (C++ + DPAPI)
- **local_storage_cache_linux/** - Linux implementation (C++ + libsecret)
- **local_storage_cache_web/** - Web implementation (IndexedDB + Web Crypto API)

## Development

### Running Tests

```bash
# Test all packages
./scripts/test_all.sh

# Test specific package
cd packages/local_storage_cache
flutter test
```

### Building

```bash
# Get dependencies for all packages
./scripts/get_dependencies.sh

# Build example app
cd packages/local_storage_cache/example
flutter run
```

## Architecture

The federated plugin architecture allows each platform to have its own optimized implementation while providing a unified API to developers.

```bash
┌─────────────────────────────────────────────┐
│         Application Layer (User Code)       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│     API Layer (local_storage_cache)         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Platform Interface Layer                   │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Platform Implementation Layer              │
│  (Android, iOS, macOS, Windows, Linux, Web) │
└─────────────────────────────────────────────┘
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../LICENSE) for details.
