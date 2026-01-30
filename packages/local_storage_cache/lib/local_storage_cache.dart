/// A comprehensive Flutter package for managing local storage and caching.
///
/// This package provides advanced features including:
/// - Multi-platform support (Android, iOS, macOS, Windows, Linux, Web)
/// - Advanced query system with SQL-like operations
/// - Multi-space architecture for data isolation
/// - Strong encryption with biometric authentication
/// - Automatic schema migration
/// - Multi-level caching
/// - Batch operations
/// - Backup & restore
///
/// Example:
/// ```dart
/// final storage = StorageEngine(
///   config: StorageConfig(
///     encryption: EncryptionConfig(enabled: true),
///   ),
/// );
/// await storage.initialize();
/// ```
library local_storage_cache;

// Configuration
export 'src/config/cache_config.dart';
export 'src/config/encryption_config.dart';
export 'src/config/log_config.dart';
export 'src/config/performance_config.dart';
export 'src/config/storage_config.dart';
// Enums
export 'src/enums/cache_level.dart';
export 'src/enums/data_type.dart';
export 'src/enums/encryption_algorithm.dart';
export 'src/enums/error_code.dart';
export 'src/enums/eviction_policy.dart';
export 'src/enums/log_level.dart';
// Exceptions
export 'src/exceptions/storage_exception.dart';
// Managers
export 'src/managers/backup_manager.dart';
export 'src/managers/cache_manager.dart';
export 'src/managers/encryption_manager.dart';
export 'src/managers/error_recovery_manager.dart';
export 'src/managers/event_manager.dart';
export 'src/managers/performance_metrics_manager.dart';
export 'src/managers/schema_manager.dart';
export 'src/managers/space_manager.dart';
export 'src/managers/storage_logger.dart';
export 'src/managers/validation_manager.dart';
// Models
export 'src/models/backup_config.dart';
export 'src/models/cache_entry.dart';
export 'src/models/cache_expiration_event.dart';
export 'src/models/cache_stats.dart';
export 'src/models/migration_operation.dart';
export 'src/models/migration_status.dart';
export 'src/models/performance_metrics.dart';
export 'src/models/query_condition.dart';
export 'src/models/restore_config.dart';
export 'src/models/schema_change.dart';
export 'src/models/storage_event.dart';
export 'src/models/storage_stats.dart';
export 'src/models/validation_error.dart';
export 'src/models/validation_result.dart';
export 'src/models/warm_cache_entry.dart';
// Optimization
export 'src/optimization/connection_pool.dart';
export 'src/optimization/prepared_statement_cache.dart';
export 'src/optimization/query_optimizer.dart';
// Core API
export 'src/query_builder.dart';
// Schema
export 'src/schema/field_schema.dart';
export 'src/schema/foreign_key_schema.dart';
export 'src/schema/index_schema.dart';
export 'src/schema/primary_key_config.dart';
export 'src/schema/table_schema.dart';
export 'src/storage_engine.dart';
