import 'package:local_storage_cache/src/config/cache_config.dart';
import 'package:local_storage_cache/src/config/encryption_config.dart';
import 'package:local_storage_cache/src/config/log_config.dart';
import 'package:local_storage_cache/src/config/performance_config.dart';

/// Main configuration for the storage engine.
class StorageConfig {
  /// Creates a storage configuration with the specified settings.
  const StorageConfig({
    this.databaseName = 'storage.db',
    this.databasePath,
    this.version = 1,
    this.encryption = const EncryptionConfig(),
    this.cache = const CacheConfig(),
    this.performance = const PerformanceConfig(),
    this.logging = const LogConfig(),
    this.enableAutoBackup = false,
    this.autoBackupInterval,
    this.autoBackupPath,
    this.enableMetrics = true,
    this.enableEventStream = true,
  });

  /// Creates a default storage configuration.
  factory StorageConfig.defaultConfig() => const StorageConfig();

  /// Creates a high-performance storage configuration.
  factory StorageConfig.highPerformance() {
    return StorageConfig(
      cache: CacheConfig.highPerformance(),
      performance: PerformanceConfig.highPerformance(),
    );
  }

  /// Creates a secure storage configuration with encryption enabled.
  factory StorageConfig.secure({
    String? customKey,
    bool requireBiometric = false,
  }) {
    return StorageConfig(
      encryption: EncryptionConfig.secure(
        customKey: customKey,
        requireBiometric: requireBiometric,
      ),
      enableAutoBackup: true,
      autoBackupInterval: const Duration(hours: 24),
    );
  }

  /// Database name.
  final String databaseName;

  /// Custom database path. If null, uses default platform path.
  final String? databasePath;

  /// Database version for migrations.
  final int version;

  /// Encryption configuration.
  final EncryptionConfig encryption;

  /// Cache configuration.
  final CacheConfig cache;

  /// Performance configuration.
  final PerformanceConfig performance;

  /// Logging configuration.
  final LogConfig logging;

  /// Whether to enable automatic backups.
  final bool enableAutoBackup;

  /// Interval for automatic backups.
  final Duration? autoBackupInterval;

  /// Path for automatic backups.
  final String? autoBackupPath;

  /// Whether to enable performance metrics collection.
  final bool enableMetrics;

  /// Whether to enable event stream.
  final bool enableEventStream;

  /// Converts the configuration to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'databaseName': databaseName,
      'databasePath': databasePath,
      'version': version,
      'encryption': encryption.toMap(),
      'cache': cache.toMap(),
      'performance': performance.toMap(),
      'logging': logging.toMap(),
      'enableAutoBackup': enableAutoBackup,
      'autoBackupInterval': autoBackupInterval?.inMilliseconds,
      'autoBackupPath': autoBackupPath,
      'enableMetrics': enableMetrics,
      'enableEventStream': enableEventStream,
    };
  }
}
