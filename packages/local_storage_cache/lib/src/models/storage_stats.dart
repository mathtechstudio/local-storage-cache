/// Statistics about storage usage.
class StorageStats {
  /// Creates storage statistics with the specified values.
  const StorageStats({
    required this.tableCount,
    required this.recordCount,
    required this.storageSize,
    required this.spaceCount,
    required this.cacheHitRate,
    required this.averageQueryTime,
  });

  /// Total number of tables.
  final int tableCount;

  /// Total number of records across all tables.
  final int recordCount;

  /// Total storage size in bytes.
  final int storageSize;

  /// Number of spaces.
  final int spaceCount;

  /// Cache hit rate (0.0 to 1.0).
  final double cacheHitRate;

  /// Average query execution time in milliseconds.
  final double averageQueryTime;

  /// Storage size in megabytes.
  double get storageSizeMB => storageSize / (1024 * 1024);

  /// Converts the statistics to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'tableCount': tableCount,
      'recordCount': recordCount,
      'storageSize': storageSize,
      'storageSizeMB': storageSizeMB,
      'spaceCount': spaceCount,
      'cacheHitRate': cacheHitRate,
      'averageQueryTime': averageQueryTime,
    };
  }
}
