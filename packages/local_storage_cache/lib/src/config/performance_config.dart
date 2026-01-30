/// Configuration for performance optimizations.
class PerformanceConfig {
  /// Creates a performance configuration with the specified settings.
  const PerformanceConfig({
    this.connectionPoolSize = 5,
    this.enablePreparedStatements = true,
    this.enableQueryOptimization = true,
    this.enableBatchOptimization = true,
    this.batchSize = 100,
  });

  /// Creates a default performance configuration.
  factory PerformanceConfig.defaultConfig() => const PerformanceConfig();

  /// Creates a high-performance configuration with optimized settings.
  factory PerformanceConfig.highPerformance() {
    return const PerformanceConfig(
      connectionPoolSize: 10,
      batchSize: 500,
    );
  }

  /// Size of the database connection pool.
  final int connectionPoolSize;

  /// Whether to enable prepared statement caching.
  final bool enablePreparedStatements;

  /// Whether to enable automatic query optimization.
  final bool enableQueryOptimization;

  /// Whether to enable batch operation optimization.
  final bool enableBatchOptimization;

  /// Default batch size for batch operations.
  final int batchSize;

  /// Converts the configuration to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'connectionPoolSize': connectionPoolSize,
      'enablePreparedStatements': enablePreparedStatements,
      'enableQueryOptimization': enableQueryOptimization,
      'enableBatchOptimization': enableBatchOptimization,
      'batchSize': batchSize,
    };
  }
}
