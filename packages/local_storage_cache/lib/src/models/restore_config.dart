// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

/// Configuration for restore operations.
class RestoreConfig {
  /// Creates a restore configuration.
  const RestoreConfig({
    this.conflictResolution = ConflictResolution.replace,
    this.includeTables,
    this.excludeTables,
    this.includeSpaces,
    this.excludeSpaces,
    this.onProgress,
  });

  /// How to handle conflicts during restore.
  final ConflictResolution conflictResolution;

  /// Specific tables to restore (null means all).
  final List<String>? includeTables;

  /// Tables to exclude from restore.
  final List<String>? excludeTables;

  /// Specific spaces to restore (null means all).
  final List<String>? includeSpaces;

  /// Spaces to exclude from restore.
  final List<String>? excludeSpaces;

  /// Progress callback.
  final void Function(double progress, String message)? onProgress;

  /// Creates a copy with modified fields.
  RestoreConfig copyWith({
    ConflictResolution? conflictResolution,
    List<String>? includeTables,
    List<String>? excludeTables,
    List<String>? includeSpaces,
    List<String>? excludeSpaces,
    void Function(double progress, String message)? onProgress,
  }) {
    return RestoreConfig(
      conflictResolution: conflictResolution ?? this.conflictResolution,
      includeTables: includeTables ?? this.includeTables,
      excludeTables: excludeTables ?? this.excludeTables,
      includeSpaces: includeSpaces ?? this.includeSpaces,
      excludeSpaces: excludeSpaces ?? this.excludeSpaces,
      onProgress: onProgress ?? this.onProgress,
    );
  }
}

/// Conflict resolution strategies.
enum ConflictResolution {
  /// Replace existing data with backup data.
  replace,

  /// Skip records that already exist.
  skip,

  /// Fail on conflict.
  fail,

  /// Merge data (keep newer).
  merge,
}
