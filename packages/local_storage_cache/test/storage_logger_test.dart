import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/enums/log_level.dart';
import 'package:local_storage_cache/src/managers/storage_logger.dart';

class TestLogger implements CustomLogger {
  final List<LogEntry> logs = [];

  @override
  void log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    logs.add(LogEntry(level, message, error, stackTrace));
  }
}

class LogEntry {
  LogEntry(this.level, this.message, this.error, this.stackTrace);

  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

void main() {
  group('StorageLogger', () {
    test('logs debug messages when level is debug', () {
      final testLogger = TestLogger();
      StorageLogger(
        minLevel: LogLevel.debug,
        customLogger: testLogger,
      ).debug('Debug message');

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.debug));
      expect(testLogger.logs.first.message, equals('Debug message'));
    });

    test('does not log debug messages when level is info', () {
      final testLogger = TestLogger();
      StorageLogger(
        customLogger: testLogger,
      ).debug('Debug message');

      expect(testLogger.logs.isEmpty, isTrue);
    });

    test('logs info messages', () {
      final testLogger = TestLogger();
      StorageLogger(
        customLogger: testLogger,
      ).info('Info message');

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.info));
      expect(testLogger.logs.first.message, equals('Info message'));
    });

    test('logs warning messages with error', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.warning,
        customLogger: testLogger,
      );

      final error = Exception('Test error');
      logger.warning('Warning message', error);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.warning));
      expect(testLogger.logs.first.message, equals('Warning message'));
      expect(testLogger.logs.first.error, equals(error));
    });

    test('logs error messages with stack trace', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.error,
        customLogger: testLogger,
      );

      final error = Exception('Test error');
      final stackTrace = StackTrace.current;
      logger.error('Error message', error, stackTrace);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.error));
      expect(testLogger.logs.first.message, equals('Error message'));
      expect(testLogger.logs.first.error, equals(error));
      expect(testLogger.logs.first.stackTrace, equals(stackTrace));
    });

    test('logs query execution', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.debug,
        customLogger: testLogger,
      );

      logger.logQuery('SELECT * FROM users', 25, resultCount: 10);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.debug));
      expect(
        testLogger.logs.first.message,
        contains('Query executed in 25ms'),
      );
      expect(testLogger.logs.first.message, contains('returned 10 rows'));
    });

    test('does not log query when level is too high', () {
      final testLogger = TestLogger();
      StorageLogger(
        customLogger: testLogger,
      ).logQuery('SELECT * FROM users', 25);

      expect(testLogger.logs.isEmpty, isTrue);
    });

    test('logs performance warning for slow operations', () {
      final testLogger = TestLogger();
      StorageLogger(
        minLevel: LogLevel.warning,
        customLogger: testLogger,
      ).logPerformance('database query', 150, threshold: 100);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.warning));
      expect(testLogger.logs.first.message, contains('Slow operation'));
      expect(testLogger.logs.first.message, contains('150ms'));
    });

    test('does not log performance warning for fast operations', () {
      final testLogger = TestLogger();
      StorageLogger(
        minLevel: LogLevel.warning,
        customLogger: testLogger,
      ).logPerformance('database query', 50, threshold: 100);

      expect(testLogger.logs.isEmpty, isTrue);
    });

    test('uses default threshold for performance logging', () {
      final testLogger = TestLogger();
      StorageLogger(
        minLevel: LogLevel.warning,
        customLogger: testLogger,
      ).logPerformance('database query', 150);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.message, contains('threshold: 100ms'));
    });

    test('logs cache operations', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.debug,
        customLogger: testLogger,
      );

      logger.logCache('get', 'user_123', hit: true);

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.level, equals(LogLevel.debug));
      expect(testLogger.logs.first.message, contains('Cache HIT'));
      expect(testLogger.logs.first.message, contains('user_123'));
    });

    test('logs cache miss', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.debug,
        customLogger: testLogger,
      );

      logger.logCache('get', 'user_123');

      expect(testLogger.logs.length, equals(1));
      expect(testLogger.logs.first.message, contains('Cache MISS'));
    });

    test('respects log level hierarchy', () {
      final testLogger = TestLogger();
      final logger = StorageLogger(
        minLevel: LogLevel.warning,
        customLogger: testLogger,
      );
      logger.debug('Debug');
      logger.info('Info');
      logger.warning('Warning');
      logger.error('Error');

      expect(testLogger.logs.length, equals(2));
      expect(testLogger.logs[0].level, equals(LogLevel.warning));
      expect(testLogger.logs[1].level, equals(LogLevel.error));
    });

    test('uses console logger by default', () {
      final logger = StorageLogger();

      // Should not throw
      expect(() => logger.info('Test message'), returnsNormally);
    });
  });
}
