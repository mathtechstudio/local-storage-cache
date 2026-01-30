import 'package:local_storage_cache/src/enums/log_level.dart';

/// Configuration for logging behavior in the storage engine.
///
/// Controls what information is logged during storage operations,
/// including queries, performance metrics, and general debug information.
class LogConfig {
  /// Creates a logging configuration with the specified settings.
  ///
  /// By default, logs at info level with queries and performance logging disabled.
  const LogConfig({
    this.level = LogLevel.info,
    this.logQueries = false,
    this.logPerformance = false,
    this.customLogger,
  });

  /// Creates a default logging configuration.
  ///
  /// Uses info level logging with queries and performance logging disabled.
  factory LogConfig.defaultConfig() => const LogConfig();

  /// Creates a verbose logging configuration.
  ///
  /// Enables debug level logging with both query and performance logging enabled.
  /// Useful for development and debugging.
  factory LogConfig.verbose() {
    return const LogConfig(
      level: LogLevel.debug,
      logQueries: true,
      logPerformance: true,
    );
  }

  /// Creates a silent logging configuration.
  ///
  /// Only logs errors, suppressing all other log output.
  /// Useful for production environments where minimal logging is desired.
  factory LogConfig.silent() {
    return const LogConfig(
      level: LogLevel.error,
    );
  }

  /// Minimum log level to output.
  final LogLevel level;

  /// Whether to log SQL queries.
  final bool logQueries;

  /// Whether to log performance metrics.
  final bool logPerformance;

  /// Custom logger function.
  final void Function(String message, LogLevel level)? customLogger;

  /// Converts this configuration to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'logQueries': logQueries,
      'logPerformance': logPerformance,
    };
  }
}
