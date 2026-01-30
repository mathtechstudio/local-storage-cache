/// Logging levels.
enum LogLevel {
  /// Debug level - Most verbose, includes all messages
  debug,

  /// Info level - General informational messages
  info,

  /// Warning level - Warning messages for potentially harmful situations
  warning,

  /// Error level - Error messages for error events
  error,
}

/// Extension methods for [LogLevel].
extension LogLevelExtension on LogLevel {
  /// Returns the numeric value of the log level.
  /// Higher values indicate more severe log levels.
  int get value {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
    }
  }

  /// Checks if this log level should be logged given a minimum level.
  bool shouldLog(LogLevel minimumLevel) {
    return value >= minimumLevel.value;
  }
}
