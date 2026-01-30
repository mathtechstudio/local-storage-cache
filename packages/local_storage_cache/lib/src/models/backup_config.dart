// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

/// Configuration for backup operations.
class BackupConfig {
  /// Creates a backup configuration.
  const BackupConfig({
    this.format = BackupFormat.json,
    this.compression = CompressionType.none,
    this.includeEncryption = false,
    this.includeTables,
    this.excludeTables,
    this.includeSpaces,
    this.excludeSpaces,
    this.incremental = false,
    this.onProgress,
  });

  /// Backup format.
  final BackupFormat format;

  /// Compression type.
  final CompressionType compression;

  /// Whether to encrypt the backup.
  final bool includeEncryption;

  /// Specific tables to include (null means all).
  final List<String>? includeTables;

  /// Tables to exclude.
  final List<String>? excludeTables;

  /// Specific spaces to include (null means all).
  final List<String>? includeSpaces;

  /// Spaces to exclude.
  final List<String>? excludeSpaces;

  /// Whether to perform incremental backup.
  final bool incremental;

  /// Progress callback.
  final void Function(double progress, String message)? onProgress;

  /// Creates a copy with modified fields.
  BackupConfig copyWith({
    BackupFormat? format,
    CompressionType? compression,
    bool? includeEncryption,
    List<String>? includeTables,
    List<String>? excludeTables,
    List<String>? includeSpaces,
    List<String>? excludeSpaces,
    bool? incremental,
    void Function(double progress, String message)? onProgress,
  }) {
    return BackupConfig(
      format: format ?? this.format,
      compression: compression ?? this.compression,
      includeEncryption: includeEncryption ?? this.includeEncryption,
      includeTables: includeTables ?? this.includeTables,
      excludeTables: excludeTables ?? this.excludeTables,
      includeSpaces: includeSpaces ?? this.includeSpaces,
      excludeSpaces: excludeSpaces ?? this.excludeSpaces,
      incremental: incremental ?? this.incremental,
      onProgress: onProgress ?? this.onProgress,
    );
  }
}

/// Backup format options.
enum BackupFormat {
  /// JSON format (human-readable).
  json,

  /// SQLite file copy (fastest).
  sqlite,

  /// Custom binary format (compact).
  binary,
}

/// Compression type options.
enum CompressionType {
  /// No compression.
  none,

  /// Gzip compression.
  gzip,

  /// Zlib compression.
  zlib,
}
