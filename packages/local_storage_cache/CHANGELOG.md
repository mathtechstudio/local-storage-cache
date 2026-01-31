# Changelog

## 2.0.1

### Fixed

* Fixed federated plugin configuration - added platform implementation packages as dependencies
* This resolves the "package does not exist, or is not a plugin package" error when installing

## 2.0.0

### New Features

* Complete rewrite with federated plugin architecture
* Multi-platform support (Android, iOS, macOS, Windows, Linux, Web)
* Advanced query system with SQL-like syntax
* Multi-space architecture for data isolation
* Strong encryption with AES-256-GCM and ChaCha20-Poly1305
* Automatic schema migration with zero downtime
* Multi-level caching system (memory and disk)
* Connection pooling and prepared statement caching
* Batch operations for improved performance
* Comprehensive backup and restore functionality
* Data validation with custom validators
* Event system for monitoring data changes
* Performance metrics and monitoring
* Error recovery with automatic retry
* Query optimization and analysis

### Platform Implementations

* Android implementation with SQLCipher and Keystore
* iOS implementation with SQLCipher and Keychain
* macOS implementation with SQLCipher and Keychain
* Windows implementation with SQLite and Credential Manager
* Linux implementation with SQLite and Secret Service API
* Web implementation with IndexedDB and LocalStorage

### Breaking Changes

* Complete API redesign - not compatible with v1.x
* New configuration system
* Different encryption approach
* Schema-based data modeling required

### Migration

* See MIGRATION.md for detailed migration guide from v1.x

## 1.0.0

* Initial release
* Basic local storage functionality
* Simple cache management
* Basic encryption support
