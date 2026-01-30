import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/enums/error_code.dart';
import 'package:local_storage_cache/src/exceptions/storage_exception.dart';
import 'package:local_storage_cache/src/managers/error_recovery_manager.dart';

void main() {
  group('ErrorRecoveryManager', () {
    late ErrorRecoveryManager recoveryManager;
    late Directory tempDir;

    setUp(() async {
      recoveryManager = ErrorRecoveryManager(
        config: const RecoveryConfig(
          maxRetries: 3,
          initialDelayMs: 10,
          maxDelayMs: 100,
        ),
      );

      tempDir = await Directory.systemTemp.createTemp('recovery_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('executeWithRetry succeeds on first attempt', () async {
      var callCount = 0;

      final result = await recoveryManager.executeWithRetry(() async {
        callCount++;
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(1));
    });

    test('executeWithRetry retries on failure', () async {
      var callCount = 0;

      final result = await recoveryManager.executeWithRetry(() async {
        callCount++;
        if (callCount < 3) {
          throw DatabaseException(
            'Database locked',
            code: ErrorCode.databaseLocked.code,
          );
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(3));
    });

    test('executeWithRetry fails after max retries', () async {
      var callCount = 0;

      expect(
        () async => recoveryManager.executeWithRetry(() async {
          callCount++;
          throw DatabaseException(
            'Database locked',
            code: ErrorCode.databaseLocked.code,
          );
        }),
        throwsA(isA<DatabaseException>()),
      );

      expect(callCount, equals(3));
    });

    test('executeWithRetry uses exponential backoff', () async {
      var callCount = 0;
      final delays = <int>[];
      var lastTime = DateTime.now();

      await expectLater(
        recoveryManager.executeWithRetry(() async {
          callCount++;
          if (callCount > 1) {
            final now = DateTime.now();
            delays.add(now.difference(lastTime).inMilliseconds);
            lastTime = now;
          }
          throw DatabaseException(
            'Database locked',
            code: ErrorCode.databaseLocked.code,
          );
        }),
        throwsA(isA<DatabaseException>()),
      );

      expect(callCount, equals(3));
      expect(delays.length, equals(2));
      // First delay should be ~10ms, second should be ~20ms
      expect(delays[0], greaterThanOrEqualTo(8));
      expect(delays[1], greaterThanOrEqualTo(delays[0]));
    });

    test('executeWithRetry respects custom shouldRetry', () async {
      var callCount = 0;

      expect(
        () async => recoveryManager.executeWithRetry(
          () async {
            callCount++;
            throw Exception('Custom error');
          },
          shouldRetry: (error) => false, // Never retry
        ),
        throwsA(isA<Exception>()),
      );

      expect(callCount, equals(1));
    });

    test('handleDatabaseLock retries on lock errors', () async {
      var callCount = 0;

      final result = await recoveryManager.handleDatabaseLock(() async {
        callCount++;
        if (callCount < 2) {
          throw DatabaseException(
            'Database locked',
            code: ErrorCode.databaseLocked.code,
          );
        }
        return 'unlocked';
      });

      expect(result, equals('unlocked'));
      expect(callCount, equals(2));
    });

    test('handleDatabaseLock does not retry on other errors', () async {
      var callCount = 0;

      await expectLater(
        recoveryManager.handleDatabaseLock(() async {
          callCount++;
          throw DatabaseException(
            'Query failed',
            code: ErrorCode.queryFailed.code,
          );
        }),
        throwsA(isA<DatabaseException>()),
      );

      expect(callCount, equals(1));
    });

    test('recoverFromCorruption restores from backup', () async {
      // Create a backup file
      final backupPath = '${tempDir.path}/backup.db';
      final backupFile = File(backupPath);
      await backupFile.writeAsString('backup data');

      // Create a corrupted database
      final dbPath = '${tempDir.path}/database.db';
      final dbFile = File(dbPath);
      await dbFile.writeAsString('corrupted');

      final success = await recoveryManager.recoverFromCorruption(
        databasePath: dbPath,
        backupPath: backupPath,
      );

      expect(success, isTrue);
      expect(await dbFile.exists(), isTrue);
      expect(await dbFile.readAsString(), equals('backup data'));
    });

    test('recoverFromCorruption fails without backup', () async {
      final dbPath = '${tempDir.path}/database.db';

      final success = await recoveryManager.recoverFromCorruption(
        databasePath: dbPath,
        backupPath: '${tempDir.path}/nonexistent.db',
      );

      expect(success, isFalse);
    });

    test('handleDiskFull executes cleanup operation', () async {
      var cleanupCalled = false;

      final success = await recoveryManager.handleDiskFull(
        cleanupOperation: () async {
          cleanupCalled = true;
        },
      );

      expect(success, isTrue);
      expect(cleanupCalled, isTrue);
    });

    test('handleDiskFull returns false on cleanup failure', () async {
      final success = await recoveryManager.handleDiskFull(
        cleanupOperation: () async {
          throw Exception('Cleanup failed');
        },
      );

      expect(success, isFalse);
    });

    test('repairDatabase runs integrity check and vacuum', () async {
      var integrityCheckCalled = false;
      var vacuumCalled = false;

      final success = await recoveryManager.repairDatabase(
        databasePath: '${tempDir.path}/database.db',
        integrityCheck: () async {
          integrityCheckCalled = true;
        },
        vacuumOperation: () async {
          vacuumCalled = true;
        },
      );

      expect(success, isTrue);
      expect(integrityCheckCalled, isTrue);
      expect(vacuumCalled, isFalse); // Should not vacuum if check passes
    });

    test('repairDatabase vacuums on integrity check failure', () async {
      var integrityCheckCount = 0;
      var vacuumCalled = false;

      final success = await recoveryManager.repairDatabase(
        databasePath: '${tempDir.path}/database.db',
        integrityCheck: () async {
          integrityCheckCount++;
          if (integrityCheckCount == 1) {
            throw Exception('Integrity check failed');
          }
        },
        vacuumOperation: () async {
          vacuumCalled = true;
        },
      );

      expect(success, isTrue);
      expect(integrityCheckCount, equals(2));
      expect(vacuumCalled, isTrue);
    });

    test('createRecoveryPoint creates backup file', () async {
      // Create a database file
      final dbPath = '${tempDir.path}/database.db';
      final dbFile = File(dbPath);
      await dbFile.writeAsString('database data');

      final recoveryPath = await recoveryManager.createRecoveryPoint(
        databasePath: dbPath,
        recoveryDir: tempDir.path,
      );

      expect(recoveryPath, isNotNull);
      expect(await File(recoveryPath!).exists(), isTrue);
      expect(
        await File(recoveryPath).readAsString(),
        equals('database data'),
      );
    });

    test('createRecoveryPoint returns null for nonexistent database', () async {
      final recoveryPath = await recoveryManager.createRecoveryPoint(
        databasePath: '${tempDir.path}/nonexistent.db',
        recoveryDir: tempDir.path,
      );

      expect(recoveryPath, isNull);
    });

    test('restoreFromRecoveryPoint restores database', () async {
      // Create a recovery point
      final recoveryPath = '${tempDir.path}/recovery.db';
      final recoveryFile = File(recoveryPath);
      await recoveryFile.writeAsString('recovery data');

      // Create a database to be replaced
      final dbPath = '${tempDir.path}/database.db';
      final dbFile = File(dbPath);
      await dbFile.writeAsString('old data');

      final success = await recoveryManager.restoreFromRecoveryPoint(
        databasePath: dbPath,
        recoveryPath: recoveryPath,
      );

      expect(success, isTrue);
      expect(await dbFile.readAsString(), equals('recovery data'));
    });

    test('restoreFromRecoveryPoint fails for nonexistent recovery', () async {
      final success = await recoveryManager.restoreFromRecoveryPoint(
        databasePath: '${tempDir.path}/database.db',
        recoveryPath: '${tempDir.path}/nonexistent.db',
      );

      expect(success, isFalse);
    });

    test('handlePermissionDenied requests permission', () async {
      var permissionRequested = false;

      final success = await recoveryManager.handlePermissionDenied(
        path: '/some/path',
        requestPermission: () async {
          permissionRequested = true;
        },
      );

      expect(success, isTrue);
      expect(permissionRequested, isTrue);
    });

    test('handlePermissionDenied returns false on failure', () async {
      final success = await recoveryManager.handlePermissionDenied(
        path: '/some/path',
        requestPermission: () async {
          throw Exception('Permission denied');
        },
      );

      expect(success, isFalse);
    });

    test('retries on timeout exceptions', () async {
      var callCount = 0;

      final result = await recoveryManager.executeWithRetry(() async {
        callCount++;
        if (callCount < 2) {
          throw TimeoutException('Operation timed out');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(2));
    });

    test('retries on socket exceptions', () async {
      var callCount = 0;

      final result = await recoveryManager.executeWithRetry(() async {
        callCount++;
        if (callCount < 2) {
          throw const SocketException('Connection failed');
        }
        return 'success';
      });

      expect(result, equals('success'));
      expect(callCount, equals(2));
    });
  });
}
